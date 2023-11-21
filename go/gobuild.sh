#!/bin/bash

set -ex

GOLANG_IMAGE_NAME=cuilan/golang:1.21-alpine

# go build
docker run --rm --volume $(pwd):/work ${GOLANG_IMAGE_NAME} \
    go build -o /work/main /work/main.go

# docker run --rm --volume $(pwd):/work cuilan/golang:1.21-alpine go build -o /work/main /work/main.go