FROM europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox:v3.9.6

COPY ./src/application.yaml /config
COPY ./src/*.tgz /
EXPOSE 80
RUN java -Xmx3G -Xms1G -jar /matchbox.jar --hapi.fhir.only_install_packages=true
