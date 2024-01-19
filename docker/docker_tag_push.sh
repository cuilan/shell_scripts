#!/bin/bash

REPOSITORY="10.123.1.46:5000/"

if [ "$1" == "" ]; then
    echo -e "\033[31mError: imageName is blank!\033[0m"
    exit 1
else
    docker tag $1 ${REPOSITORY}$1
    docker push ${REPOSITORY}$1
fi
