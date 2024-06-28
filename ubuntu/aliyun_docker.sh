#!/bin/bash

set -e

sudo apt-get update

sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

# 安装GPG证书
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

# 添加docker源
sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get -y update

sudo apt-get -y upgrade

sudo apt-get -y install docker-ce
