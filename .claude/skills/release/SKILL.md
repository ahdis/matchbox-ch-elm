---
name: release
description: Make a new matchbox-ch-elm release (e.g. 1.15.4) - pick the version, run the release workflow with the new matchbox and/or ch-elm version (it updates the files, pushes to main, tags and creates the GitHub release) and follow the Docker image build. Use when the user asks to release, cut or publish a new matchbox-ch-elm version, e.g. for a new matchbox or ch-elm version.
---

# Making a matchbox-ch-elm release

A release is a new combination of a matchbox version (the `FROM` image in `Dockerfile`) and a ch-elm IG version
(`src/ch.fhir.ig.ch-elm.tgz`). The `Create a release` workflow (`.github/workflows/release.yml`), started on `main`
with the version and the new matchbox and/or ch-elm version, does the whole release: it updates the files with
`.github/scripts/prepare-release.sh` (`Dockerfile`, the package, `src/application.yaml`, `README.md` and the
`changelog.md` entry), builds the image to check that the IG loads, pushes the commit named after the version to `main`,
creates the tag with the bare version (no `v`) and the GitHub release with the notes from `changelog.md` (a `-cibuild`
version as a pre-release), and starts `.github/workflows/build.yml` on the tag. That builds the image (amd64 and arm64),
pushes it as `ghcr.io/ahdis/matchbox-ch-elm:<tag>` (also as `<ch-elm>-<matchbox>` and `<ch-elm>`, see
`.github/scripts/version.sh`) and posts to Zulip. Up to `1.15.1-cibuild` the image was also pushed to Google Artifact
Registry (`europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm`), newer versions are only on ghcr.io. There is
no PR.

The user asking for a release authorizes the whole procedure (release workflow, which pushes to `main`). Stop and ask
if the version isn't obvious or if a workflow fails. A tag is published at once: don't move or delete it, make a new
patch release instead.

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
- matchbox pre-release (e.g. `v5.0.0-rc1`): only with the ch-elm ci-build, as a `-cibuildN` version, so that it's a
  pre-release and the `<ch-elm>` tag on ghcr.io stays on the last stable image

The workflow refuses a `-cibuild` version with a published package and an `X.Y.Z` version with a ci-build package. If
`main` has a ci-build package, a stable release must set `chelm` to a published version.

The matchbox release must have its Docker image (its `Build and Upload to Google Artifact registry` run in
`ahdis/matchbox` completed), the workflow checks it. For a new major version check its release notes for changed or
removed settings used in `src/application.yaml`; if the config needs changes, make the release by hand (step 3).

## 2. Run the release workflow

```bash
gh workflow run release.yml --repo ahdis/matchbox-ch-elm --ref main -f version=1.15.7 -f matchbox=v4.1.22
gh workflow run release.yml --repo ahdis/matchbox-ch-elm --ref main -f version=1.16.0 -f chelm=1.16.0
gh workflow run release.yml --repo ahdis/matchbox-ch-elm --ref main -f version=1.16.0-cibuild -f chelm=cibuild
```

Inputs: `version` (required), `matchbox` (tag, e.g. `v4.1.22`), `chelm` (version or `cibuild`), `note` (an additional
line for the changelog entry, e.g. a config change) and `zulip` (default on). Empty `matchbox` / `chelm` keep the
current version. If the workflow fails before "Commit and push to main", nothing is published: fix the cause and run
it again.

## 3. Release by hand (config changes)

When `src/application.yaml` or other files need changes beyond the versions, prepare the release locally (needs `jq`
and `docker`), adjust the files, build, and commit only the release files (never `.DS_Store`, it's tracked and often
modified):

```bash
.github/scripts/prepare-release.sh 1.16.0 v5.0.0 1.16.0 "config for matchbox v5"
docker build --progress=plain -t matchbox-ch-elm .
git add Dockerfile changelog.md README.md src/application.yaml src/ch.fhir.ig.ch-elm.tgz
git commit -m "1.16.0"
git push origin main
gh workflow run release.yml --repo ahdis/matchbox-ch-elm --ref main -f version=1.16.0
```

When the first entry of `changelog.md` is already the version, the workflow only checks that the entry lists the
matchbox version of the `Dockerfile` and the ch-elm version of the package (also preloaded in `src/application.yaml`)
and releases `main` as it is. Don't tag by hand.

To try an image locally: `docker run -d --name matchbox-ch-elm -p 8080:80 matchbox-ch-elm`, then
http://localhost:8080/matchboxv3/.

## 4. Follow the release and the build

```bash
gh run list --repo ahdis/matchbox-ch-elm --limit 2               # 'Create a release', then the build on the tag
gh run watch <id> --repo ahdis/matchbox-ch-elm --exit-status
gh release view 1.15.7 --repo ahdis/matchbox-ch-elm
docker manifest inspect ghcr.io/ahdis/matchbox-ch-elm:1.15.7 > /dev/null && echo ok
```

The release workflow takes a few minutes (it builds the image once), the build on the tag about 10–20 min. On success
a message is posted to Zulip `#matchbox` (topic "new matchbox-ch-elm version published", with the link to the release),
on failure to `#ahdis`. Report the version, its matchbox and ch-elm versions, the release URL and the image.
