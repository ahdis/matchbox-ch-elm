#!/usr/bin/env bash
# Prepares a release in the working tree: sets the matchbox base image and/or the ch-elm IG package, the ch-elm version
# in src/application.yaml and the image tags in README.md, and adds the changelog entry.
#
# Usage: prepare-release.sh <version> [matchbox] [chelm] [note]
#   version   release version, e.g. 1.15.7 or 1.16.0-cibuild2
#   matchbox  matchbox tag, e.g. v4.1.22. Empty: unchanged
#   chelm     ch-elm version, e.g. 1.16.0, or 'cibuild' for the current ci-build. Empty: unchanged
#   note      an additional line for the changelog entry
set -euo pipefail
cd "$(dirname "$0")/../.."

VERSION=$1
MATCHBOX=${2:-}
CHELM_SOURCE=${3:-}
NOTE=${4:-}
PACKAGE=src/ch.fhir.ig.ch-elm.tgz

# sed without -i, which differs between GNU and BSD
replace() { sed "$1" "$2" > "$2.tmp" && mv "$2.tmp" "$2"; }
package_version() { tar -xOzf "$1" package/package.json | jq -r .version; }

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-cibuild[0-9]*)?$ ]]; then
  echo "The version '$VERSION' isn't of the form X.Y.Z or X.Y.Z-cibuildN" >&2
  exit 1
fi
if awk 'NF { print $1 }' changelog.md | grep -qxF "$VERSION"; then
  echo "$VERSION is already in changelog.md" >&2
  exit 1
fi

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
{
  printf '%s %s\n- matchbox %s\n- ch.fhir.ig.ch-elm#%s\n' "$VERSION" "$(date +%Y/%m/%d)" "$CURRENT_MATCHBOX" "$CURRENT_CHELM"
  [ -z "$NOTE" ] || printf -- '- %s\n' "$NOTE"
  printf '\n'
  cat changelog.md
} > changelog.md.tmp && mv changelog.md.tmp changelog.md

# The docker run examples show the latest stable image
if [[ "$VERSION" != *-cibuild* ]]; then
  replace "s|\(ghcr\.io/ahdis/matchbox-ch-elm:\)[^ ]*-[^ ]*\$|\1$(.github/scripts/version.sh)|; s|\(ghcr\.io/ahdis/matchbox-ch-elm:\)[0-9.]*\$|\1$CURRENT_CHELM|" \
    README.md
fi

awk 'NF == 0 { exit } { print }' changelog.md
