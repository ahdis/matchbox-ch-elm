# matchbox-ch-elm
matchbox configured with ch-elm for validation


## how to install a new ch-elm ig or matchbox version

1. if ch-elm is updated download the published (or ci-build) package into src/ch.fhir.ig.ch-elm.tgz
2. adjust the version in src/application.yaml
3. update Dockerfile if there is a new matchbox version
4. updated changelog.md with planned new release
5. commit and push to main, make are release tag and push it to origin
6. you get a message on zulip if matchbox-ch-elm is available in the registry

## Build container for matchbox configured with ch-elm

```
docker build --progress=plain -t matchbox-ch-elm .
docker run -d --name matchbox-ch-elm -p 8080:80 matchbox-ch-elm
docker logs matchbox-ch-elm --follow 
```

after startup matchbox will be available at
http://localhost:8080/matchboxv3/


## Download image for google artifact registry

```
docker run -d --name matchbox-ch-elm -p 8080:80  europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm:1.13.0

```