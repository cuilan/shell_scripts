#!/usr/bin/env bash

set -ex

BUILD_DATE=`date +%Y%m%d%H%M%S`

PROJECT_NAME=${PROJECT_NAME:-"default"}

BUILD_HOST=${BUILD_HOST:-"unix:///var/run/docker.sock"}
DOCKERFILE=${DOCKERFILE:-"./ci/Dockerfile"}

while getopts "h:f:n:" OPT; do
    case $OPT in
        h)
            BUILD_HOST=$OPTARG;;
        f)
            DOCKERFILE=$OPTARG;;
        n)
            PROJECT_NAME=$OPTARG;;
        *)
    esac
done

IMAGE_NAME=10.123.1.46:5000/deployment/${PROJECT_NAME}:${BUILD_DATE}
LATEST_IMAGE_NAME=10.123.1.46:5000/deployment/${PROJECT_NAME}:latest

# build
cat ${DOCKERFILE} \
    | sed "s@{{REG_HOST}}@${REG_HOST}@g" \
    | docker -H ${BUILD_HOST} build -t ${IMAGE_NAME} -f - .

# login
#docker -H ${BUILD_HOST} login ${REG_HOST} -u ${REG_USER} -p ${REG_PWD}

# push
docker -H ${BUILD_HOST} tag ${IMAGE_NAME} ${LATEST_IMAGE_NAME}
docker -H ${BUILD_HOST} push ${IMAGE_NAME}
docker -H ${BUILD_HOST} push ${LATEST_IMAGE_NAME}

# 本地运行不用删
docker -H ${BUILD_HOST} rmi ${IMAGE_NAME}
docker -H ${BUILD_HOST} rmi ${LATEST_IMAGE_NAME}

echo "Build image success --> ${IMAGE_NAME}"

# ./docker_build.sh -f ./Dockerfile -n xxxx