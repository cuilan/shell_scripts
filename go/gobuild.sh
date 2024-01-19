#!/usr/bin/env bash

set -ex

GOLANG_IMAGE_NAME=cuilan/golang:1.21-alpine

# go build
docker run --rm --volume $1:/work ${GOLANG_IMAGE_NAME} \
    bash -c "cd /work && go mod tidy && go mod download && go build -o main ."

# docker run --rm --volume $(pwd):/work ${GOLANG_IMAGE_NAME} \
    # bash -c "cd /work && go mod tidy && go mod download && go build -o main ."
