#!/bin/bash

# Debian 13 (Trixie) 快捷初始化脚本
# 作用：快速配置和初始化全新的Debian 13系统
# 使用方法：必须以root用户运行（系统初始化脚本）
# 注意：Debian 13安装后默认没有sudo命令，此脚本必须直接以root运行

#=============================================================================
# 配置区域 - 请根据实际环境修改以下变量
#=============================================================================

# 系统配置
SYSTEM_TIMEZONE='Asia/Shanghai'
SYSTEM_LOCALE='en_US.UTF-8'

# VIM配置
VIM_CONFIG_DOWNLOAD_URL='https://raw.githubusercontent.com/cuilan/source/main/vim/vimrc'

# APT镜像源配置 (默认使用清华大学镜像)
APT_MIRROR_BASE_URL='https://mirrors.tuna.tsinghua.edu.cn/debian/'

# 时间同步服务器
NTP_SERVERS=(
    "ntp.aliyun.com"
    "ntp1.aliyun.com" 
    "ntp2.aliyun.com"
    "cn.pool.ntp.org"
)

# Docker配置
DOCKER_DATA_ROOT="/data/docker"
DOCKER_REGISTRY_MIRRORS=(
    "http://docker.mirrors.ustc.edu.cn"
    "http://hub-mirror.c.163.com"
)

# 常用软件包列表
BASIC_PACKAGES=(
    apt-transport-https ca-certificates software-properties-common
    wget curl vim git htop sudo tzdata passwd
    zsh tree unzip zip net-tools lsof
    htop iotop sysstat stress axel
    build-essential python3-dev python3-pip
)

#=============================================================================
# 脚本执行区域 - 以下内容通常不需要修改  
#=============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 全局变量
USERNAME=""
INSTALL_DOCKER=false
INSTALL_STATIC_IP=false
INSTALL_CHRONY=false

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "${DEBUG}" == "1" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# 检查是否以root权限运行
# 注意：此脚本用于系统初始化，必须直接以root用户运行
# Debian 13安装后默认没有sudo命令，不能使用sudo运行此脚本
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须直接以root用户运行"
        log_error "Debian 13系统初始化时没有sudo命令，请使用root用户执行"
        log_info "切换root用户: su -"
        log_info "然后执行: $0"
        exit 1
    fi
    log_info "✓ 确认以root用户运行"
}

# 检查系统版本
check_debian_version() {
    if [[ ! -f /etc/debian_version ]]; then
        log_error "此脚本仅适用于Debian系统"
        exit 1
    fi
    
    local debian_version=$(cat /etc/debian_version)
    log_info "检测到Debian版本: $debian_version"
    
    # 检查是否为Debian 13/Trixie
    if grep -q "trixie\|13\|testing" /etc/os-release 2>/dev/null; then
        log_info "✓ 确认为Debian 13 (Trixie)系统"
    else
        log_warn "⚠ 未确认为Debian 13系统，继续执行可能存在兼容性问题"
        read -p "是否继续执行？(y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "已取消执行"
            exit 0
        fi
    fi
}

# 交互式配置选择
interactive_config() {
    echo ""
    log_info "=== Debian 13 系统初始化配置 ==="
    echo ""
    log_info "注意：此脚本必须以root用户运行（Debian 13安装后默认没有sudo命令）"
    echo ""
    
    # 用户配置
    # 注意：sudo会在system_update阶段安装，所以这里可以配置sudo权限
    read -p "请输入需要配置sudo权限的用户名（直接回车跳过）: " USERNAME
    
    # 功能选择
    echo ""
    echo "请选择需要安装/配置的功能："
    
    read -p "是否配置静态IP？(y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        INSTALL_STATIC_IP=true
    fi
    
    read -p "是否安装配置Chrony时间同步？(Y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_CHRONY=true
    fi
    
    read -p "是否安装Docker？(Y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        INSTALL_DOCKER=true
    fi
    
    echo ""
    log_info "配置确认："
    echo "  • 用户配置: ${USERNAME:-"跳过"}"
    echo "  • 静态IP配置: $INSTALL_STATIC_IP"
    echo "  • Chrony时间同步: $INSTALL_CHRONY"
    echo "  • Docker安装: $INSTALL_DOCKER"
    echo ""
    
    read -p "确认开始初始化？(Y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "已取消初始化"
        exit 0
    fi
}

