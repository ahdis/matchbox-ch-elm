# AGENT.md

Instructions for coding agents working on this repository.

## What this repo is

A thin Docker image on top of [matchbox](https://github.com/ahdis/matchbox) that preloads the
CH ELM implementation guide (`ch.fhir.ig.ch-elm`) for validation. There is no application code:
a release is a new combination of matchbox version and ch-elm IG version.

| File | Purpose |
| --- | --- |
| `Dockerfile` | `FROM europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox:vX.Y.Z`, the matchbox base image |
| `src/ch.fhir.ig.ch-elm.tgz` | the ch-elm IG package that gets installed into the image |
| `src/application.yaml` | matchbox config; the ch-elm version appears in **two** places (`hapi.fhir.implementationguides.chelm.version` and `matchbox.fhir.context.igsPreloaded`) |
| `changelog.md` | release history, newest entry first |
| `.github/workflows/googleregistry.yml` | on every pushed tag, builds the image (amd64 and arm64), pushes it to Google Artifact Registry as `matchbox-ch-elm:<tag>` and posts to Zulip (`#matchbox`) |

## Release process

### 1. Pick the new version

The release version follows the ch-elm IG version:

- only matchbox changes: bump the patch of the last release (e.g. `1.15.2` → `1.15.3`)
- new ch-elm IG version: use the IG version (e.g. ch-elm `1.16.0` → release `1.16.0`)
- ch-elm ci-build: `<ig-version>-cibuild`, `-cibuild2`, … (e.g. `1.15.0-cibuild2`)

Check the latest tag with `git fetch --tags && git tag --sort=-creatordate | head`.

### 2. Update matchbox (if there is a new matchbox version)

Before bumping, check that the base image exists:

```
docker manifest inspect europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox:vX.Y.Z
```

Then change the `FROM` line in `Dockerfile` to that tag.

### 3. Update ch-elm (if there is a new IG version)

1. Download the published (or ci-build) `package.tgz` and save it as `src/ch.fhir.ig.ch-elm.tgz`.
   - published: `https://fhir.ch/ig/ch-elm/<version>/package.tgz`
   - ci-build: `https://build.fhir.org/ig/ahdis/ch-elm/package.tgz`
2. Check the version inside the package: `tar -xOzf src/ch.fhir.ig.ch-elm.tgz package/package.json | grep '"version"'`
3. Set that version in **both** places in `src/application.yaml`.

### 4. Update `changelog.md`

Add an entry at the top, in this format (date as `YYYY/MM/DD`):

```
1.15.3 2026/09/26
- matchbox v4.1.18
- ch.fhir.ig.ch-elm#1.15.1

```

### 5. Optional: test locally

```
docker build --progress=plain -t matchbox-ch-elm .
docker run -d --name matchbox-ch-elm -p 8080:80 matchbox-ch-elm
docker logs matchbox-ch-elm --follow
```

matchbox is then available at http://localhost:8080/matchboxv3/. The build step installs the
IG, so a successful `docker build` already confirms that the package loads.

### 6. Commit, tag and push

Commit only the release files (never `.DS_Store`). The commit message is the version, and the
tag is the bare version without a `v` prefix:

```
git add Dockerfile changelog.md src/application.yaml src/ch.fhir.ig.ch-elm.tgz
git commit -m "1.15.3"
git tag 1.15.3
git push origin main
git push origin 1.15.3
```

Pushing the tag starts the `googleregistry.yml` workflow. No GitHub release is created; since
2024, releases are tags only.

### 7. Verify

- Workflow run: `gh run list --workflow=googleregistry.yml -L 1` (or `gh run watch`)
- Image: `docker manifest inspect europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm:1.15.3`
- Zulip: a message in `#matchbox`, topic "new matchbox-ch-elm version published". On failure,
  a message goes to `#ahdis`.

Optionally update the image tag in the "Download image" example in `README.md`.
