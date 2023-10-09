# matchbox-ch-elm
matchbox configured with ch-elm for validation
## Build container for matchbox configured with ch-elm

```
docker build -t matchbox-ch-elm .
docker run -d --name matchbox-ch-elm -p 8080:8080 matchbox-ch-elm
```

after startup matchbox will be available at
http://localhost:8080/matchbox/


## Download image for google artifact registry

```
docker pull europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm:v1.0.0-trialuse
docker run -d --name matchbox-ch-elm -p 8080:8080  europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox-ch-elm:v1.0.0-trialuse
```