# 系统更新和软件包安装
system_update() {
    log_info "开始更新系统和安装基础软件包..."
    
    # 备份原始sources.list
    if [[ ! -f /etc/apt/sources.list.backup ]]; then
        log_info "备份原始APT源配置..."
        cp /etc/apt/sources.list /etc/apt/sources.list.backup
    fi
    
    # 配置APT源 (Debian 13 Trixie)
    log_info "配置APT源为清华大学镜像..."
    cat > /etc/apt/sources.list << EOF
# Debian 13 (Trixie) - 清华大学镜像源
deb ${APT_MIRROR_BASE_URL} trixie main contrib non-free non-free-firmware
# deb-src ${APT_MIRROR_BASE_URL} trixie main contrib non-free non-free-firmware

deb ${APT_MIRROR_BASE_URL} trixie-updates main contrib non-free non-free-firmware
# deb-src ${APT_MIRROR_BASE_URL} trixie-updates main contrib non-free non-free-firmware

deb ${APT_MIRROR_BASE_URL} trixie-backports main contrib non-free non-free-firmware
# deb-src ${APT_MIRROR_BASE_URL} trixie-backports main contrib non-free non-free-firmware

# Debian 官方安全更新源
deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF
    
    # 更新软件包列表
    log_info "更新软件包列表..."
    apt update -y
    
    # 升级系统
    log_info "升级系统软件包..."
    apt upgrade -y
    
    # 安装基础软件包（包括sudo，这样后续配置才能使用sudo组）
    log_info "安装基础软件包（包括sudo等）..."
    apt install -y "${BASIC_PACKAGES[@]}"
    
    # 清理
    log_info "清理APT缓存..."
    apt autoremove -y
    apt autoclean -y
    
    log_info "✓ 系统更新和软件包安装完成"
}

# 设置系统本地化
set_locale() {
    log_info "配置系统本地化..."
    
    # 生成locale
    if command -v locale-gen &> /dev/null; then
        locale-gen ${SYSTEM_LOCALE}
    fi
    
    # 设置系统locale
    if command -v localectl &> /dev/null; then
        localectl set-locale LANG=${SYSTEM_LOCALE}
    else
        echo "export LANG=${SYSTEM_LOCALE}" >> /etc/environment
        echo "export LC_ALL=${SYSTEM_LOCALE}" >> /etc/environment
    fi
    
    log_info "✓ 系统本地化设置为: ${SYSTEM_LOCALE}"
}

# 设置时区
set_timezone() {
    log_info "设置系统时区为: ${SYSTEM_TIMEZONE}"
    
    if command -v timedatectl &> /dev/null; then
        timedatectl set-timezone ${SYSTEM_TIMEZONE}
    else
        ln -sf /usr/share/zoneinfo/${SYSTEM_TIMEZONE} /etc/localtime
        echo ${SYSTEM_TIMEZONE} > /etc/timezone
    fi
    
    log_info "✓ 时区设置完成"
}

