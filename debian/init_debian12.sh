#!/bin/bash

set -e

TZ='Asia/Shanghai'

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
    echo "正在配置Vim编辑器..."
    
    # 创建基础 vimrc 配置
    create_vimrc() {
        local vimrc_path="$1"
        local owner="$2"
        
        # 如果系统有默认 vimrc，先复制它
        if [ ! -f "$vimrc_path" ]; then
            if [ -f /etc/vim/vimrc ]; then
                cp /etc/vim/vimrc "$vimrc_path"
            else
                # 如果没有系统默认配置，创建一个基础配置
                touch "$vimrc_path"
            fi
        fi
        
        # 添加基础配置（如果不存在）
        # 幂等性：检查是否已存在关键配置，避免重复添加
        if ! grep -q "au BufReadPost \* if line" "$vimrc_path" 2>/dev/null; then
            cat >> "$vimrc_path" << 'EOF'

" 基础设置
set number
set background=dark
set compatible
syntax on
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
EOF
            echo "已添加 Vim 基础配置到 $vimrc_path"
        else
            echo "Vim 基础配置已存在于 $vimrc_path"
        fi
        
        # 设置文件所有者
        if [ -n "$owner" ]; then
            chown "$owner:$owner" "$vimrc_path" 2>/dev/null || true
        fi
    }
    
    # 为root用户配置vim
    create_vimrc "/root/.vimrc" ""
    echo "✓ 已为root用户配置Vim（语法高亮和行号）"
    
    # 如果指定了用户，也为该用户配置vim
    if [ -n "$USERNAME" ] && [ -d "/home/$USERNAME" ]; then
        create_vimrc "/home/$USERNAME/.vimrc" "$USERNAME"
        echo "✓ 已为用户 $USERNAME 配置Vim（语法高亮和行号）"
    fi
    
    echo "✓ Vim配置完成"
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
    echo ""
    echo "=== Zsh 配置 ==="
    
    read -p "是否安装和配置 Zsh？（y/N）: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "跳过 Zsh 安装"
        return
    fi
    
    echo "正在安装 Zsh..."
    apt update -y
    apt install -y zsh
    
    # 检查是否安装成功
    if command -v zsh &> /dev/null; then
        echo "✓ Zsh 安装成功"
        
        # 如果配置了用户，为该用户设置 zsh 为默认 shell
        if [ -n "$USERNAME" ] && id "$USERNAME" &>/dev/null; then
            read -p "是否为用户 $USERNAME 设置 Zsh 为默认 shell？（Y/n）: " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                chsh -s $(which zsh) "$USERNAME" 2>/dev/null || echo "⚠ 无法为用户 $USERNAME 设置 Zsh，请手动执行: chsh -s $(which zsh)"
                echo "✓ 已为用户 $USERNAME 设置 Zsh 为默认 shell（需要重新登录生效）"
            fi
        fi
        
        # 为 root 用户设置 zsh（可选）
        read -p "是否为 root 用户设置 Zsh 为默认 shell？（y/N）: " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chsh -s $(which zsh) root 2>/dev/null || echo "⚠ 无法为 root 设置 Zsh"
            echo "✓ 已为 root 设置 Zsh 为默认 shell（需要重新登录生效）"
        fi
    else
        echo "⚠ Zsh 安装失败"
    fi
}

