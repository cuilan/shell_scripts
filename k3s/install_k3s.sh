#!/bin/bash

# K3s 自动化安装脚本
# 作用：自动安装和配置K3s（轻量级Kubernetes）
# 使用方法：必须以root用户运行

#=============================================================================
# 配置区域 - 请根据实际环境修改以下变量
#=============================================================================

# K3s版本配置
K3S_VERSION="latest"  # 可选: latest, v1.28.0, v1.27.0 等

# 安装模式配置
INSTALL_MODE="server"  # server: 控制平面节点, agent: 工作节点

# 单节点模式（server模式下的简化安装）
SINGLE_NODE_MODE=true  # true: 单节点模式, false: 集群模式

# 集群配置（仅在集群模式下使用）
K3S_TOKEN=""           # 集群token（从第一个server节点获取）
K3S_URL=""              # 第一个server节点的URL，格式: https://server-ip:6443

# 网络配置
K3S_NODE_IP=""          # 节点IP地址（留空自动检测）
K3S_NODE_EXTERNAL_IP=""  # 节点外部IP地址（用于集群通信）

# 数据目录配置
K3S_DATA_DIR="/var/lib/rancher/k3s"  # K3s数据目录

# 安装选项
INSTALL_OPTIONS=(
    "--write-kubeconfig-mode=644"    # kubeconfig文件权限
    "--tls-san=localhost"             # TLS SAN（可添加多个IP或域名）
)

# 如果单节点模式，添加禁用组件选项
if [[ "$SINGLE_NODE_MODE" == "true" && "$INSTALL_MODE" == "server" ]]; then
    INSTALL_OPTIONS+=(
        "--disable=traefik"           # 禁用Traefik（可选）
        # "--disable=servicelb"       # 禁用ServiceLB（可选）
        # "--disable=local-storage"    # 禁用local-storage（可选）
    )
fi

# 镜像仓库配置（可选，用于国内加速）
# INSTALL_OPTIONS+=("--system-default-registry=registry.cn-hangzhou.aliyuncs.com")

# 环境变量配置
export INSTALL_K3S_VERSION="${K3S_VERSION}"
export K3S_DATA_DIR="${K3S_DATA_DIR}"

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

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本必须直接以root用户运行"
        log_info "请使用: su - 切换到root用户后执行"
        exit 1
    fi
    log_info "✓ 确认以root用户运行"
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    # 检查操作系统
    if [[ ! -f /etc/os-release ]]; then
        log_error "无法检测操作系统"
        return 1
    fi
    
    local os_name=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    log_info "检测到操作系统: $os_name"
    
    # 检查内核版本（K3s需要Linux内核）
    if [[ "$(uname -s)" != "Linux" ]]; then
        log_error "K3s仅支持Linux系统"
        exit 1
    fi
    
    local kernel_version=$(uname -r)
    log_info "内核版本: $kernel_version"
    
    # 检查必要的依赖
    local missing_deps=()
    
    for cmd in curl; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少必要的依赖: ${missing_deps[*]}"
        log_info "请先安装这些依赖，例如："
        log_info "  apt-get update && apt-get install -y curl"
        exit 1
    fi
    
    # 检查端口是否被占用（6443是K3s API server端口）
    if [[ "$INSTALL_MODE" == "server" ]]; then
        if command -v netstat &> /dev/null; then
            if netstat -tuln | grep -q ":6443 "; then
                log_warn "端口6443已被占用，K3s可能无法正常启动"
                read -p "是否继续？(y/N): " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 0
                fi
            fi
        fi
    fi
    
    log_info "✓ 系统要求检查通过"
}

# 检查是否已安装K3s
check_existing_installation() {
    if command -v k3s &> /dev/null || [[ -f /usr/local/bin/k3s ]]; then
        log_warn "检测到已安装的K3s"
        
        if systemctl is-active --quiet k3s 2>/dev/null || systemctl is-active --quiet k3s-agent 2>/dev/null; then
            log_warn "K3s服务正在运行"
        fi
        
        read -p "是否卸载现有安装并重新安装？(y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "卸载现有K3s安装..."
            uninstall_k3s
        else
            log_info "已取消安装"
            exit 0
        fi
    fi
}

