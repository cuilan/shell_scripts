#!/usr/bin/env bash

DOCKERHUB="docker.io/library/"
REPOSITORY="docker.m.daocloud.io/"

if [ "$1" == "" ]; then
    echo -e "\033[31mError: imageName is blank!\033[0m"
    exit 1
fi

image=$1

proxyImage=${REPOSITORY}${image}

echo -e "\033[32mpull ${proxyImage} \033[0m"
echo -e ""
docker pull ${proxyImage}

echo -e "\033[33mtag ${proxyImage} -> ${DOCKERHUB}${image} \033[0m"
echo -e ""
docker tag ${proxyImage} ${DOCKERHUB}${image}

echo -e "\033[34mrmi ${proxyImage} \033[0m"
echo -e ""
docker rmi ${proxyImage}