# 配置Vim
config_vim() {
    log_info "配置Vim编辑器..."
    
    # 为root用户配置vim
    if curl -fsSL ${VIM_CONFIG_DOWNLOAD_URL} > /root/.vimrc 2>/dev/null; then
        log_info "✓ 已为root用户下载Vim配置"
    else
        log_warn "⚠ Vim配置下载失败，使用默认配置"
    fi
    
    # 如果指定了用户，也为该用户配置vim
    if [[ -n "$USERNAME" && -d "/home/$USERNAME" ]]; then
        if curl -fsSL ${VIM_CONFIG_DOWNLOAD_URL} > /home/$USERNAME/.vimrc 2>/dev/null; then
            chown $USERNAME:$USERNAME /home/$USERNAME/.vimrc
            log_info "✓ 已为用户 $USERNAME 下载Vim配置"
        fi
    fi
    
    # 安装Vundle插件管理器（可选）
    if command -v git &> /dev/null; then
        mkdir -p /root/.vim/bundle
        if [[ ! -d /root/.vim/bundle/Vundle.vim ]]; then
            git clone https://github.com/VundleVim/Vundle.vim.git /root/.vim/bundle/Vundle.vim 2>/dev/null || true
        fi
        
        # 为指定用户也安装（以root权限创建，然后修改所有者）
        if [[ -n "$USERNAME" && -d "/home/$USERNAME" ]]; then
            mkdir -p /home/$USERNAME/.vim/bundle
            chown -R $USERNAME:$USERNAME /home/$USERNAME/.vim 2>/dev/null || true
            if [[ ! -d /home/$USERNAME/.vim/bundle/Vundle.vim ]]; then
                # 以root权限克隆，然后修改所有者
                git clone https://github.com/VundleVim/Vundle.vim.git /home/$USERNAME/.vim/bundle/Vundle.vim 2>/dev/null || true
                chown -R $USERNAME:$USERNAME /home/$USERNAME/.vim/bundle/Vundle.vim 2>/dev/null || true
            fi
        fi
    fi
    
    log_info "✓ Vim配置完成"
}

# 配置Bash环境
config_bash() {
    log_info "配置Bash环境..."
    
    # 配置全局PATH环境变量
    cat > /etc/environment << 'EOF'
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF
    
    # 配置/etc/profile确保所有用户都有完整的PATH
    if ! grep -q "PATH.*sbin" /etc/profile 2>/dev/null; then
        cat >> /etc/profile << 'EOF'

# 确保所有用户都有完整的PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# 设置一些有用的别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
EOF
    fi
    
    # 为root用户配置.bashrc
    if ! grep -q "/usr/sbin:/sbin" /root/.bashrc 2>/dev/null; then
        cat >> /root/.bashrc << 'EOF'

# 添加系统管理目录到PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# 有用的别名
alias ll='ls -alF'
alias la='ls -A' 
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
EOF
    fi
    
    # 为指定用户配置.bashrc
    if [[ -n "$USERNAME" && -d "/home/$USERNAME" ]]; then
        if ! grep -q "/usr/sbin:/sbin" /home/$USERNAME/.bashrc 2>/dev/null; then
            cat >> /home/$USERNAME/.bashrc << 'EOF'

# 添加系统管理目录到PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# 有用的别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF' 
alias ..='cd ..'
alias ...='cd ../..'
EOF
            chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc 2>/dev/null || true
        fi
    fi
    
    log_info "✓ Bash环境配置完成"
}

# 配置用户权限
# 注意：sudo包已在system_update阶段安装，所以这里可以配置sudo权限
config_user() {
    if [[ -z "$USERNAME" ]]; then
        log_info "跳过用户配置"
        return
    fi
    
    log_info "配置用户权限: $USERNAME"
    
    # 检查用户是否存在
    if ! id "$USERNAME" &>/dev/null; then
        log_info "用户 $USERNAME 不存在，正在创建..."
        useradd -m -s /bin/bash "$USERNAME"
        
        echo "请为用户 $USERNAME 设置密码:"
        passwd "$USERNAME"
    else
        log_info "用户 $USERNAME 已存在"
    fi
    
    # 将用户添加到sudo组（sudo已在system_update阶段安装）
    usermod -aG sudo "$USERNAME"
    
    # 确保sudo组在sudoers中有权限
    if ! grep -q "^%sudo" /etc/sudoers; then
        echo "%sudo   ALL=(ALL:ALL) ALL" >> /etc/sudoers
    fi
    
    log_info "✓ 用户 $USERNAME 已添加到sudo组"
    log_info "  该用户现在可以使用sudo命令（需要重新登录）"
}