# 卸载K3s
uninstall_k3s() {
    log_info "开始卸载K3s..."
    
    # 停止服务
    if systemctl is-active --quiet k3s 2>/dev/null; then
        log_info "停止k3s服务..."
        systemctl stop k3s
    fi
    
    if systemctl is-active --quiet k3s-agent 2>/dev/null; then
        log_info "停止k3s-agent服务..."
        systemctl stop k3s-agent
    fi
    
    # 禁用服务
    systemctl disable k3s 2>/dev/null || true
    systemctl disable k3s-agent 2>/dev/null || true
    
    # 运行官方卸载脚本
    if [[ -f /usr/local/bin/k3s-killall.sh ]]; then
        log_info "运行k3s-killall.sh..."
        /usr/local/bin/k3s-killall.sh
    fi
    
    if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
        log_info "运行k3s-uninstall.sh..."
        /usr/local/bin/k3s-uninstall.sh
    fi
    
    # 清理残留文件
    log_info "清理残留文件..."
    rm -f /usr/local/bin/k3s* 2>/dev/null || true
    rm -rf /etc/systemd/system/k3s* 2>/dev/null || true
    systemctl daemon-reload
    
    log_info "✓ K3s卸载完成"
}

# 获取节点IP地址
get_node_ip() {
    if [[ -n "$K3S_NODE_IP" ]]; then
        echo "$K3S_NODE_IP"
        return
    fi
    
    # 自动检测IP地址
    local ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}' | head -n1)
    
    if [[ -z "$ip" ]]; then
        # 备用方法
        ip=$(hostname -I | awk '{print $1}')
    fi
    
    if [[ -z "$ip" ]]; then
        log_error "无法自动检测节点IP地址"
        log_info "请手动设置 K3S_NODE_IP 变量"
        exit 1
    fi
    
    echo "$ip"
}

# 构建安装选项
build_install_options() {
    local options=("${INSTALL_OPTIONS[@]}")
    
    # 添加节点IP
    local node_ip=$(get_node_ip)
    if [[ -n "$node_ip" ]]; then
        options+=("--node-ip=$node_ip")
    fi
    
    # 添加外部IP（如果指定）
    if [[ -n "$K3S_NODE_EXTERNAL_IP" ]]; then
        options+=("--node-external-ip=$K3S_NODE_EXTERNAL_IP")
    fi
    
    # 添加TLS SAN（包含节点IP）
    if [[ -n "$node_ip" ]]; then
        options+=("--tls-san=$node_ip")
    fi
    
    # Agent模式需要token和URL
    if [[ "$INSTALL_MODE" == "agent" ]]; then
        if [[ -z "$K3S_TOKEN" ]]; then
            log_error "Agent模式需要设置K3S_TOKEN"
            log_info "请从第一个server节点获取token: cat /var/lib/rancher/k3s/server/node-token"
            exit 1
        fi
        
        if [[ -z "$K3S_URL" ]]; then
            log_error "Agent模式需要设置K3S_URL"
            log_info "格式: https://server-ip:6443"
            exit 1
        fi
        
        export K3S_TOKEN="${K3S_TOKEN}"
        export K3S_URL="${K3S_URL}"
    fi
    
    # 输出选项（用于调试）
    log_debug "安装选项: ${options[*]}"
    
    # 返回选项数组（通过全局变量）
    INSTALL_OPTIONS_FINAL=("${options[@]}")
}

# 安装K3s Server
install_k3s_server() {
    log_info "开始安装K3s Server..."
    
    # 构建安装选项
    build_install_options
    
    # 下载并安装K3s
    log_info "下载K3s安装脚本..."
    local install_script_url="https://get.k3s.io"
    
    if curl -sfSL "$install_script_url" | INSTALL_K3S_VERSION="${K3S_VERSION}" sh -s - server "${INSTALL_OPTIONS_FINAL[@]}"; then
        log_info "✓ K3s Server 安装成功"
    else
        log_error "✗ K3s Server 安装失败"
        return 1
    fi
    
    # 等待服务启动
    log_info "等待K3s服务启动..."
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet k3s; then
        log_info "✓ K3s服务运行正常"
    else
        log_warn "⚠ K3s服务未正常运行"
        log_info "请检查日志: journalctl -u k3s -f"
        return 1
    fi
}

