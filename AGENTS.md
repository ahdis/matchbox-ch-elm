# AGENTS.md

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
| `.github/workflows/release.yml` | `Create a release`, started by hand on `main` with optionally a new matchbox and/or ch-elm version and a note: updates the files with `.github/scripts/prepare-release.sh`, builds the image, pushes the release commit to `main`, creates the tag and the GitHub release with the notes from `changelog.md`, then starts `build.yml` on the tag (passing the `zulip` option) |
| `.github/scripts/prepare-release.sh` | updates `Dockerfile`, the IG package, `src/application.yaml` and `README.md` to a new matchbox and/or ch-elm version, names the release (`version.sh`, `-rN` for a rebuild of released versions) and adds the changelog entry |
| `.github/workflows/build.yml` | on every pushed tag (or started by `release.yml`), builds the image (amd64 and arm64) and pushes it to `ghcr.io/ahdis/matchbox-ch-elm` as `<tag>` and the tags of `.github/scripts/version.sh --tags`, and posts to Zulip (`#matchbox`), unless `zulip` is turned off. Up to `1.15.1-cibuild` it also pushed to Google Artifact Registry |
| `.github/scripts/version.sh` | prints the version of the image in the working tree (`<ch-elm>-<matchbox>`, for a ci-build `<ch-elm>-cibuild.<package date>-<matchbox>`), with `--tags` also the tag of its latest build (no `<ch-elm>` tag with a matchbox pre-release) |

## Release process

A release is made with the `Create a release` workflow, see "how to install a new ch-elm ig or matchbox version" in
`README.md`. The release name is derived from the versions, never chosen by hand. Don't tag by hand, and don't move or
delete a published tag. To follow a release:

```bash
gh run list --repo ahdis/matchbox-ch-elm --limit 2               # 'Create a release', then the build on the tag
gh run watch <id> --repo ahdis/matchbox-ch-elm --exit-status
```
