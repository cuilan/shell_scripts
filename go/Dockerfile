FROM cuilan/alpine:latest

LABEL maintainer="cuilan <17746598041@163.com>"

ARG SRC_PATH

ENV SRC_PATH ${SRC_PATH}

WORKDIR /app

COPY ${SRC_PATH} .

CMD ["./main"]