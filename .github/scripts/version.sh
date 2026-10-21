#!/usr/bin/env bash
# Prints the version of the image in the working tree: <ch-elm>-<matchbox> (e.g. 1.15.1-4.1.22), for a ch-elm
# ci-build <ch-elm>-cibuild.<package date>-<matchbox>.
# With --tags, also the tag of the latest build of it: <ch-elm>, for a ci-build <ch-elm>-cibuild-<matchbox>, none for
# another pre-release (a matchbox or ch-elm version with a suffix, e.g. v5.0.0-rc1).
# With --env, the variables MATCHBOX, CHELM, VERSION, LATEST and PRERELEASE as shell assignments.
set -euo pipefail
cd "$(dirname "$0")/../.."

MATCHBOX=$(sed -n 's/^FROM .*matchbox:\(v[^ ]*\).*/\1/p' Dockerfile)
PACKAGE_JSON=$(tar -xOzf src/ch.fhir.ig.ch-elm.tgz package/package.json)
CHELM=$(jq -er .version <<< "$PACKAGE_JSON")
DATE=$(jq -er .date <<< "$PACKAGE_JSON")
URL=$(jq -er .url <<< "$PACKAGE_JSON")
if [[ "$URL" == *build.fhir.org* ]]; then
  VERSION=$CHELM-cibuild.$DATE-${MATCHBOX#v}
  LATEST=$CHELM-cibuild-${MATCHBOX#v}
  PRERELEASE=true
elif [[ "$MATCHBOX$CHELM" == *-* ]]; then
  VERSION=$CHELM-${MATCHBOX#v}
  LATEST=
  PRERELEASE=true
else
  VERSION=$CHELM-${MATCHBOX#v}
  LATEST=$CHELM
  PRERELEASE=false
fi

case "${1:-}" in
  --tags)
    echo "$VERSION"
    [ -z "$LATEST" ] || echo "$LATEST"
    ;;
  --env)
    printf 'MATCHBOX=%q\nCHELM=%q\nVERSION=%q\nLATEST=%q\nPRERELEASE=%q\n' \
      "$MATCHBOX" "$CHELM" "$VERSION" "$LATEST" "$PRERELEASE"
    ;;
  *)
    echo "$VERSION"
    ;;
esac