# 安装K3s Agent
install_k3s_agent() {
    log_info "开始安装K3s Agent..."
    
    # 构建安装选项
    build_install_options
    
    # 下载并安装K3s Agent
    log_info "下载K3s安装脚本..."
    local install_script_url="https://get.k3s.io"
    
    if curl -sfSL "$install_script_url" | INSTALL_K3S_VERSION="${K3S_VERSION}" K3S_TOKEN="${K3S_TOKEN}" K3S_URL="${K3S_URL}" sh -s - agent "${INSTALL_OPTIONS_FINAL[@]}"; then
        log_info "✓ K3s Agent 安装成功"
    else
        log_error "✗ K3s Agent 安装失败"
        return 1
    fi
    
    # 等待服务启动
    log_info "等待K3s Agent服务启动..."
    sleep 5
    
    # 检查服务状态
    if systemctl is-active --quiet k3s-agent; then
        log_info "✓ K3s Agent服务运行正常"
    else
        log_warn "⚠ K3s Agent服务未正常运行"
        log_info "请检查日志: journalctl -u k3s-agent -f"
        return 1
    fi
}

# 配置kubectl
configure_kubectl() {
    if [[ "$INSTALL_MODE" != "server" ]]; then
        return 0
    fi
    
    log_info "配置kubectl..."
    
    # 检查kubectl是否可用
    if command -v kubectl &> /dev/null; then
        log_info "✓ kubectl已可用"
        return 0
    fi
    
    # 创建kubectl符号链接或别名
    local k3s_kubectl="/usr/local/bin/k3s kubectl"
    if [[ -f /usr/local/bin/k3s ]]; then
        # 创建kubectl别名脚本
        cat > /usr/local/bin/kubectl << 'EOF'
#!/bin/bash
/usr/local/bin/k3s kubectl "$@"
EOF
        chmod +x /usr/local/bin/kubectl
        log_info "✓ kubectl已配置（通过k3s）"
    else
        log_warn "⚠ 无法配置kubectl，k3s二进制文件未找到"
    fi
}

# 显示集群信息
show_cluster_info() {
    if [[ "$INSTALL_MODE" != "server" ]]; then
        return 0
    fi
    
    log_info "=== K3s集群信息 ==="
    echo ""
    
    # 显示节点信息
    if command -v kubectl &> /dev/null; then
        log_info "节点列表："
        kubectl get nodes 2>/dev/null || log_warn "无法获取节点信息（可能服务未完全启动）"
        echo ""
    fi
    
    # 显示服务状态
    log_info "服务状态："
    systemctl status k3s --no-pager -l 2>/dev/null | head -n 10 || true
    echo ""
    
    # 显示重要文件位置
    log_info "重要文件位置："
    echo "  • K3s配置文件: /etc/rancher/k3s/k3s.yaml"
    echo "  • K3s数据目录: ${K3S_DATA_DIR}"
    echo "  • K3s日志: journalctl -u k3s -f"
    echo ""
    
    # 显示集群token（用于添加节点）
    if [[ -f "${K3S_DATA_DIR}/server/node-token" ]]; then
        log_info "集群Token（用于添加Agent节点）："
        echo "  $(cat ${K3S_DATA_DIR}/server/node-token)"
        echo ""
        log_info "添加Agent节点时使用："
        echo "  export K3S_TOKEN=\"$(cat ${K3S_DATA_DIR}/server/node-token)\""
        echo "  export K3S_URL=\"https://$(get_node_ip):6443\""
    fi
    echo ""
}

