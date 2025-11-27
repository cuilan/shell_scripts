#!/bin/bash

# Containerd 二进制安装脚本
# 作用：从GitHub下载并安装containerd和runc的二进制文件
# 使用方法：必须以root用户运行

#=============================================================================
# 配置区域 - 请根据实际环境修改以下变量
#=============================================================================

# 版本配置
CONTAINERD_VERSION="1.7.25"
RUNC_VERSION="1.2.6"

# 安装路径配置
INSTALL_PREFIX="/usr/local"
SYSTEMD_DIR="/etc/systemd/system"  # systemd服务文件目录

# 下载URL配置
CONTAINERD_RELEASE_URL="https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"
RUNC_RELEASE_URL="https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64"

# 临时目录（下载文件存放位置）
TMP_DIR="/tmp/containerd-install-$$"

# 是否自动启动服务
AUTO_START_SERVICE=true

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

# 清理函数
cleanup() {
    log_debug "清理临时文件..."
    if [[ -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
    # 清理当前目录的临时文件
    rm -f containerd-*.tar.gz runc.amd64 2>/dev/null || true
}

# 设置退出时清理
trap cleanup EXIT INT TERM

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须直接以root用户运行"
        log_info "请使用: su - 切换到root用户后执行"
        exit 1
    fi
    log_info "✓ 确认以root用户运行"
}

# 检查系统架构
check_architecture() {
    local arch=$(uname -m)
    log_info "检测系统架构: $arch"
    
    if [[ "$arch" != "x86_64" && "$arch" != "amd64" ]]; then
        log_error "此脚本目前仅支持 amd64/x86_64 架构"
        log_error "检测到的架构: $arch"
        exit 1
    fi
    log_info "✓ 系统架构检查通过"
}

# 检查必要的依赖
check_dependencies() {
    log_info "检查系统依赖..."
    
    local missing_deps=()
    
    # 检查必要的命令
    for cmd in curl tar systemctl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少必要的依赖: ${missing_deps[*]}"
        log_info "请先安装这些依赖，例如："
        log_info "  apt-get update && apt-get install -y curl tar systemd"
        exit 1
    fi
    
    log_info "✓ 系统依赖检查通过"
}

# 检查是否已安装
check_installed() {
    local already_installed=false
    
    if command -v containerd &> /dev/null; then
        local installed_version=$(containerd --version 2>/dev/null | head -n1 || echo "unknown")
        log_warn "检测到已安装的containerd: $installed_version"
        already_installed=true
    fi
    
    if command -v runc &> /dev/null; then
        local installed_version=$(runc --version 2>/dev/null | head -n1 || echo "unknown")
        log_warn "检测到已安装的runc: $installed_version"
        already_installed=true
    fi
    
    if [[ "$already_installed" == "true" ]]; then
        read -p "检测到已安装的containerd/runc，是否继续安装？(y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "已取消安装"
            exit 0
        fi
    fi
}

# 创建临时目录
create_temp_dir() {
    mkdir -p "$TMP_DIR"
    log_debug "创建临时目录: $TMP_DIR"
}

# 下载文件
download_file() {
    local url="$1"
    local output_file="$2"
    local description="$3"
    
    log_info "下载 $description..."
    log_debug "URL: $url"
    log_debug "输出文件: $output_file"
    
    if curl -fsSL -o "$output_file" "$url"; then
        log_info "✓ $description 下载成功"
        return 0
    else
        log_error "✗ $description 下载失败"
        return 1
    fi
}

# 验证下载的文件
verify_file() {
    local file="$1"
    local description="$2"
    
    if [[ ! -f "$file" ]]; then
        log_error "文件不存在: $file"
        return 1
    fi
    
    if [[ ! -s "$file" ]]; then
        log_error "文件为空: $file"
        return 1
    fi
    
    log_debug "✓ $description 文件验证通过"
    return 0
}

# 安装containerd
install_containerd() {
    log_info "开始安装 containerd v${CONTAINERD_VERSION}..."
    
    # 检查是否已安装
    if [[ -f "${INSTALL_PREFIX}/bin/containerd" ]]; then
        log_warn "containerd 已存在于 ${INSTALL_PREFIX}/bin/containerd"
        read -p "是否覆盖安装？(y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "跳过containerd安装"
            return 0
        fi
    fi
    
    # 下载containerd
    local containerd_tar="${TMP_DIR}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz"
    if ! download_file "$CONTAINERD_RELEASE_URL" "$containerd_tar" "containerd"; then
        return 1
    fi
    
    # 验证文件
    if ! verify_file "$containerd_tar" "containerd压缩包"; then
        return 1
    fi
    
    # 解压安装
    log_info "解压并安装containerd..."
    if tar -xzf "$containerd_tar" -C "$INSTALL_PREFIX" 2>/dev/null; then
        log_info "✓ containerd 安装成功"
        
        # 验证安装
        if [[ -f "${INSTALL_PREFIX}/bin/containerd" ]]; then
            local version=$("${INSTALL_PREFIX}/bin/containerd" --version 2>/dev/null | head -n1 || echo "unknown")
            log_info "  安装位置: ${INSTALL_PREFIX}/bin/containerd"
            log_info "  版本信息: $version"
        else
            log_warn "⚠ containerd二进制文件未找到，但解压成功"
        fi
    else
        log_error "✗ containerd 解压失败"
        return 1
    fi
}

# 配置systemd服务
systemd_containerd() {
    log_info "配置containerd systemd服务..."
    
    # 确保systemd目录存在
    mkdir -p "$SYSTEMD_DIR"
    
    # 备份已存在的服务文件
    if [[ -f "${SYSTEMD_DIR}/containerd.service" ]]; then
        local backup_file="${SYSTEMD_DIR}/containerd.service.backup.$(date +%Y%m%d_%H%M%S)"
        cp "${SYSTEMD_DIR}/containerd.service" "$backup_file"
        log_info "已备份现有服务文件: $backup_file"
    fi
    
    # 创建systemd服务文件
    log_info "创建systemd服务文件: ${SYSTEMD_DIR}/containerd.service"
    cat > "${SYSTEMD_DIR}/containerd.service" << EOF
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target dbus.service

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=${INSTALL_PREFIX}/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
    
    log_info "✓ systemd服务文件创建成功"
    
    # 重新加载systemd配置
    log_info "重新加载systemd配置..."
    systemctl daemon-reload
    
    # 启用服务
    log_info "启用containerd服务..."
    systemctl enable containerd.service
    
    # 根据配置决定是否启动服务
    if [[ "$AUTO_START_SERVICE" == "true" ]]; then
        log_info "启动containerd服务..."
        if systemctl start containerd.service; then
            log_info "✓ containerd服务启动成功"
            
            # 等待服务就绪
            sleep 2
            
            # 检查服务状态
            if systemctl is-active --quiet containerd.service; then
                log_info "✓ containerd服务运行正常"
            else
                log_warn "⚠ containerd服务未正常运行，请检查日志: journalctl -u containerd"
            fi
        else
            log_error "✗ containerd服务启动失败"
            log_info "请检查日志: journalctl -u containerd"
            return 1
        fi
    else
        log_info "服务已启用但未启动（AUTO_START_SERVICE=false）"
        log_info "手动启动: systemctl start containerd"
    fi
}

# 安装runc
install_runc() {
    log_info "开始安装 runc v${RUNC_VERSION}..."
    
    # 检查是否已安装
    if [[ -f "${INSTALL_PREFIX}/sbin/runc" ]]; then
        log_warn "runc 已存在于 ${INSTALL_PREFIX}/sbin/runc"
        read -p "是否覆盖安装？(y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "跳过runc安装"
            return 0
        fi
    fi
    
    # 下载runc
    local runc_binary="${TMP_DIR}/runc.amd64"
    if ! download_file "$RUNC_RELEASE_URL" "$runc_binary" "runc"; then
        return 1
    fi
    
    # 验证文件
    if ! verify_file "$runc_binary" "runc二进制文件"; then
        return 1
    fi
    
    # 安装runc
    log_info "安装runc到 ${INSTALL_PREFIX}/sbin/runc..."
    if install -m 755 "$runc_binary" "${INSTALL_PREFIX}/sbin/runc"; then
        log_info "✓ runc 安装成功"
        
        # 验证安装
        if [[ -f "${INSTALL_PREFIX}/sbin/runc" ]]; then
            local version=$("${INSTALL_PREFIX}/sbin/runc" --version 2>/dev/null | head -n1 || echo "unknown")
            log_info "  安装位置: ${INSTALL_PREFIX}/sbin/runc"
            log_info "  版本信息: $version"
        else
            log_warn "⚠ runc二进制文件未找到，但安装命令成功"
        fi
    else
        log_error "✗ runc 安装失败"
        return 1
    fi
}

# 验证安装
verify_installation() {
    log_info "验证安装结果..."
    
    local success=true
    
    # 检查containerd
    if command -v containerd &> /dev/null; then
        local version=$(containerd --version 2>/dev/null | head -n1)
        log_info "✓ containerd: $version"
    else
        log_error "✗ containerd 未找到"
        success=false
    fi
    
    # 检查runc
    if command -v runc &> /dev/null; then
        local version=$(runc --version 2>/dev/null | head -n1)
        log_info "✓ runc: $version"
    else
        log_error "✗ runc 未找到"
        success=false
    fi
    
    # 检查systemd服务
    if systemctl list-unit-files | grep -q containerd.service; then
        if systemctl is-enabled --quiet containerd.service 2>/dev/null; then
            log_info "✓ containerd服务: 已启用"
        else
            log_warn "⚠ containerd服务: 未启用"
        fi
        
        if systemctl is-active --quiet containerd.service 2>/dev/null; then
            log_info "✓ containerd服务: 运行中"
        else
            log_warn "⚠ containerd服务: 未运行"
        fi
    else
        log_error "✗ containerd服务文件未找到"
        success=false
    fi
    
    if [[ "$success" == "true" ]]; then
        echo ""
        log_info "🎉 Containerd 安装完成！"
        echo ""
        log_info "常用命令："
        echo "  • 查看服务状态: systemctl status containerd"
        echo "  • 查看日志: journalctl -u containerd -f"
        echo "  • 重启服务: systemctl restart containerd"
        echo "  • 查看版本: containerd --version && runc --version"
    else
        log_error "❌ 安装验证失败，请检查上述错误信息"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "Containerd 二进制安装脚本"
    echo ""
    echo "使用方法："
    echo "  $0 [选项]"
    echo ""
    echo "选项："
    echo "  install    安装containerd和runc（默认）"
    echo "  verify    验证安装结果"
    echo "  help      显示此帮助信息"
    echo ""
    echo "环境变量："
    echo "  DEBUG=1    启用调试输出"
    echo ""
    echo "配置说明："
    echo "  在脚本顶部的配置区域可以修改版本和路径等配置"
}

# 主函数
main() {
    local action="${1:-install}"
    
    echo ""
    log_info "=== Containerd 二进制安装脚本 ==="
    echo ""
    
    case "$action" in
        install)
            check_root
            check_architecture
            check_dependencies
            check_installed
            create_temp_dir
            install_containerd
            install_runc
            systemd_containerd
            verify_installation
            ;;
        verify)
            verify_installation
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知操作: $action"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"