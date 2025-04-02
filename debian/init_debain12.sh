#!/bin/bash

set -e

TZ='Asia/Shanghai'

VIM_CONFIG_DOWNLOAD_URL='https://raw.githubusercontent.com/cuilan/source/main/vim/vimrc'

function sysUpdate() {
    if [ ! -f /etc/apt/sources.list.old ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.old
        cat > /etc/apt/sources.list << EOF
# tsinghua
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
# offical security
#deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF
    fi
    apt update -y
    apt upgrade -y
    apt install -y apt-transport-https ca-certificates \
        software-properties-common wget curl vim zsh git htop sudo tzdata
        #language-pack-en-base language-pack-en conntrack ipvsadm ipset stress sysstat axel
    apt autoremove -y
    apt autoclean -y
}

function setLocale() {
    #localectl list-locales
    localectl set-locale LANG=en_US.UTF-8
}

function setTimezone() {
    #timedatectl list-timezones
    timedatectl set-timezone ${TZ}
}

function configVim() {
    curl -fsSL ${VIM_CONFIG_DOWNLOAD_URL} >~/.vimrc
    mkdir -p ~/.vim/bundle
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    vim +PluginInstall +qall
}

function configBash() {

}

function configZsh() {

}

sysUpdate
setLocale
setTimezone
configBash