# 配置静态IP
config_static_ip() {
    if [[ "$INSTALL_STATIC_IP" != "true" ]]; then
        log_info "跳过静态IP配置"
        return
    fi
    
    log_info "配置静态IP..."
    
    # 获取网络接口名称
    local interface=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [[ -z "$interface" ]]; then
        log_error "未找到默认网络接口，请手动指定"
        return 1
    fi
    
    log_info "检测到网络接口: $interface"
    echo ""
    echo "请输入静态IP配置信息:"
    
    read -p "IP地址 (例如: 192.168.1.100): " static_ip
    read -p "子网掩码 (例如: 24 或 255.255.255.0): " netmask  
    read -p "网关地址 (例如: 192.168.1.1): " gateway
    read -p "DNS服务器 (例如: 8.8.8.8): " dns_server
    
    # 备份原始网络配置
    if [[ -f /etc/network/interfaces ]]; then
        cp /etc/network/interfaces /etc/network/interfaces.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 检查是否使用NetworkManager
    if systemctl is-active NetworkManager >/dev/null 2>&1; then
        log_info "检测到NetworkManager，将使用nmcli配置..."
        
        # 使用NetworkManager配置
        nmcli con mod "$interface" ipv4.addresses "$static_ip/$netmask"
        nmcli con mod "$interface" ipv4.gateway "$gateway"
        nmcli con mod "$interface" ipv4.dns "$dns_server"
        nmcli con mod "$interface" ipv4.method manual
        nmcli con up "$interface"
    else
        # 使用传统的/etc/network/interfaces配置
        log_info "使用传统网络配置方式..."
        
        cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto $interface
iface $interface inet static
    address $static_ip
    netmask $netmask
    gateway $gateway
    dns-nameservers $dns_server
EOF
    fi
    
    # 配置DNS
    echo "nameserver $dns_server" > /etc/resolv.conf
    
    log_info "✓ 静态IP配置完成"
    log_info "网络接口: $interface"
    log_info "IP地址: $static_ip"
    log_info "子网掩码: $netmask" 
    log_info "网关: $gateway"
    log_info "DNS: $dns_server"
    echo ""
    log_warn "请重启网络服务或重启系统使配置生效:"
    echo "systemctl restart networking 或者 reboot"
}

# 配置Chrony时间同步
config_chrony() {
    if [[ "$INSTALL_CHRONY" != "true" ]]; then
        log_info "跳过Chrony时间同步配置"
        return
    fi
    
    log_info "配置Chrony时间同步服务..."
    
    # 安装chrony
    apt update -y
    apt install -y chrony
    
    # 停止并禁用systemd-timesyncd
    systemctl stop systemd-timesyncd 2>/dev/null || true
    systemctl disable systemd-timesyncd 2>/dev/null || true
    
    # 备份原始配置文件
    if [[ -f /etc/chrony/chrony.conf ]]; then
        cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # 生成chrony.conf配置
    cat > /etc/chrony/chrony.conf << 'EOF'
# 使用中国的NTP服务器池
EOF
    
    # 添加配置的NTP服务器
    for server in "${NTP_SERVERS[@]}"; do
        echo "pool $server iburst" >> /etc/chrony/chrony.conf
    done
    
    cat >> /etc/chrony/chrony.conf << 'EOF'

# 备用国外NTP服务器
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst

# 记录系统时钟获得/丢失时间的速率
driftfile /var/lib/chrony/chrony.drift

# 允许系统时钟被大幅度调整
makestep 1 3

# 启用内核同步RTC
rtcsync

# 增加调度优先级
sched_priority 1

# 指定NTP客户端日志文件
logdir /var/log/chrony

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
        log_info "✓ Chronyd服务启动成功!"
        
        # 强制立即同步时间
        chrony makestep 2>/dev/null || true
        
        log_info "时间同步配置完成"
    else
        log_error "Chronyd服务启动失败，请检查配置"
        return 1
    fi
}

