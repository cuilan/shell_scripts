#!/bin/bash

# NFS自动挂载systemd服务卸载脚本
# 作用：完全移除NFS自动挂载服务和相关配置
# 使用方法：sudo ./uninstall_nfs_automount.sh

set -e  # 遇到错误立即退出

# 颜色定义，用于美化输出
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

log_question() {
    echo -e "${BLUE}[QUESTION]${NC} $1"
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

# 询问用户确认
confirm_removal() {
    log_warn "此操作将完全移除NFS自动挂载服务，包括："
    echo "  • 停止并禁用systemd服务"
    echo "  • 删除systemd单元文件"
    echo "  • 卸载当前挂载的NFS"
    echo "  • 可选：删除挂载点目录"
    echo ""
    
    read -p "$(log_question '确定要继续吗？(y/N): ')" -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
}

# 停止并禁用systemd服务
stop_services() {
    local services=("mnt-nfs.automount" "mnt-nfs.mount")
    
    for service in "${services[@]}"; do
        log_info "处理服务: $service"
        
        # 检查服务是否存在
        if systemctl list-unit-files "$service" &>/dev/null; then
            # 停止服务
            if systemctl is-active --quiet "$service"; then
                log_info "停止服务: $service"
                systemctl stop "$service" || log_warn "停止服务 $service 时出现问题"
            else
                log_info "服务 $service 已经停止"
            fi
            
            # 禁用服务
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                log_info "禁用服务: $service"
                systemctl disable "$service" || log_warn "禁用服务 $service 时出现问题"
            else
                log_info "服务 $service 已经禁用或未启用"
            fi
        else
            log_info "服务 $service 不存在，跳过"
        fi
    done
}

# 强制卸载NFS挂载
force_unmount() {
    local mount_point="/mnt/nfs"
    
    log_info "检查NFS挂载状态..."
    
    # 检查是否已挂载
    if mount | grep -q "$mount_point"; then
        log_info "发现活动的NFS挂载，正在卸载..."
        
        # 尝试正常卸载
        if umount "$mount_point" 2>/dev/null; then
            log_info "✓ NFS挂载已正常卸载"
        else
            log_warn "正常卸载失败，尝试强制卸载..."
            
            # 强制卸载
            if umount -f "$mount_point" 2>/dev/null; then
                log_info "✓ NFS挂载已强制卸载"
            else
                log_warn "强制卸载失败，尝试懒卸载..."
                
                # 懒卸载
                if umount -l "$mount_point" 2>/dev/null; then
                    log_info "✓ NFS挂载已懒卸载"
                else
                    log_error "所有卸载方式都失败，请手动处理挂载点: $mount_point"
                fi
            fi
        fi
    else
        log_info "未发现活动的NFS挂载"
    fi
}

# 删除systemd单元文件
remove_systemd_units() {
    local systemd_dir="/etc/systemd/system"
    local units=("mnt-nfs.mount" "mnt-nfs.automount")
    
    for unit in "${units[@]}"; do
        local unit_path="$systemd_dir/$unit"
        
        if [[ -f "$unit_path" ]]; then
            log_info "删除单元文件: $unit_path"
            rm -f "$unit_path"
        else
            log_info "单元文件不存在: $unit_path"
        fi
    done
}

# 询问是否删除挂载点目录
remove_mount_point() {
    local mount_point="/mnt/nfs"
    
    if [[ -d "$mount_point" ]]; then
        echo ""
        read -p "$(log_question '是否删除挂载点目录 /mnt/nfs？(y/N): ')" -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 检查目录是否为空
            if [[ -z "$(ls -A "$mount_point" 2>/dev/null)" ]]; then
                log_info "删除挂载点目录: $mount_point"
                rmdir "$mount_point"
            else
                log_warn "挂载点目录不为空，是否强制删除？"
                read -p "$(log_question '强制删除 /mnt/nfs 及其内容？(y/N): ')" -n 1 -r
                echo ""
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "强制删除挂载点目录及内容: $mount_point"
                    rm -rf "$mount_point"
                else
                    log_info "保留挂载点目录: $mount_point"
                fi
            fi
        else
            log_info "保留挂载点目录: $mount_point"
        fi
    else
        log_info "挂载点目录不存在: $mount_point"
    fi
}

# 重新加载systemd配置
reload_systemd() {
    log_info "重新加载systemd配置..."
    systemctl daemon-reload
}

# 清理相关进程（如果有的话）
cleanup_processes() {
    log_info "检查相关进程..."
    
    # 查找可能的NFS相关进程
    local nfs_procs
    nfs_procs=$(ps aux | grep -E "(mount\.nfs|nfs)" | grep -v grep | awk '{print $2}' || true)
    
    if [[ -n "$nfs_procs" ]]; then
        log_warn "发现NFS相关进程，这是正常的系统进程"
        echo "$nfs_procs" | while read -r pid; do
            if [[ -n "$pid" ]]; then
                log_info "NFS相关进程 PID: $pid"
            fi
        done
    else
        log_info "未发现异常的NFS相关进程"
    fi
}

# 验证卸载结果
verify_removal() {
    log_info "验证卸载结果..."
    
    local success=true
    
    # 检查服务状态
    for service in "mnt-nfs.automount" "mnt-nfs.mount"; do
        if systemctl list-unit-files "$service" &>/dev/null; then
            log_error "✗ 服务文件仍然存在: $service"
            success=false
        else
            log_info "✓ 服务文件已删除: $service"
        fi
    done
    
    # 检查挂载状态
    if mount | grep -q "/mnt/nfs"; then
        log_error "✗ NFS仍然处于挂载状态"
        success=false
    else
        log_info "✓ NFS挂载已清除"
    fi
    
    # 检查单元文件
    for unit in "mnt-nfs.mount" "mnt-nfs.automount"; do
        if [[ -f "/etc/systemd/system/$unit" ]]; then
            log_error "✗ 单元文件仍然存在: /etc/systemd/system/$unit"
            success=false
        else
            log_info "✓ 单元文件已删除: $unit"
        fi
    done
    
    if [[ "$success" == "true" ]]; then
        log_info "✓ 卸载验证通过"
        return 0
    else
        log_error "卸载验证失败，请检查上述问题"
        return 1
    fi
}

# 显示清理后的状态
show_final_status() {
    echo ""
    log_info "=== 系统状态 ==="
    
    # 显示相关服务状态
    echo "NFS相关服务状态："
    systemctl list-units --type=mount --state=active | grep nfs || echo "  (无活动的NFS挂载服务)"
    
    # 显示挂载状态
    echo ""
    echo "当前挂载状态："
    mount -t nfs,nfs4 2>/dev/null || echo "  (无NFS挂载)"
    
    echo ""
}

# 主函数
main() {
    log_info "开始卸载NFS自动挂载服务..."
    
    # 执行各个卸载步骤
    check_root
    check_systemd
    confirm_removal
    
    echo ""
    log_info "正在执行卸载操作..."
    
    stop_services
    force_unmount
    remove_systemd_units
    reload_systemd
    cleanup_processes
    
    # 询问是否删除挂载点
    remove_mount_point
    
    echo ""
    log_info "验证卸载结果..."
    
    if verify_removal; then
        echo ""
        log_info "✅ NFS自动挂载服务卸载完成！"
        
        # 显示最终状态
        show_final_status
        
        log_info "如需重新安装，请运行 ./install_nfs_automount.sh"
    else
        echo ""
        log_error "❌ 卸载过程中出现问题，请检查上述错误信息"
        exit 1
    fi
}

# 执行主函数
main "$@"
