#!/bin/bash

# docker 安装

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

sudo sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo

sudo yum makecache fast
sudo yum -y install docker-ce:20.10.14

sudo service docker start

systemctl enable docker


mkdir -p /data/docker

cat > /etc/docker/daemon.json << EOF
{
    "data-root": "/data/docker",
    "debug": true,
    "experimental": true,
    "insecure-registries": [
        "docker.mirrors.ustc.edu.cn"
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-file": "3",
        "max-size": "50m"
    },
    "registry-mirrors": [
        "http://docker.mirrors.ustc.edu.cn",
        "http://hub-mirror.c.163.com"
    ]
}
EOF

systemctl restart docker

cp ./docker-compose /usr/local/bin/
chmod 755 /usr/local/bin/docker-compose
source /etc/profile

sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
