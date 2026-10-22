# matchbox-ch-elm
matchbox configured with ch-elm for validation


## how to install a new ch-elm ig or matchbox version

Start the `Create a release` workflow on `main` (Actions → Create a release → Run workflow) with

- `matchbox`: the new matchbox version, e.g. `v4.1.22` (its image must be in Google Artifact Registry)
- `chelm`: the new ch-elm version, e.g. `1.16.0`, or `cibuild` for the current ci-build
- `note`: an additional line for the changelog entry

```bash
gh workflow run release.yml --repo ahdis/matchbox-ch-elm --ref main -f matchbox=v4.1.22 -f chelm=1.16.0
```

It updates `Dockerfile`, `src/ch.fhir.ig.ch-elm.tgz`, `src/application.yaml`, this README and `changelog.md`
(`.github/scripts/prepare-release.sh`), checks that the image builds, pushes the release commit to `main`, creates the
tag and the GitHub release and builds the image. You get a message on Zulip when the image is available in the
registry.

A release is named after its versions, `<ch-elm version>-<matchbox version>`, e.g. `1.15.1-4.1.22`. A ch-elm ci-build
is named `<ch-elm version>-cibuild.<package date>-<matchbox version>`. Releases with a ch-elm ci-build or a matchbox
or ch-elm pre-release (e.g. `v5.0.0-rc1`) are pre-releases. A rebuild of versions that are already released, e.g. for
a config change or OS updates, gets `-r2`, `-r3`, … and needs a `note`.

New versions: [matchbox releases](https://github.com/ahdis/matchbox/releases) and the
[ch-elm package list](https://fhir.ch/ig/ch-elm/package-list.json).

When the config needs changes (e.g. for a new matchbox major version), commit them to `main`, then run the workflow
(with the new versions, or without if you updated them by hand). If the workflow fails before it pushes, nothing is
published. If it fails later, run it again: it releases the pushed commit. Don't tag by hand, and don't move or delete
a published tag.

Releases up to `1.15.1-cibuild2` used a separate version number (e.g. `1.15.6`).

## Build container for matchbox configured with ch-elm

```
docker build --progress=plain -t matchbox-ch-elm .
docker run -d --name matchbox-ch-elm -p 8080:80 matchbox-ch-elm
docker logs matchbox-ch-elm --follow 
```

after startup matchbox will be available at
http://localhost:8080/matchboxv3/


## Download image from the GitHub Container registry

by release, by `<ch-elm version>-<matchbox version>` (the latest build of it, including `-rN` rebuilds) or by ch-elm
version (its latest stable build)

```
docker run -d --name matchbox-ch-elm -p 8080:80 ghcr.io/ahdis/matchbox-ch-elm:1.15.1-4.1.21
docker run -d --name matchbox-ch-elm -p 8080:80 ghcr.io/ahdis/matchbox-ch-elm:1.15.1
```

Releases up to `1.15.1-cibuild` are also in the Google Artifact Registry
(`europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm:<version>`), newer ones only on ghcr.io.