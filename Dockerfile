FROM europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox:v3.8.9

USER root
RUN mkdir -p /config && chown matchbox:matchbox /config
COPY ./src/application.yaml /config
COPY ./src/*.tgz /
USER matchbox
EXPOSE 80
RUN java -Xmx3G -Xms1G -jar /matchbox.jar --hapi.fhir.only_install_packages=true
