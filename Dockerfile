FROM europe-west6-docker.pkg.dev/ahdis-ch/ahdis/matchbox:v5.0.0-rc2

COPY ./src/application.yaml /config
COPY ./src/*.tgz /

# Use root to maintain the system
USER root

# Update packages, in case the Matchbox image is too old
RUN apt update && apt upgrade -y

# Remove the package management tools for security reasons
#RUN dpkg -r --force-all apt apt-get && dpkg -r --force-all debconf dpkg

# Switch back to the matchbox user
USER matchbox

EXPOSE 80

# The Matchbox image checks port 8080, this image runs on the port of src/application.yaml
ENV HEALTHCHECK_URL=http://localhost:80/matchboxv3/actuator/health

RUN java -Xmx3G -Xms1G -jar /matchbox.jar --hapi.fhir.only_install_packages=true