# 验证安装
verify_installation() {
    log_info "验证K3s安装..."
    
    local success=true
    
    # 检查k3s二进制文件
    if [[ -f /usr/local/bin/k3s ]]; then
        local version=$(/usr/local/bin/k3s --version 2>/dev/null | head -n1 || echo "unknown")
        log_info "✓ K3s二进制文件: $version"
    else
        log_error "✗ K3s二进制文件未找到"
        success=false
    fi
    
    # 检查服务状态
    if [[ "$INSTALL_MODE" == "server" ]]; then
        if systemctl is-active --quiet k3s 2>/dev/null; then
            log_info "✓ k3s服务: 运行中"
        else
            log_error "✗ k3s服务: 未运行"
            success=false
        fi
        
        if systemctl is-enabled --quiet k3s 2>/dev/null; then
            log_info "✓ k3s服务: 已启用"
        else
            log_warn "⚠ k3s服务: 未启用"
        fi
    else
        if systemctl is-active --quiet k3s-agent 2>/dev/null; then
            log_info "✓ k3s-agent服务: 运行中"
        else
            log_error "✗ k3s-agent服务: 未运行"
            success=false
        fi
        
        if systemctl is-enabled --quiet k3s-agent 2>/dev/null; then
            log_info "✓ k3s-agent服务: 已启用"
        else
            log_warn "⚠ k3s-agent服务: 未启用"
        fi
    fi
    
    # 检查kubectl（仅server模式）
    if [[ "$INSTALL_MODE" == "server" ]]; then
        if command -v kubectl &> /dev/null; then
            log_info "✓ kubectl: 可用"
        else
            log_warn "⚠ kubectl: 不可用（可能需要手动配置）"
        fi
    fi
    
    if [[ "$success" == "true" ]]; then
        echo ""
        log_info "🎉 K3s安装完成！"
        echo ""
        log_info "常用命令："
        if [[ "$INSTALL_MODE" == "server" ]]; then
            echo "  • 查看节点: kubectl get nodes"
            echo "  • 查看Pod: kubectl get pods -A"
            echo "  • 查看服务状态: systemctl status k3s"
            echo "  • 查看日志: journalctl -u k3s -f"
            echo "  • 获取kubeconfig: cat /etc/rancher/k3s/k3s.yaml"
        else
            echo "  • 查看服务状态: systemctl status k3s-agent"
            echo "  • 查看日志: journalctl -u k3s-agent -f"
        fi
    else
        log_error "❌ 安装验证失败，请检查上述错误信息"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    echo "K3s 自动化安装脚本"
    echo ""
    echo "使用方法："
    echo "  $0 [选项]"
    echo ""
    echo "选项："
    echo "  install     安装K3s（默认）"
    echo "  uninstall  卸载K3s"
    echo "  status     查看K3s状态"
    echo "  info       显示集群信息"
    echo "  help       显示此帮助信息"
    echo ""
    echo "配置说明："
    echo "  在脚本顶部的配置区域可以修改："
    echo "  • K3S_VERSION      - K3s版本（latest或具体版本号）"
    echo "  • INSTALL_MODE    - 安装模式（server/agent）"
    echo "  • SINGLE_NODE_MODE - 单节点模式（true/false）"
    echo "  • K3S_TOKEN       - 集群token（agent模式必需）"
    echo "  • K3S_URL         - Server URL（agent模式必需）"
    echo ""
    echo "环境变量："
    echo "  DEBUG=1           启用调试输出"
    echo ""
    echo "示例："
    echo "  # 安装单节点K3s Server"
    echo "  ./install_k3s.sh"
    echo ""
    echo "  # 安装K3s Agent（需要先配置K3S_TOKEN和K3S_URL）"
    echo "  INSTALL_MODE=agent K3S_TOKEN=xxx K3S_URL=https://server:6443 ./install_k3s.sh"
}

# 显示状态
show_status() {
    log_info "=== K3s服务状态 ==="
    echo ""
    
    if systemctl list-unit-files | grep -q k3s; then
        systemctl status k3s --no-pager -l 2>/dev/null || true
    fi
    
    if systemctl list-unit-files | grep -q k3s-agent; then
        systemctl status k3s-agent --no-pager -l 2>/dev/null || true
    fi
    
    echo ""
    log_info "=== 节点信息 ==="
    if command -v kubectl &> /dev/null; then
        kubectl get nodes 2>/dev/null || log_warn "无法获取节点信息"
    else
        log_warn "kubectl不可用"
    fi
}

# 主函数
main() {
    local action="${1:-install}"
    
    echo ""
    log_info "=== K3s 自动化安装脚本 ==="
    echo ""
    
    case "$action" in
        install)
            check_root
            check_system_requirements
            check_existing_installation
            
            if [[ "$INSTALL_MODE" == "server" ]]; then
                install_k3s_server
                configure_kubectl
            else
                install_k3s_agent
            fi
            
            verify_installation
            show_cluster_info
            ;;
        uninstall)
            check_root
            uninstall_k3s
            ;;
        status)
            show_status
            ;;
        info)
            show_cluster_info
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