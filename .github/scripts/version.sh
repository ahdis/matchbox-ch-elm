#!/usr/bin/env bash
# Prints the version of the image in the working tree: <ch-elm>-<matchbox> (e.g. 1.15.1-4.1.22), for a ch-elm
# ci-build <ch-elm>-cibuild.<package date>-<matchbox>.
# With --tags, also the tag of the latest build of it: <ch-elm>, for a ci-build <ch-elm>-cibuild-<matchbox>.
set -euo pipefail
cd "$(dirname "$0")/../.."

MATCHBOX=$(sed -n 's/^FROM .*matchbox:v\([^ ]*\).*/\1/p' Dockerfile)
PACKAGE_JSON=$(tar -xOzf src/ch.fhir.ig.ch-elm.tgz package/package.json)
CHELM=$(jq -er .version <<< "$PACKAGE_JSON")
DATE=$(jq -er .date <<< "$PACKAGE_JSON")
URL=$(jq -er .url <<< "$PACKAGE_JSON")
if [[ "$URL" == *build.fhir.org* ]]; then
  echo "$CHELM-cibuild.$DATE-$MATCHBOX"
  LATEST="$CHELM-cibuild-$MATCHBOX"
else
  echo "$CHELM-$MATCHBOX"
  LATEST=$CHELM
fi
if [ "${1:-}" = "--tags" ]; then
  echo "$LATEST"
fi
