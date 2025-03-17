FROM node:22.14.0-alpine3.21 AS build

RUN apk update && apk add libjxl=0.10.4-r0 \
  libxml2=2.13.4-r5

# install all native build libs
RUN apk add --no-cache --update \
  bash \
  curl \
  ffmpeg \
  libwebp-tools \
  openjdk11 \
  openssl \
  unzip \
  zstd

#RUN npm uninstall --location=global cross-spawn

#RUN npm i --location=global dotenv-cli cross-spawn

# Enable Corepack
RUN corepack enable

# Install & activate a specific Yarn version (e.g., 4.7.0)
RUN corepack prepare yarn@4.7.0 --activate

# set java env variables for sonar
ENV JAVA_HOME=/usr/lib/jvm/default-jvm/jre \
  PATH="/usr/lib/jvm/default-jvm/jre/bin:$PATH"

# download latest version of sonar
# it needs to be stored in special folder for
# sonarqube-scanner
ENV SONAR_SCANNER_VERSION=7.0.2.4839
ENV SONAR_BINARY_CACHE=/tmp
ENV SONAR_ZIP_LOCATION=${SONAR_BINARY_CACHE}/sonar-scanner.zip
ENV SONAR_MAIN_FOLDER=${SONAR_BINARY_CACHE}/.sonar/native-sonar-scanner

# download sonar launcher
ADD https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}.zip ${SONAR_ZIP_LOCATION}

# store in special folder
# based on https://github.com/bellingard/sonar-scanner-npm/blob/6071ae7928a77138e6651e665097284c8accaa1d/src/sonar-scanner-executable.js#L62
RUN mkdir -p ${SONAR_MAIN_FOLDER} && \
  unzip ${SONAR_ZIP_LOCATION} -d ${SONAR_MAIN_FOLDER} && \
  mv ${SONAR_MAIN_FOLDER}/sonar-scanner-${SONAR_SCANNER_VERSION} ${SONAR_MAIN_FOLDER}/sonar-scanner-${SONAR_SCANNER_VERSION}-linux && \
  rm ${SONAR_ZIP_LOCATION}

# add sonar scanner to path
ENV PATH="${SONAR_MAIN_FOLDER}/sonar-scanner-${SONAR_SCANNER_VERSION}-linux/bin:$PATH"

# https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/
# Java heap space error or java.lang.OutOfMemoryError
ENV SONAR_SCANNER_OPTS="-Xmx512m"
