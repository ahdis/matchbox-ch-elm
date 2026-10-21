# matchbox-ch-elm
matchbox configured with ch-elm for validation


## how to install a new ch-elm ig or matchbox version

Start the `Create a release` workflow (Actions → Create a release → Run workflow, on `main`) with the version and the
new matchbox version (e.g. `v4.1.22`) and/or the new ch-elm version (e.g. `1.16.0`, or `cibuild` for the current
ci-build). It updates the files, checks that the image builds, pushes the release commit to `main`, creates the release
and builds the image. You get a message on Zulip when the new matchbox-ch-elm image is available in the registry.

How to pick the version, and how to release by hand when `src/application.yaml` needs changes, is in
[`.claude/skills/release/SKILL.md`](.claude/skills/release/SKILL.md) (or ask Claude Code to make a release).

## Build container for matchbox configured with ch-elm

```
docker build --progress=plain -t matchbox-ch-elm .
docker run -d --name matchbox-ch-elm -p 8080:80 matchbox-ch-elm
docker logs matchbox-ch-elm --follow 
```

after startup matchbox will be available at
http://localhost:8080/matchboxv3/


## Download image from the GitHub Container registry

by `<ch-elm version>-<matchbox version>` or by ch-elm version (the latest build for it)

```
docker run -d --name matchbox-ch-elm -p 8080:80 ghcr.io/ahdis/matchbox-ch-elm:1.15.1-4.1.21
docker run -d --name matchbox-ch-elm -p 8080:80 ghcr.io/ahdis/matchbox-ch-elm:1.15.1
```

Releases up to `1.15.1-cibuild` are also in the Google Artifact Registry
(`europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm:<version>`), newer ones only on ghcr.io.