#!/bin/bash

# ================================================================================
# sudo vim /usr/lib/systemd/system/docker.service
# 添加 tcp 监听地址
# ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H fd:// --containerd=/run/containerd/containerd.sock
# sudo systemctl daemon-reload & sudo systemctl restart docker
# ================================================================================

# set -e: 如果任何命令返回非零退出状态，则立即退出。
# set -o pipefail: 如果管道中的任何命令失败，则整个管道的退出状态为失败。
set -e
set -o pipefail

# ---- 彩色输出定义 ----
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# ---- 默认配置 ----
# 如果提供了命令行参数，则使用它们；否则使用默认值。
REMOTE_HOST=${1:-"10.123.1.45"}
REMOTE_PORT=${2:-"2375"}
CONTEXT_NAME="${REMOTE_HOST}-docker"
DESCRIPTION="Docker on $REMOTE_HOST"
CONNECT_TIMEOUT=5 # 连接超时时间（秒）

# ---- 脚本开始 ----
echo -e "${YELLOW}🚀 开始配置远程 Docker 上下文...${NC}"
echo "------------------------------------"
echo "远程主机: $REMOTE_HOST"
echo "远程端口: $REMOTE_PORT"
echo "上下文名: $CONTEXT_NAME"
echo "------------------------------------"

# 1. 检查本地 Docker 命令是否可用
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ 错误: 'docker' 命令未找到。请先安装 Docker。${NC}"
    exit 1
fi

# 2. 检查远程 Docker 可用性
echo -e "🔍 正在检查远程 Docker (tcp://$REMOTE_HOST:$REMOTE_PORT) 的可用性..."

# 优先使用 nc (netcat) 进行快速端口检查
if command -v nc &> /dev/null; then
    if ! nc -z -w $CONNECT_TIMEOUT $REMOTE_HOST $REMOTE_PORT; then
        echo -e "${RED}❌ 错误: 无法连接到 $REMOTE_HOST 的 $REMOTE_PORT 端口。请检查：${NC}"
        echo "   1. 远程主机的 IP 和端口是否正确。"
        echo "   2. 防火墙规则是否允许访问。"
        echo "   3. 远程 Docker daemon 是否已配置为监听 TCP 套接字。"
        exit 1
    fi
else
    # 如果 nc 不可用，则回退到使用 docker version 命令检查
    echo -e "${YELLOW}ℹ️ 'nc' 命令未找到，将使用 'docker version' 进行检查 (可能稍慢)...${NC}"
    if ! docker --host "tcp://$REMOTE_HOST:$REMOTE_PORT" version --format '{{.Server.Version}}' &>/dev/null; then
        echo -e "${RED}❌ 错误: 无法从远程 Docker 获取响应。请检查权限或 Docker daemon 配置。${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✅ 远程 Docker 守护进程响应正常。${NC}"

# 3. 创建 Docker context
echo -e "🔧 正在处理 Docker context: $CONTEXT_NAME"
if docker context inspect "$CONTEXT_NAME" &>/dev/null; then
  echo -e "${YELLOW}ℹ️ 上下文 \"$CONTEXT_NAME\" 已存在，跳过创建。${NC}"
else
  docker context create "$CONTEXT_NAME" \
    --description "$DESCRIPTION" \
    --docker "host=tcp://$REMOTE_HOST:$REMOTE_PORT"
  # $? 会被 set -e 自动处理，如果创建失败脚本会在此处退出
  echo -e "${GREEN}✅ Docker 上下文 \"$CONTEXT_NAME\" 创建成功。${NC}"
fi

# 4. 切换 context
echo -e "🚀 正在切换至新上下文: $CONTEXT_NAME"
docker context use "$CONTEXT_NAME"
echo -e "${GREEN}✅ 已成功切换上下文。${NC}"

# 5. 测试连接
echo -e "📋 正在测试连接 (执行 docker ps)...${NC}"
docker ps

echo -e "\n${GREEN}🎉 配置完成！当前已连接到远程 Docker 上下文: $CONTEXT_NAME${NC}"
