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
| `.github/workflows/googleregistry.yml` | on every pushed tag, builds the image (amd64 and arm64), pushes it to Google Artifact Registry as `matchbox-ch-elm:<tag>` and posts to Zulip (`#matchbox`) |

## Release process

The release procedure (version, matchbox and ch-elm update, changelog, tag, image build) is in the Claude Code skill
[`.claude/skills/release/SKILL.md`](.claude/skills/release/SKILL.md). Follow it for a release.
