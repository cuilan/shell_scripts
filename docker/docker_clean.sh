#!/bin/bash

# =================== 配置变量 ===================

# 要删除的 Docker 镜像仓库地址
REGISTRY_URL="reg.weattech.com"

# ===============================================
# 以下为清理脚本

echo "=========================================="
echo "开始执行 Docker 清理脚本"
echo "=========================================="
echo ""

# 查找所有状态为"Exited"（已退出）的容器，提取容器ID，并停止这些容器
echo "[1/5] 正在停止已退出的容器..."
EXITED_CONTAINERS=$(docker ps -a | grep "Exited" | awk '{print $1}')
if [ -z "$EXITED_CONTAINERS" ]; then
    echo "  没有找到已退出的容器"
else
    echo "$EXITED_CONTAINERS" | xargs docker stop 2>/dev/null
    echo "  已停止已退出的容器"
fi
echo ""

# 查找所有状态为"Exited"（已退出）的容器，提取容器ID，并删除这些容器
echo "[2/5] 正在删除已退出的容器..."
if [ -z "$EXITED_CONTAINERS" ]; then
    echo "  没有需要删除的容器"
else
    echo "$EXITED_CONTAINERS" | xargs docker rm 2>/dev/null
    echo "  已删除已退出的容器"
fi
echo ""

# 查找所有标签为"none"的镜像（悬空镜像），排除表头行，提取镜像ID，并删除这些镜像
echo "[3/5] 正在删除标签为'none'的悬空镜像..."
NONE_IMAGES=$(docker images | grep none | grep -v REPOSITORY | awk '{print $3}')
if [ -z "$NONE_IMAGES" ]; then
    echo "  没有找到悬空镜像"
else
    echo "$NONE_IMAGES" | xargs docker rmi 2>/dev/null
    echo "  已删除悬空镜像"
fi
echo ""

# 查找所有来自指定仓库的镜像，提取镜像ID，并删除这些镜像
echo "[4/5] 正在删除来自'${REGISTRY_URL}'仓库的镜像..."
REG_IMAGES=$(docker images | grep "${REGISTRY_URL}" | awk '{print $3}')
if [ -z "$REG_IMAGES" ]; then
    echo "  没有找到该仓库的镜像"
else
    echo "$REG_IMAGES" | xargs docker rmi 2>/dev/null
    echo "  已删除该仓库的镜像"
fi
echo ""

# 删除所有未使用的镜像（包括悬空镜像和有标签但未被使用的镜像），-a表示所有未使用的镜像，-f表示强制删除不提示确认
echo "[5/5] 正在清理所有未使用的镜像..."
docker image prune -a -f
echo "  未使用的镜像清理完成"
echo ""

echo "=========================================="
echo "Docker 清理脚本执行完成"
echo "=========================================="
