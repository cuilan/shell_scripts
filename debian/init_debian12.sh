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
        software-properties-common wget curl vim zsh git htop sudo tzdata \
        passwd
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
    echo "正在配置Bash环境..."
    
    # 为root用户配置.bashrc
    if ! grep -q "/usr/sbin:/sbin" /root/.bashrc 2>/dev/null; then
        cat >> /root/.bashrc << 'EOF'

# 添加系统管理目录到PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
EOF
    fi
    
    # 为所有用户配置全局环境变量
    cat > /etc/environment << 'EOF'
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF
    
    # 配置/etc/profile以确保所有用户登录时都有正确的PATH
    if ! grep -q "PATH.*sbin" /etc/profile 2>/dev/null; then
        cat >> /etc/profile << 'EOF'

# 确保所有用户都有完整的PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF
    fi
    
    # 为weattech用户配置.bashrc（如果存在）
    if [ -d /home/weattech ]; then
        if ! grep -q "/usr/sbin:/sbin" /home/weattech/.bashrc 2>/dev/null; then
            cat >> /home/weattech/.bashrc << 'EOF'

# 添加系统管理目录到PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
EOF
            chown weattech:weattech /home/weattech/.bashrc 2>/dev/null || true
        fi
    fi
    
    echo "已配置系统PATH环境变量"
    echo "当前PATH: $PATH"
}

function configZsh() {

}

function configStaticIP() {
    echo "正在配置静态IP..."
    
    # 获取网络接口名称
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [ -z "$INTERFACE" ]; then
        echo "未找到默认网络接口，请手动指定"
        return 1
    fi
    
    echo "检测到网络接口: $INTERFACE"
    echo "请输入静态IP配置信息:"
    
    read -p "IP地址 (例如: 192.168.1.100): " STATIC_IP
    read -p "子网掩码 (例如: 24 或 255.255.255.0): " NETMASK
    read -p "网关地址 (例如: 192.168.1.1): " GATEWAY
    read -p "DNS服务器 (例如: 8.8.8.8): " DNS_SERVER
    
    # 备份原始网络配置
    if [ -f /etc/network/interfaces ]; then
        cp /etc/network/interfaces /etc/network/interfaces.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 配置静态IP
    cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto $INTERFACE
iface $INTERFACE inet static
    address $STATIC_IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS_SERVER
EOF
    
    # 配置DNS
    echo "nameserver $DNS_SERVER" > /etc/resolv.conf
    
    echo "静态IP配置完成!"
    echo "网络接口: $INTERFACE"
    echo "IP地址: $STATIC_IP"
    echo "子网掩码: $NETMASK"
    echo "网关: $GATEWAY"
    echo "DNS: $DNS_SERVER"
    echo ""
    echo "请重启网络服务或重启系统使配置生效:"
    echo "systemctl restart networking"
    echo "或者: reboot"
}

function configUser() {
    echo "正在配置用户权限..."
    
    # 检查是否有非root用户需要配置
    read -p "请输入需要配置sudo权限的用户名（直接回车跳过）: " USERNAME
    
    if [ -n "$USERNAME" ]; then
        # 检查用户是否存在
        if ! id "$USERNAME" &>/dev/null; then
            echo "用户 $USERNAME 不存在，正在创建..."
            /usr/sbin/useradd -m -s /bin/bash "$USERNAME" || useradd -m -s /bin/bash "$USERNAME"
            echo "请为用户 $USERNAME 设置密码:"
            passwd "$USERNAME"
        fi
        
        # 将用户添加到sudo组
        /usr/sbin/usermod -aG sudo "$USERNAME" || usermod -aG sudo "$USERNAME"
        
        # 确保sudo组在sudoers中有权限
        if ! grep -q "^%sudo" /etc/sudoers; then
            echo "%sudo   ALL=(ALL:ALL) ALL" >> /etc/sudoers
        fi
        
        echo "用户 $USERNAME 已添加到sudo组"
        echo "该用户现在可以使用sudo命令"
    else
        echo "跳过用户配置"
    fi
}

