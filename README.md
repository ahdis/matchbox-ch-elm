# matchbox-ch-elm
matchbox configured with ch-elm for validation
# Build container for matchbox configured with ch-elm

```
docker build -t matchbox-ch-elm .
docker run -d --name matchbox-ch-elm -p 8080:8080 matchbox-ch-elm
```


after startup matchbox will be available at

localhost:8080/matchbox/

