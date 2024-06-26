#!/bin/bash

set -e

TZ='Asia/Shanghai'
OS_RELEASE="$(lsb_release -cs)"
SOURCES_LIST_URL="https://raw.githubusercontent.com/cuilan/source/main/ubuntu/sources.list"

OZ_DOWNLOAD_URL='https://github.com/robbyrussell/oh-my-zsh.git'
OZ_AUTOSUGGESTIONS_DOWNLOAD_URL='https://github.com/zsh-users/zsh-autosuggestions.git'
OZ_SYNTAX_HIGHLIGHTING_DOWNLOAD_URL='https://github.com/zsh-users/zsh-syntax-highlighting.git'
OZ_CONFIG_DOWNLOAD_URL='https://raw.githubusercontent.com/cuilan/source/main/zsh/zshrc'

VIM_CONFIG_DOWNLOAD_URL='https://raw.githubusercontent.com/cuilan/source/main/vim/vimrc'

DOCKER_LIST_URL='https://raw.githubusercontent.com/cuilan/source/main/docker/docker.list'
DOCKER_CONFIG_DOWNLOAD_URL=''

function sysupdate() {
    if [ ! -f /etc/apt/sources.list.old ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.old
        curl -fsSL ${SOURCES_LIST_URL} | sed "s@{{OS_RELEASE}}@${OS_RELEASE}@gi" >/etc/apt/sources.list
    fi
    apt update -y
    apt upgrade -y
    apt install -y apt-transport-https ca-certificates \
        software-properties-common wget vim zsh git htop \
        tzdata language-pack-en-base language-pack-en
    #conntrack ipvsadm ipset stress sysstat axel
    apt autoremove -y
    apt autoclean -y
}

function setlocale() {
    #localectl list-locales
    localectl set-locale LANG=en_US.UTF-8
}

function settimezone() {
    timedatectl set-timezone ${TZ}
}

function install_ohmyzsh() {
    if [ ! -d ~/.oh-my-zsh ]; then
        git clone --depth=1 ${OZ_DOWNLOAD_URL} ~/.oh-my-zsh
        git clone ${OZ_AUTOSUGGESTIONS_DOWNLOAD_URL} ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        git clone ${OZ_SYNTAX_HIGHLIGHTING_DOWNLOAD_URL} ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        curl -fsSL ${OZ_CONFIG_DOWNLOAD_URL} >~/.zshrc
        chsh -s $(grep /zsh$ /etc/shells | tail -1)
    fi
}

function config_vim() {
    curl -fsSL ${VIM_CONFIG_DOWNLOAD_URL} >~/.vimrc
    mkdir -p ~/.vim/bundle
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall
}

function install_docker() {
	for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    curl -fsSL ${DOCKER_LIST_URL} | sed "s@{{OS_RELEASE}}@${OS_RELEASE}@gi" >/etc/apt/sources.list.d/docker.list
    curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -
    apt update -y
    apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
}

function config_docker() {
    mkdir -p /data/docker
    cat > /etc/docker/daemon.json << EOF
{
    "data-root": "/data/docker",
    "debug": true,
    "experimental": true,
    "insecure-registries": [
    ],
    "log-driver": "json-file",
    "log-opts": {
        "max-file": "3",
        "max-size": "30m"
    },
    "registry-mirrors": [
    ]
}
EOF

    systemctl daemon-reload
    systemctl restart docker.service
}

function config_china_docker() {
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
        "max-size": "30m"
    },
    "registry-mirrors": [
        "http://docker.mirrors.ustc.edu.cn",
        "http://hub-mirror.c.163.com"
    ]
}
EOF

    systemctl daemon-reload
    systemctl restart docker.service
}

# sysupdate
# setlocale
# settimezone
# install_ohmyzsh
# config_vim
# install_docker
config_docker
# config_china_docker
