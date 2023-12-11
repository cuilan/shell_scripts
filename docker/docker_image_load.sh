#!/bin/bash

set -e

if [ "$1" == "" ]; then
    echo -e "\033[31mError: imageName is blank!\033[0m"
    exit 1
else
    docker load < $1
fi