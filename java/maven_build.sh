#!/bin/bash

set -ex

JAVA_IMAGE_NAME=cuilan/javabuild8:hotspot

MAVEN_REPOSITORY=$HOME/.m2/repository
CONTAINER_MAVEN_CACHE_DIR=/data/maven_cache

MAVEN_SETTING_DIR=$HOME/.m2/settings.xml

# mvn package
docker run --rm \
        --volume .:/work \
        --volume ${MAVEN_SETTING_DIR}:/data/settings.xml \
        --volume ${MAVEN_REPOSITORY}:${CONTAINER_MAVEN_CACHE_DIR} ${JAVA_IMAGE_NAME} \
        /usr/local/bin/cmvn --settings /data/settings.xml package -Dmaven.test.skip=true -f /work/pom.xml

# mvn clean
# docker run --rm \
        # --volume .:/work \
        # --volume ${MAVEN_SETTING_DIR}:/data/settings.xml \
        # --volume ${MAVEN_REPOSITORY}:${CONTAINER_MAVEN_CACHE_DIR} ${JAVA_IMAGE_NAME} \
        # /usr/local/bin/cmvn --settings /data/settings.xml clean -Dmaven.test.skip=true -f /work/pom.xml
