#!/bin/bash

set -e

TZ='Asia/Shanghai'
OS_RELEASE="$(lsb_release -cs)"
OZ_DOWNLOAD_URL='https://github.com/robbyrussell/oh-my-zsh.git'
OZ_SYNTAX_HIGHLIGHTING_DOWNLOAD_URL='https://github.com/zsh-users/zsh-syntax-highlighting.git'
OZ_CONFIG_DOWNLOAD_URL=''

function sysupdate(){
    apt update -y
    apt upgrade -y
    apt install -y apt-transport-https ca-certificates \
		software-properties-common wget vim zsh git htop \
		tzdata language-pack-en-base language-pack-en
		#conntrack ipvsadm ipset stress sysstat axel
    apt autoremove -y
    apt autoclean -y
}

function setlocale(){
	#localectl list-locales
    localectl set-locale LANG=en_US.UTF-8
}

function settimezone(){
    timedatectl set-timezone ${TZ}
}

function install_ohmyzsh(){
    if [ ! -d ~/.oh-my-zsh ]; then
        git clone --depth=1 ${OZ_DOWNLOAD_URL} ~/.oh-my-zsh
        git clone ${OZ_SYNTAX_HIGHLIGHTING_DOWNLOAD_URL} ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        #curl -fsSL ${OZ_CONFIG_DOWNLOAD_URL} > ~/.zshrc
        cp ${ZSH_TEMPLATES:-~/.oh-my-zsh/templates}/zshrc.zsh-template ~/.zshrc
		chsh -s $(grep /zsh$ /etc/shells | tail -1)
    fi
}

function config_vim(){

}

function install_docker(){

}

function install_dc(){
    curl -fsSL ${DOCKER_COMPOSE_DOWNLOAD_URL} > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

#sysupdate
#setlocale
#settimezone
#install_ohmyzsh
config_vim
install_docker
install_dc
