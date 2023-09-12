#!/bin/bash

set -ex

JAVA_IMAGE_NAME="cuilan/javabuild8:hotspot"

# mvn package
docker run --rm \
        --volume .:/work \
        --volume $HOME/.m2/repository:/data/maven_cache ${JAVA_IMAGE_NAME} \
        /usr/local/bin/cmvn package -Dmaven.test.skip=true -f /work/pom.xml

docker run --rm \
        --volume .:/work \
        --volume $HOME/.m2/settings.xml:/settings.xml \
        --volume $HOME/.m2/repository:/data/maven_cache ${JAVA_IMAGE_NAME} \
        /usr/local/bin/cmvn --settings /settings.xml package -Dmaven.test.skip=true -f /work/pom.xml

# mvn clean
docker run --rm \
        --volume .:/work \
        --volume $HOME/.m2/repository:/data/maven_cache ${JAVA_IMAGE_NAME} \
        /usr/local/bin/cmvn clean -f /work/pom.xml

# gradle build
docker run --rm \
        --volume .:/work ${JAVA_IMAGE_NAME} \
        /usr/local/bin/cgradle build -p /work/

# gradle clean
docker run --rm \
        --volume .:/work ${JAVA_IMAGE_NAME} \
        /usr/local/bin/cgradle clean -p /work/

# gradlew build
docker run --rm \
        --volume .:/work ${JAVA_IMAGE_NAME} \
        /work/gradlew build -p /work/

# gradlew clean
docker run --rm \
        --volume .:/work ${JAVA_IMAGE_NAME} \
        /work/gradlew clean -p /work/