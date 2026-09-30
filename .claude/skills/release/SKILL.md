---
name: release
description: Make a new matchbox-ch-elm release (e.g. 1.15.4) - update the matchbox base image and/or the ch-elm IG package, add the changelog entry, commit and push the version tag, and follow the Docker image build. Use when the user asks to release, cut or publish a new matchbox-ch-elm version, e.g. for a new matchbox or ch-elm version.
---

# Making a matchbox-ch-elm release

A release is a new combination of a matchbox version (the `FROM` image in `Dockerfile`) and a ch-elm IG version
(`src/ch.fhir.ig.ch-elm.tgz`). It's a commit on `main` named after the version and a tag with the bare version (no
`v`). Pushing the tag starts `.github/workflows/googleregistry.yml`, which builds the image (amd64 and arm64), pushes it
as `europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm:<tag>` and posts to Zulip. There is no PR and, since
2024, no GitHub release.

The user asking for a release authorizes the whole procedure (commit and push to `main`, tag). Stop and ask if the
version isn't obvious, if `main` has unexpected changes, or if the build fails. A pushed tag is published at once:
don't move or delete it, make a new patch release instead.

## 1. Check the state and pick the version

```bash
git switch main && git pull --ff-only && git fetch --tags
git tag --sort=-creatordate | head -5                                     # last release
head -4 changelog.md
grep '^FROM' Dockerfile                                                    # current matchbox
tar -xOzf src/ch.fhir.ig.ch-elm.tgz package/package.json | grep '"version"'    # current ch-elm
curl -s https://fhir.ch/ig/ch-elm/package-list.json | python3 -c \
  "import json,sys; [print(e['version'], e['status'], e.get('date')) for e in json.load(sys.stdin)['list'][:3]]"
```

The version follows the ch-elm IG version:

- only matchbox changes: the patch of the last release + 1 (e.g. `1.15.3` → `1.15.4`)
- new ch-elm IG version: the IG version (e.g. ch-elm `1.16.0` → `1.16.0`)
- ch-elm ci-build: `<ig-version>-cibuild`, `-cibuild2`, … (e.g. `1.15.0-cibuild2`)

## 2. matchbox (if there is a new matchbox version)

The matchbox release must have its Docker image (its `Build and Upload to Google Artifact registry` run in
`ahdis/matchbox` completed):

```bash
docker manifest inspect europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox:vX.Y.Z > /dev/null && echo ok
```

(`gcloud.auth.docker-helper` errors about expired credentials can be ignored if it prints `ok`, the image is public.)
Set the tag in the `FROM` line of `Dockerfile`.

## 3. ch-elm (if there is a new IG version)

1. Download the package to `src/ch.fhir.ig.ch-elm.tgz`:
   - published: `curl -fsSL -o src/ch.fhir.ig.ch-elm.tgz https://fhir.ch/ig/ch-elm/<version>/package.tgz`
   - ci-build: `curl -fsSL -o src/ch.fhir.ig.ch-elm.tgz https://build.fhir.org/ig/ahdis/ch-elm/package.tgz`
2. Check the version in the package:
   `tar -xOzf src/ch.fhir.ig.ch-elm.tgz package/package.json | grep '"version"'`
3. Set it in **both** places of `src/application.yaml`: `hapi.fhir.implementationguides.chelm.version` and
   `matchbox.fhir.context.igsPreloaded` (`ch.fhir.ig.ch-elm#<version>`).

## 4. Changelog and README

Add the entry at the top of `changelog.md` (date `YYYY/MM/DD`, followed by an empty line):

```
1.15.4 2026/09/30
- matchbox v4.1.19
- ch.fhir.ig.ch-elm#1.15.1

```

Set the new version in the `docker run` example under "Download image" in `README.md`.

## 5. Build locally (for a new IG version)

The image build installs the IG, so a successful build confirms the package loads. Recommended for a new ch-elm
package (it takes a few minutes), optional if only matchbox changes:

```bash
docker build --progress=plain -t matchbox-ch-elm .
```

To try it: `docker run -d --name matchbox-ch-elm -p 8080:80 matchbox-ch-elm`, then http://localhost:8080/matchboxv3/.

## 6. Commit, tag and push

Commit only the release files, never `.DS_Store` (it's tracked and often modified). The commit message is the version:

```bash
git add Dockerfile changelog.md README.md src/application.yaml src/ch.fhir.ig.ch-elm.tgz
git commit -m "1.15.4"
git tag 1.15.4
git push origin main
git push origin 1.15.4
```

## 7. Follow the build

```bash
gh run list --repo ahdis/matchbox-ch-elm --workflow googleregistry.yml --limit 1
gh run watch <id> --repo ahdis/matchbox-ch-elm --exit-status
docker manifest inspect europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm:1.15.4 > /dev/null && echo ok
```

The build takes about 10–15 min. On success a message is posted to Zulip `#matchbox` (topic "new matchbox-ch-elm
version published"), on failure to `#ahdis`. Report the version, its matchbox and ch-elm versions, and the image.
