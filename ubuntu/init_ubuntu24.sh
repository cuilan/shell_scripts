#!/bin/bahs

set -e

TZ='Asia/Shanghai'

SOURCES_LIST_URL="https://raw.githubusercontent.com/cuilan/source/main/ubuntu/sources.list"

OZ_DOWNLOAD_URL='https://github.com/robbyrussell/oh-my-zsh.git'
OZ_AUTOSUGGESTIONS_DOWNLOAD_URL='https://github.com/zsh-users/zsh-autosuggestions.git'
OZ_SYNTAX_HIGHLIGHTING_DOWNLOAD_URL='https://github.com/zsh-users/zsh-syntax-highlighting.git'
OZ_CONFIG_DOWNLOAD_URL='https://raw.githubusercontent.com/cuilan/source/main/zsh/zshrc'

VIM_CONFIG_DOWNLOAD_URL='https://raw.githubusercontent.com/cuilan/source/main/vim/vimrc'

DOCKER_LIST_URL='https://raw.githubusercontent.com/cuilan/source/main/docker/docker.list'
DOCKER_CONFIG_DOWNLOAD_URL=''

function sysupdate() {

    apt update -y
    apt upgrade -y
    apt install -y apt-transport-https ca-certificates \
        software-properties-common wget vim zsh git htop \
        tzdata language-pack-en-base language-pack-en
    #conntrack ipvsadm ipset stress sysstat axel
    apt autoremove -y
    apt autoclean -y
}


sysupdate
# setlocale
# settimezone
# install_ohmyzsh
# config_vim
# install_docker
# config_docker
# config_china_docker