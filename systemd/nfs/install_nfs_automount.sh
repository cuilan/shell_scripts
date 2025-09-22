#!/bin/bash

# NFS自动挂载systemd服务安装脚本
# 作用：自动配置和启用NFS自动挂载服务
# 使用方法：sudo ./install_nfs_automount.sh

set -e  # 遇到错误立即退出

# 颜色定义，用于美化输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

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

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检查systemd是否可用
check_systemd() {
    if ! command -v systemctl &> /dev/null; then
        log_error "systemctl命令未找到，请确认系统支持systemd"
        exit 1
    fi
    log_info "systemd检查通过"
}

# 检查NFS工具是否安装
check_nfs_tools() {
    if ! command -v mount.nfs &> /dev/null; then
        log_warn "NFS工具未安装，正在尝试安装..."
        
        # 根据不同发行版安装NFS工具
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y nfs-common
        elif command -v yum &> /dev/null; then
            yum install -y nfs-utils
        elif command -v dnf &> /dev/null; then
            dnf install -y nfs-utils
        else
            log_error "无法自动安装NFS工具，请手动安装"
            exit 1
        fi
        log_info "NFS工具安装完成"
    else
        log_info "NFS工具检查通过"
    fi
}

# 创建挂载目录
create_mount_point() {
    local mount_point="/mnt/nfs"
    
    if [[ ! -d "$mount_point" ]]; then
        log_info "创建挂载点目录: $mount_point"
        mkdir -p "$mount_point"
        chmod 755 "$mount_point"
    else
        log_info "挂载点目录已存在: $mount_point"
    fi
}

# 复制systemd单元文件
install_systemd_units() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local systemd_dir="/etc/systemd/system"
    
    # 复制.mount文件
    if [[ -f "$script_dir/mnt-nfs.mount" ]]; then
        log_info "安装mount单元文件..."
        cp "$script_dir/mnt-nfs.mount" "$systemd_dir/"
        chmod 644 "$systemd_dir/mnt-nfs.mount"
    else
        log_error "未找到mnt-nfs.mount文件"
        exit 1
    fi
    
    # 复制.automount文件
    if [[ -f "$script_dir/mnt-nfs.automount" ]]; then
        log_info "安装automount单元文件..."
        cp "$script_dir/mnt-nfs.automount" "$systemd_dir/"
        chmod 644 "$systemd_dir/mnt-nfs.automount"
    else
        log_error "未找到mnt-nfs.automount文件"
        exit 1
    fi
}

# 重新加载systemd配置
reload_systemd() {
    log_info "重新加载systemd配置..."
    systemctl daemon-reload
}

# 启用并启动服务
enable_service() {
    log_info "启用NFS自动挂载服务..."
    
    # 停用可能已启用的mount单元（automount会管理它）
    systemctl disable mnt-nfs.mount 2>/dev/null || true
    
    # 启用并启动automount单元
    systemctl enable mnt-nfs.automount
    systemctl start mnt-nfs.automount
    
    log_info "服务启用完成"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."
    
    if systemctl is-active --quiet mnt-nfs.automount; then
        log_info "✓ NFS自动挂载服务运行正常"
    else
        log_error "✗ NFS自动挂载服务未正常运行"
        return 1
    fi
    
    if systemctl is-enabled --quiet mnt-nfs.automount; then
        log_info "✓ NFS自动挂载服务已设置为开机启动"
    else
        log_warn "⚠ NFS自动挂载服务未设置开机启动"
    fi
    
    log_info "可以通过以下命令测试挂载："
    echo "  ls /mnt/nfs  # 首次访问会触发自动挂载"
}

# 主函数
main() {
    log_info "开始安装NFS自动挂载服务..."
    
    # 执行各个检查和安装步骤
    check_root
    check_systemd
    check_nfs_tools
    create_mount_point
    install_systemd_units
    reload_systemd
    enable_service
    verify_installation
    
    log_info "安装完成！"
    log_warn "注意：请根据实际情况修改 /etc/systemd/system/mnt-nfs.mount 中的NFS服务器地址"
}

# 执行主函数
main "$@"