function configStaticIP() {
    echo ""
    echo "=== 静态IP配置 ==="
    
    read -p "是否配置静态IP？（如果虚拟机已配置静态IP可跳过）（y/N）: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "跳过静态IP配置"
        return
    fi
    
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
    echo ""
    echo "=== 用户配置 ==="
    
    read -p "是否配置用户？（y/N）: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "跳过用户配置"
        return
    fi
    
    read -p "请输入用户名（直接回车跳过）: " USERNAME
    
    if [ -n "$USERNAME" ]; then
        # 检查用户是否存在
        if ! id "$USERNAME" &>/dev/null; then
            read -p "用户 $USERNAME 不存在，是否创建新用户？（Y/n）: " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                echo "正在创建用户 $USERNAME..."
                /usr/sbin/useradd -m -s /bin/bash "$USERNAME" || useradd -m -s /bin/bash "$USERNAME"
                echo "请为用户 $USERNAME 设置密码:"
                passwd "$USERNAME"
            else
                echo "跳过用户创建"
                return
            fi
        else
            echo "用户 $USERNAME 已存在"
        fi
        
        # 将用户添加到sudo组
        /usr/sbin/usermod -aG sudo "$USERNAME" || usermod -aG sudo "$USERNAME"
        
        # 确保sudo组在sudoers中有权限
        if ! grep -q "^%sudo" /etc/sudoers; then
            echo "%sudo   ALL=(ALL:ALL) ALL" >> /etc/sudoers
        fi
        
        echo "✓ 用户 $USERNAME 已添加到sudo组"
        echo "  该用户现在可以使用sudo命令"
    else
        echo "跳过用户配置"
    fi
}

function configChronyd() {
    echo "正在配置Chronyd时间同步服务..."
    
    # 注意：时间同步是基础配置，默认执行，不询问
    
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
    
    # 启动并启用chrony服务
    # 注意：Debian 12 中服务名称是 chrony.service，不是 chronyd.service
    echo "启动 Chrony 服务..."
    
    # 尝试启动服务（忽略错误，避免脚本中断）
    local chrony_service="chrony"
    if systemctl start "$chrony_service" 2>/dev/null; then
        echo "✓ Chrony 服务启动命令执行成功"
    else
        echo "⚠ systemctl start chrony 执行失败，尝试其他方式..."
        # 尝试直接运行 chronyd（如果 systemctl 不可用）
        if command -v chronyd &> /dev/null; then
            chronyd -d 2>/dev/null &
            sleep 2
        fi
    fi
    
    # 尝试启用服务（忽略错误）
    systemctl enable "$chrony_service" 2>/dev/null || echo "⚠ 无法启用 chrony 服务（可能已启用或 systemd 不可用）"
    
    # 等待服务启动
    sleep 3
    
    # 验证chrony状态（多种方式检查）
    local chrony_running=false
    
    # 方式1：检查systemd服务状态
    if systemctl is-active "$chrony_service" >/dev/null 2>&1; then
        chrony_running=true
        echo "✓ Chrony 服务通过 systemd 启动成功"
    # 方式2：检查进程是否运行
    elif pgrep -x chronyd >/dev/null 2>&1; then
        chrony_running=true
        echo "✓ Chronyd 进程正在运行"
    # 方式3：检查端口是否监听（chronyd默认监听323端口）
    elif netstat -tuln 2>/dev/null | grep -q ":323 " || ss -tuln 2>/dev/null | grep -q ":323 "; then
        chrony_running=true
        echo "✓ Chronyd 端口正在监听"
    fi
    
    if [ "$chrony_running" = "true" ]; then
        echo ""
        echo "=== Chrony 状态信息 ==="
        systemctl status "$chrony_service" --no-pager -l 2>/dev/null || echo "（无法获取 systemd 状态）"
        echo ""
        echo "=== 时间同步源状态 ==="
        chrony sources -v 2>/dev/null || chronyc sources -v 2>/dev/null || echo "（无法获取同步源状态）"
        echo ""
        echo "=== 时间同步统计 ==="
        chrony tracking 2>/dev/null || chronyc tracking 2>/dev/null || echo "（无法获取同步统计）"
        echo ""
        echo "✓ 时间同步配置完成"
        
        # 强制立即同步时间
        chrony makestep 2>/dev/null || chronyc makestep 2>/dev/null || true
        echo "已强制执行时间同步"
    else
        echo "⚠ Chrony 服务可能未正常启动"
        echo "  请手动检查："
        echo "  • systemctl status chrony"
        echo "  • journalctl -xeu chrony"
        echo "  • 检查 /etc/chrony/chrony.conf 配置"
        echo "  配置已保存，可以稍后手动启动服务"
    fi
}

