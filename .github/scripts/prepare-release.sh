#!/usr/bin/env bash
# Prepares a release in the working tree: sets the matchbox base image and/or the ch-elm IG package, the ch-elm version
# in src/application.yaml and the image tags in README.md, and adds the changelog entry.
#
# The release is named after the versions (.github/scripts/version.sh), e.g. 1.15.1-4.1.22. If that tag exists, the
# release is a rebuild of the same versions (e.g. for a config change) and gets the next revision, e.g.
# 1.15.1-4.1.22-r2, which needs a note for the changelog entry.
# If the first entry of changelog.md is already the release (e.g. the release commit was pushed, but the release
# failed), it changes nothing.
#
# Usage: prepare-release.sh [matchbox] [chelm] [note]
#   matchbox  matchbox tag, e.g. v4.1.22. Empty: unchanged
#   chelm     ch-elm version, e.g. 1.16.0, or 'cibuild' for the current ci-build. Empty: unchanged
#   note      an additional line for the changelog entry
#
# Prints the release and writes 'version' and 'prerelease' to $GITHUB_OUTPUT if it's set.
set -euo pipefail
cd "$(dirname "$0")/../.."

MATCHBOX=${1:-}
CHELM_SOURCE=${2:-}
NOTE=${3:-}
PACKAGE=src/ch.fhir.ig.ch-elm.tgz

# sed without -i, which differs between GNU and BSD
replace() { sed "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"; }
package_version() { tar -xOzf "$1" package/package.json | jq -r .version; }
tag_exists() { git rev-parse -q --verify "refs/tags/$1" > /dev/null; }

if [ -n "$MATCHBOX" ]; then
  IMAGE=$(sed -n 's/^FROM \([^:]*\):.*/\1/p' Dockerfile)
  if ! docker manifest inspect "$IMAGE:$MATCHBOX" > /dev/null; then
    echo "The matchbox image $IMAGE:$MATCHBOX doesn't exist (yet)" >&2
    exit 1
  fi
  replace "s|^\(FROM .*matchbox:\)[^ ]*|\1$MATCHBOX|" Dockerfile
fi

if [ -n "$CHELM_SOURCE" ]; then
  PREVIOUS_CHELM=$(package_version "$PACKAGE")
  if [ "$CHELM_SOURCE" = cibuild ]; then
    curl -fsSL -o "$PACKAGE" https://build.fhir.org/ig/ahdis/ch-elm/package.tgz
  else
    curl -fsSL -o "$PACKAGE" "https://fhir.ch/ig/ch-elm/$CHELM_SOURCE/package.tgz"
    if [ "$(package_version "$PACKAGE")" != "$CHELM_SOURCE" ]; then
      echo "The package of ch-elm $CHELM_SOURCE has the version $(package_version "$PACKAGE")" >&2
      exit 1
    fi
  fi
  CHELM=$(package_version "$PACKAGE")
  replace "s|^\( *version: \)$PREVIOUS_CHELM\$|\1$CHELM|; s|ch\.fhir\.ig\.ch-elm#$PREVIOUS_CHELM|ch.fhir.ig.ch-elm#$CHELM|" \
    src/application.yaml
fi

CURRENT_MATCHBOX=$(sed -n 's/^FROM .*matchbox:\(v[^ ]*\).*/\1/p' Dockerfile)
CURRENT_CHELM=$(package_version "$PACKAGE")
BASE=$(.github/scripts/version.sh)
VERSION=$BASE
REVISION=1
while tag_exists "$VERSION"; do
  REVISION=$((REVISION + 1))
  VERSION=$BASE-r$REVISION
done
PRERELEASE=false
if [[ "$BASE" == *-cibuild* || "$CURRENT_MATCHBOX" == *-* ]]; then
  PRERELEASE=true
fi

if [ "$(awk 'NF { print $1; exit }' changelog.md)" = "$VERSION" ]; then
  echo "changelog.md already starts with $VERSION" >&2
else
  if awk 'NF { print $1 }' changelog.md | grep -qxF "$VERSION"; then
    echo "$VERSION is in changelog.md, but not tagged" >&2
    exit 1
  fi
  if [ "$REVISION" -gt 1 ] && [ -z "$NOTE" ]; then
    echo "$BASE is already released, the rebuild $VERSION needs a note for the changelog" >&2
    exit 1
  fi
  {
    printf '%s %s\n- matchbox %s\n- ch.fhir.ig.ch-elm#%s\n' "$VERSION" "$(date +%Y/%m/%d)" "$CURRENT_MATCHBOX" "$CURRENT_CHELM"
    [ -z "$NOTE" ] || printf -- '- %s\n' "$NOTE"
    printf '\n'
    cat changelog.md
  } > changelog.md.tmp && mv changelog.md.tmp changelog.md

  # The docker run examples show the latest stable image, <ch-elm>-<matchbox> follows its rebuilds
  if [ "$PRERELEASE" = false ]; then
    replace "s|\(ghcr\.io/ahdis/matchbox-ch-elm:\)[^ ]*-[^ ]*\$|\1$BASE|; s|\(ghcr\.io/ahdis/matchbox-ch-elm:\)[0-9.]*\$|\1$CURRENT_CHELM|" \
      README.md
  fi
fi

awk 'NF == 0 { exit } { print }' changelog.md >&2
echo "$VERSION"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "version=$VERSION"
    echo "prerelease=$PRERELEASE"
  } >> "$GITHUB_OUTPUT"
fi