function configChronyd() {
    echo "正在配置Chronyd时间同步服务..."
    
    # 安装chrony
    apt update -y
    apt install -y chrony
    
    # 停止并禁用系统自带的systemd-timesyncd
    systemctl stop systemd-timesyncd 2>/dev/null || true
    systemctl disable systemd-timesyncd 2>/dev/null || true
    
    # 备份原始配置文件
    if [ -f /etc/chrony/chrony.conf ]; then
        cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 配置chrony.conf
    cat > /etc/chrony/chrony.conf << 'EOF'
# 使用中国的NTP服务器池
pool ntp.aliyun.com iburst
pool ntp1.aliyun.com iburst
pool ntp2.aliyun.com iburst
pool cn.pool.ntp.org iburst

# 备用国外NTP服务器
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst

# 记录系统时钟获得/丢失时间的速率
driftfile /var/lib/chrony/chrony.drift

# 允许系统时钟被大幅度调整
makestep 1 3

# 启用内核同步RTC
rtcsync

# 启用硬件时间戳（如果可用）
#hwtimestamp *

# 增加调度优先级
sched_priority 1

# 指定NTP客户端日志文件
logdir /var/log/chrony

# 允许本地网络的客户端访问（如果需要作为NTP服务器）
#allow 192.168.0.0/16
#allow 10.0.0.0/8
#allow 172.16.0.0/12

# 本地时钟作为备用
local stratum 10
EOF
    
    # 启动并启用chronyd服务
    systemctl start chronyd
    systemctl enable chronyd
    
    # 等待服务启动
    sleep 3
    
    # 验证chronyd状态
    if systemctl is-active chronyd >/dev/null 2>&1; then
        echo "Chronyd服务启动成功!"
        echo ""
        echo "=== Chronyd状态信息 ==="
        systemctl status chronyd --no-pager -l
        echo ""
        echo "=== 时间同步源状态 ==="
        chrony sources -v
        echo ""
        echo "=== 时间同步统计 ==="
        chrony tracking
        echo ""
        echo "时间同步配置完成!"
    else
        echo "Chronyd服务启动失败，请检查配置"
        return 1
    fi
    
    # 强制立即同步时间
    chrony makestep
    echo "已强制执行时间同步"
}

function configDocker() {
    echo "正在安装Docker..."
    
    # 卸载旧版本Docker
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # 安装必要的依赖包
    apt update -y
    apt install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # 添加Docker官方GPG密钥
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # 添加Docker APT源
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 更新APT缓存并安装Docker CE
    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
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

    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 验证Docker安装
    if docker --version > /dev/null 2>&1; then
        echo "Docker安装成功!"
        docker --version
        echo ""
        echo "Docker服务状态:"
        systemctl status docker --no-pager -l
        echo ""
        
        # 自动将配置的用户添加到docker组
        if [ -n "$USERNAME" ]; then
            /usr/sbin/usermod -aG docker "$USERNAME" || usermod -aG docker "$USERNAME"
            echo "用户 $USERNAME 已添加到docker组"
            echo "该用户重新登录后可以免sudo运行docker命令"
        else
            echo "如需将用户添加到docker组（免sudo运行docker）："
            echo "sudo usermod -aG docker 用户名"
            echo "然后重新登录或执行: newgrp docker"
        fi
    else
        echo "Docker安装失败，请检查错误信息"
        return 1
    fi
}

function main() {
    echo "正在初始化Debian 12系统..."
    echo "请输入需要配置sudo权限的用户名（直接回车跳过）: "
    read -p "用户名: " USERNAME
    echo "正在更新系统..."
    sysUpdate
    echo "正在设置时区..."
    setLocale
    setTimezone
    echo "正在配置Bash环境..."
    configBash
    echo "正在配置用户权限..."
    configUser
    echo "正在配置Chronyd时间同步服务..."
    configChronyd
    echo "正在配置静态IP..."
    configStaticIP
    echo "正在安装Docker..."
    configDocker
}

main