# 配置Docker
config_docker() {
    if [[ "$INSTALL_DOCKER" != "true" ]]; then
        log_info "跳过Docker安装"
        return
    fi
    
    log_info "安装和配置Docker..."
    
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
    
    # 创建Docker数据目录
    mkdir -p ${DOCKER_DATA_ROOT}
    
    # 配置Docker daemon
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << EOF
{
    "data-root": "${DOCKER_DATA_ROOT}",
    "debug": false,
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
EOF
    
    # 添加镜像源
    local first=true
    for mirror in "${DOCKER_REGISTRY_MIRRORS[@]}"; do
        if [[ "$first" == "true" ]]; then
            echo "        \"$mirror\"" >> /etc/docker/daemon.json
            first=false
        else
            echo "        ,\"$mirror\"" >> /etc/docker/daemon.json
        fi
    done
    
    cat >> /etc/docker/daemon.json << 'EOF'
    ]
}
EOF
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 验证Docker安装
    if docker --version > /dev/null 2>&1; then
        log_info "✓ Docker安装成功!"
        docker --version
        
        # 将用户添加到docker组
        if [[ -n "$USERNAME" ]]; then
            usermod -aG docker "$USERNAME"
            log_info "✓ 用户 $USERNAME 已添加到docker组"
            log_info "该用户重新登录后可以免sudo运行docker命令"
        fi
    else
        log_error "Docker安装失败，请检查错误信息"
        return 1
    fi
}

# 显示系统信息
show_system_info() {
    log_info "=== 系统初始化完成 ==="
    echo ""
    echo "系统信息："
    echo "  • 操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "  • 内核版本: $(uname -r)"
    echo "  • 时区: $(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone)"
    echo "  • 本地化: ${SYSTEM_LOCALE}"
    echo ""
    
    if [[ -n "$USERNAME" ]]; then
        echo "用户配置："
        echo "  • 已配置用户: $USERNAME"
        echo "  • sudo权限: 已启用"
        if [[ "$INSTALL_DOCKER" == "true" ]]; then
            echo "  • docker组成员: 是"
        fi
        echo ""
    fi
    
    echo "已安装的服务："
    if [[ "$INSTALL_CHRONY" == "true" ]]; then
        echo "  • Chrony时间同步: $(systemctl is-active chronyd 2>/dev/null || echo "未运行")"
    fi
    if [[ "$INSTALL_DOCKER" == "true" ]]; then
        echo "  • Docker: $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "安装失败")"
    fi
    echo ""
    
    log_info "建议执行以下命令完成配置："
    if [[ "$INSTALL_STATIC_IP" == "true" ]]; then
        echo "  • 重启网络服务: systemctl restart networking"
    fi
    if [[ -n "$USERNAME" ]]; then
        echo "  • 切换到配置的用户: su - $USERNAME"
    fi
    echo "  • 重启系统应用所有更改: reboot"
}

# 主函数
main() {
    echo ""
    log_info "=== Debian 13 (Trixie) 系统快捷初始化脚本 ==="
    echo ""
    
    # 检查系统
    check_root
    check_debian_version
    
    # 交互式配置
    interactive_config
    
    echo ""
    log_info "开始系统初始化..."
    echo ""
    
    # 执行初始化步骤
    system_update
    set_locale
    set_timezone
    config_vim
    config_bash
    config_user
    config_chrony
    config_static_ip
    config_docker
    
    echo ""
    show_system_info
    
    log_info "🎉 Debian 13 系统初始化完成!"
}

# 执行主函数
main "$@"
