#!/bin/bash

set -e

TZ='Asia/Shanghai'
REPOSITORIES_URL="https://raw.githubusercontent.com/cuilan/source/main/alpine/repo-v3_19"

OZ_DOWNLOAD_URL='https://github.com/robbyrussell/oh-my-zsh.git'
OZ_AUTOSUGGESTIONS_DOWNLOAD_URL='https://github.com/zsh-users/zsh-autosuggestions.git'
OZ_SYNTAX_HIGHLIGHTING_DOWNLOAD_URL='https://github.com/zsh-users/zsh-syntax-highlighting.git'
OZ_CONFIG_DOWNLOAD_URL='https://raw.githubusercontent.com/cuilan/source/main/zsh/zshrc'

VIM_CONFIG_DOWNLOAD_URL='https://raw.githubusercontent.com/cuilan/source/main/vim/vimrc'

DOCKER_LIST_URL='https://raw.githubusercontent.com/cuilan/source/main/docker/docker.list'
DOCKER_CONFIG_DOWNLOAD_URL=''

function sysupdate() {
    if [ ! -f /etc/apk/repositories.bak ]; then
        cp /etc/apk/repositories /etc/apk/repositories.old
        curl -fsSL ${REPOSITORIES_URL} >/etc/apk/repositories
    fi
    apk update
    apk upgrade
}

function addpkg() {
    apk add bash zsh ca-certificates vim git htop tzdata
}

function settimezone() {
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
        && echo ${TZ} > /etc/timezone
}

function install_ohmyzsh() {
    if [ ! -d ~/.oh-my-zsh ]; then
        git clone --depth=1 ${OZ_DOWNLOAD_URL} ~/.oh-my-zsh
        git clone ${OZ_AUTOSUGGESTIONS_DOWNLOAD_URL} ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        git clone ${OZ_SYNTAX_HIGHLIGHTING_DOWNLOAD_URL} ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        curl -fsSL ${OZ_CONFIG_DOWNLOAD_URL} >~/.zshrc
        # vim /etc/passwd update the default shell to zsh
    fi
}

function config_vim() {
    curl -fsSL ${VIM_CONFIG_DOWNLOAD_URL} >~/.vimrc
    mkdir -p ~/.vim/bundle
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall
}

function install_docker() {
    # install
    apk add docker docker-cli-compose
    # and root to docker group
    addgroup root docker

    # config
    mkdir -p /data/docker
    mkdir -p /etc/docker
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

    rc-update add docker default
    service docker start
    
    # 重启命令，怕忘
    # rc-service docker restart
}

function install_containerd() {
    # install
    apk add containerd containerd-ctr

    if [ ! -f /etc/containerd/config.toml.bak ]; then
        cp /etc/containerd/config.toml /etc/containerd/config.toml.old
        sed -i "s@/var/lib/containerd@/data/containerd@" /etc/containerd/config.toml
    fi

    rc-update add containerd default
    service containerd start
    rc-service containerd restart
}

# sysupdate
# addpkg
# settimezone
# install_ohmyzsh
# config_vim
# install_docker
install_containerd