function configDocker() {
    echo ""
    echo "=== Docker 安装 ==="
    
    read -p "是否安装 Docker？（y/N）: " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "跳过 Docker 安装"
        return
    fi
    
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
    
    # 检查 GPG 密钥文件是否已存在且有效
    local docker_gpg="/etc/apt/keyrings/docker.gpg"
    local need_download=true
    
    if [ -f "$docker_gpg" ]; then
        # 验证现有文件是否为有效的 GPG 密钥
        if gpg --no-default-keyring --keyring "$docker_gpg" --list-keys &>/dev/null; then
            echo "✓ Docker GPG 密钥已存在且有效，跳过下载"
            need_download=false
        else
            echo "⚠ 现有 GPG 密钥文件无效，将重新下载"
            rm -f "$docker_gpg"
        fi
    fi
    
    # 如果需要下载，尝试下载 GPG 密钥（带重试机制）
    if [ "$need_download" = "true" ]; then
        echo "正在下载 Docker GPG 密钥..."
        local max_retries=3
        local retry=0
        local download_success=false
        
        while [ $retry -lt $max_retries ]; do
            if curl -fsSL --connect-timeout 10 --max-time 30 https://download.docker.com/linux/debian/gpg | gpg --dearmor -o "$docker_gpg" 2>/dev/null; then
                download_success=true
                break
            else
                retry=$((retry + 1))
                if [ $retry -lt $max_retries ]; then
                    echo "⚠ 下载失败，正在重试 ($retry/$max_retries)..."
                    sleep 2
                fi
            fi
        done
        
        if [ "$download_success" = "true" ]; then
            chmod a+r "$docker_gpg"
            echo "✓ Docker GPG 密钥下载成功"
        else
            echo "❌ Docker GPG 密钥下载失败（已重试 $max_retries 次）"
            echo "  可能的原因："
            echo "  • 网络连接问题"
            echo "  • Docker 官方服务器暂时不可用"
            echo ""
            echo "  请选择："
            echo "  1. 跳过 Docker 安装（推荐，可稍后手动安装）"
            echo "  2. 继续尝试安装（可能失败）"
            read -p "请输入选择 (1/2，默认1): " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[2]$ ]]; then
                echo "已跳过 Docker 安装"
                return 0
            else
                echo "⚠ 继续安装，但可能因为缺少 GPG 密钥而失败"
            fi
        fi
    fi
    
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
    echo ""
    echo "=========================================="
    echo "Debian 12 系统初始化脚本"
    echo "=========================================="
    echo ""
    
    # 第一步：基础系统更新和配置
    echo "=== 第一步：系统更新和基础配置 ==="
    echo "正在更新系统..."
    sysUpdate
    
    echo "正在设置本地化..."
    setLocale
    
    echo "正在设置时区..."
    setTimezone
    
    echo "正在配置Bash环境..."
    configBash
    
    echo "正在配置Chronyd时间同步服务..."
    configChronyd
    
    echo ""
    echo "✓ 基础配置完成"
    echo ""
    
    # 第二步：询问是否配置静态IP
    configStaticIP
    
    # 第三步：配置用户
    configUser
    
    # 第四步：询问是否安装 Zsh
    configZsh
    
    # 第五步：询问是否安装 Docker
    configDocker
    
    echo ""
    echo "=========================================="
    echo "系统初始化完成！"
    echo "=========================================="
    echo ""
    
    if [ -n "$USERNAME" ]; then
        echo "提示："
        echo "  • 用户 $USERNAME 已配置 sudo 权限"
        if command -v zsh &> /dev/null; then
            echo "  • Zsh 已安装，重新登录后生效"
        fi
        if docker --version &> /dev/null; then
            echo "  • Docker 已安装，用户 $USERNAME 需要重新登录才能免 sudo 使用 docker"
        fi
    fi
    echo ""
}

main
