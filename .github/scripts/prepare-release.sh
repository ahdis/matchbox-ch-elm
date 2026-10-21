#!/usr/bin/env bash
# Prepares a release in the working tree: sets the matchbox base image and/or the ch-elm IG package, the ch-elm version
# in src/application.yaml and the image tags in README.md, and adds the changelog entry.
#
# The release is named after the versions (.github/scripts/version.sh). If that tag exists, the release is a rebuild of
# the same versions (e.g. for a config change) and gets the next revision, e.g. 1.15.1-4.1.22-r2, which needs a note.
# If the first entry of changelog.md is already the release (e.g. the release commit was pushed, but the release
# failed), it changes nothing.
#
# Usage: prepare-release.sh [matchbox] [chelm] [note]
#   matchbox  matchbox tag, e.g. v4.1.22. Empty: unchanged
#   chelm     ch-elm version, e.g. 1.16.0, or 'cibuild' for the current ci-build. Empty: unchanged
#   note      an additional line for the changelog entry
#
# Prints the release and writes VERSION and PRERELEASE to $GITHUB_ENV if it's set.
set -euo pipefail
cd "$(dirname "$0")/../.."

NEW_MATCHBOX=${1:-}
NEW_CHELM=${2:-}
NOTE=${3:-}
PACKAGE=src/ch.fhir.ig.ch-elm.tgz

# sed without -i, which differs between GNU and BSD
replace() { sed "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"; }
tag_exists() { git rev-parse -q --verify "refs/tags/$1" > /dev/null; }

if [ -n "$NEW_MATCHBOX" ]; then
  IMAGE=$(sed -n 's/^FROM \([^:]*\):.*/\1/p' Dockerfile)
  if ! docker manifest inspect "$IMAGE:$NEW_MATCHBOX" > /dev/null; then
    echo "The matchbox image $IMAGE:$NEW_MATCHBOX doesn't exist (yet)" >&2
    exit 1
  fi
  replace "s|^\(FROM .*matchbox:\)[^ ]*|\1$NEW_MATCHBOX|" Dockerfile
fi

if [ -n "$NEW_CHELM" ]; then
  if [ "$NEW_CHELM" = cibuild ]; then
    curl -fsSL -o "$PACKAGE" https://build.fhir.org/ig/ahdis/ch-elm/package.tgz
  else
    curl -fsSL -o "$PACKAGE" "https://fhir.ch/ig/ch-elm/$NEW_CHELM/package.tgz"
  fi
fi

eval "$(.github/scripts/version.sh --env)"
if [ -n "$NEW_CHELM" ] && [ "$NEW_CHELM" != cibuild ] && [ "$CHELM" != "$NEW_CHELM" ]; then
  echo "The package of ch-elm $NEW_CHELM has the version $CHELM" >&2
  exit 1
fi
CHELM=$CHELM yq -i '.hapi.fhir.implementationguides.chelm.version = strenv(CHELM) |
  .matchbox.fhir.context.igsPreloaded = "ch.fhir.ig.ch-elm#" + strenv(CHELM)' src/application.yaml

BASE=$VERSION
REVISION=1
while tag_exists "$VERSION"; do
  REVISION=$((REVISION + 1))
  VERSION=$BASE-r$REVISION
done

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
    printf '%s %s\n- matchbox %s\n- ch.fhir.ig.ch-elm#%s\n' "$VERSION" "$(date +%Y/%m/%d)" "$MATCHBOX" "$CHELM"
    [ -z "$NOTE" ] || printf -- '- %s\n' "$NOTE"
    printf '\n'
    cat changelog.md
  } > changelog.md.tmp && mv changelog.md.tmp changelog.md

  # The docker run examples show the latest stable image, <ch-elm>-<matchbox> follows its rebuilds
  if [ "$PRERELEASE" = false ]; then
    replace "s|\(ghcr\.io/ahdis/matchbox-ch-elm:\)[^ ]*-[^ ]*\$|\1$BASE|; s|\(ghcr\.io/ahdis/matchbox-ch-elm:\)[0-9.]*\$|\1$LATEST|" \
      README.md
  fi
fi

awk 'NF == 0 { exit } { print }' changelog.md >&2
echo "$VERSION"
if [ -n "${GITHUB_ENV:-}" ]; then
  printf 'VERSION=%s\nPRERELEASE=%s\n' "$VERSION" "$PRERELEASE" >> "$GITHUB_ENV"
fi
