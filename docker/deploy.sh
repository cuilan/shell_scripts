#!/bin/bash
# 快速部署脚本 - 类似 kubectl set image

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示使用说明
show_usage() {
    echo "用法: $0 -d <directory-path> -i <image-name> [-c <container-name>]"
    echo ""
    echo "参数说明:"
    echo "  -d, --directory <path>  服务目录路径（必需，支持相对路径和绝对路径）"
    echo "  -i, --image <name>      完整镜像名称（必需，格式：registry/image:tag）"
    echo "  -c, --container <name>  容器名称（可选，当 docker-compose.yaml 中有多个容器时使用）"
    echo "                          可以多次使用 -c 参数指定多个容器"
    echo "  -h, --help              显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -d myproject -i nginx:latest"
    echo "  $0 -d ./myproject -i nginx:latest -c nginx"
    echo "  $0 -d /home/user/myproject -i ghcr.io/user/image:v1.0.0 -c nginx -c redis"
    echo "  $0 -d /home/user/myproject -i harbor.example.com/service:dev-abc123 -c test-service"
    echo ""
    echo "说明:"
    echo "  - 部署历史会记录在目录下的 .deploy_history 文件中"
    echo "  - 脚本会自动检测并使用可用的 docker-compose 命令（docker compose > docker-compose）"
    echo ""
}

# 解析命令行参数
SERVICE_DIR=""
IMAGE_NAME=""
CONTAINERS=()

# 检查 --help 参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_usage
    exit 0
fi

while getopts "d:i:c:h" opt; do
    case $opt in
        d)
            SERVICE_DIR="$OPTARG"
            ;;
        i)
            IMAGE_NAME="$OPTARG"
            ;;
        c)
            CONTAINERS+=("$OPTARG")
            ;;
        h)
            show_usage
            exit 0
            ;;
        \?)
            show_usage
            exit 1
            ;;
    esac
done

# 验证必需参数（缺少参数时直接显示帮助信息）
if [ -z "$SERVICE_DIR" ] || [ -z "$IMAGE_NAME" ]; then
    show_usage
    exit 1
fi

# 处理目录路径（支持相对路径和绝对路径）
if [[ "$SERVICE_DIR" = /* ]]; then
    # 绝对路径
    SERVICE_DIR="$SERVICE_DIR"
else
    # 相对路径，相对于脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SERVICE_DIR="${SCRIPT_DIR}/${SERVICE_DIR}"
fi

# 转换为绝对路径
SERVICE_DIR="$(cd "$SERVICE_DIR" 2>/dev/null && pwd || echo "$SERVICE_DIR")"

# 检查服务目录是否存在
if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}错误: 服务目录不存在: ${SERVICE_DIR}${NC}"
    exit 1
fi

COMPOSE_FILE="${SERVICE_DIR}/docker-compose.yaml"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo -e "${RED}错误: docker-compose.yaml 文件不存在: ${COMPOSE_FILE}${NC}"
    exit 1
fi

# 获取 docker-compose.yaml 中的所有容器名称（container_name）
ALL_CONTAINERS=$(grep -E "^\s+container_name:" "$COMPOSE_FILE" | sed 's/.*container_name:[[:space:]]*//' | tr -d "\"'" | sed 's/[[:space:]]*$//')

# 如果没有指定容器，检查是否有多个容器
if [ ${#CONTAINERS[@]} -eq 0 ]; then
    CONTAINER_COUNT=$(echo "$ALL_CONTAINERS" | grep -v '^$' | wc -l | tr -d ' ')
    if [ "$CONTAINER_COUNT" -eq 0 ]; then
        echo -e "${RED}错误: 未找到任何 container_name 配置${NC}"
        exit 1
    elif [ "$CONTAINER_COUNT" -gt 1 ]; then
        echo -e "${YELLOW}警告: docker-compose.yaml 中包含多个容器，请使用 -c 参数指定要更新的容器${NC}"
        echo ""
        echo "可用的容器名称:"
        echo "$ALL_CONTAINERS" | grep -v '^$' | sed 's/^/  - /'
        echo ""
        echo "示例: $0 -d $SERVICE_DIR -i $IMAGE_NAME -c <container-name>"
        exit 1
    else
        # 只有一个容器，自动使用该容器名
        CONTAINERS=("$(echo "$ALL_CONTAINERS" | grep -v '^$' | head -1)")
    fi
fi

# 创建部署历史文件路径（隐藏文件）
DEPLOY_HISTORY="${SERVICE_DIR}/.deploy_history"

# 初始化部署历史文件（如果不存在）
if [ ! -f "$DEPLOY_HISTORY" ]; then
    touch "$DEPLOY_HISTORY"
fi

# 更新每个指定容器的镜像标签
for CONTAINER_NAME in "${CONTAINERS[@]}"; do
    # 检查容器名称是否存在
    if ! echo "$ALL_CONTAINERS" | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${RED}错误: 容器名称 '${CONTAINER_NAME}' 不存在于 docker-compose.yaml 中${NC}"
        echo "可用的容器名称:"
        echo "$ALL_CONTAINERS" | grep -v '^$' | sed 's/^/  - /'
        exit 1
    fi
    
    # 找到包含该 container_name 的服务配置块
    # 先找到 container_name 所在的行
    CONTAINER_NAME_LINE=$(grep -n "container_name:[[:space:]]*${CONTAINER_NAME}" "$COMPOSE_FILE" | head -1 | cut -d: -f1)
    if [ -z "$CONTAINER_NAME_LINE" ]; then
        echo -e "${RED}错误: 无法找到容器 '${CONTAINER_NAME}' 的 container_name 配置${NC}"
        exit 1
    fi
    
    # 向上查找服务名称（缩进为 2 个空格的行）
    SERVICE_START=1
    for ((i=$CONTAINER_NAME_LINE; i>=1; i--)); do
        LINE=$(sed -n "${i}p" "$COMPOSE_FILE")
        if [[ "$LINE" =~ ^[[:space:]]{2}[a-zA-Z0-9_-]+:[[:space:]]*$ ]]; then
            SERVICE_START=$i
            break
        fi
    done
    
    # 找到下一个服务或顶级键的开始行号（作为结束位置）
    TOTAL_LINES=$(wc -l < "$COMPOSE_FILE")
    SERVICE_END=$TOTAL_LINES
    NEXT_SERVICE=$(sed -n "$((SERVICE_START+1)),$" "$COMPOSE_FILE" | grep -n "^[[:space:]]\{0,2\}[a-zA-Z0-9_-]*:" | head -1 | cut -d: -f1)
    if [ -n "$NEXT_SERVICE" ]; then
        SERVICE_END=$((SERVICE_START + NEXT_SERVICE - 1))
    fi
    
    # 在服务配置块中查找 image 行
    IMAGE_LINE=$(sed -n "${SERVICE_START},${SERVICE_END}p" "$COMPOSE_FILE" | grep -n "^\s*image:" | head -1 | cut -d: -f1)
    if [ -z "$IMAGE_LINE" ]; then
        echo -e "${RED}错误: 无法找到容器 '${CONTAINER_NAME}' 的 image 配置${NC}"
        exit 1
    fi
    
    # 获取实际的 image 行号
    ACTUAL_IMAGE_LINE=$((SERVICE_START + IMAGE_LINE - 1))
    
    # 获取当前镜像名称（完整镜像名称）
    IMAGE_LINE_CONTENT=$(sed -n "${ACTUAL_IMAGE_LINE}p" "$COMPOSE_FILE")
    OLD_IMAGE=$(echo "$IMAGE_LINE_CONTENT" | sed 's/.*image:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    
    if [ -z "$OLD_IMAGE" ]; then
        echo -e "${RED}错误: 无法从容器 '${CONTAINER_NAME}' 中获取镜像名称${NC}"
        exit 1
    fi
    
    NEW_IMAGE="$IMAGE_NAME"
    
    echo -e "${BLUE}更新容器: ${CONTAINER_NAME}${NC}"
    echo -e "  当前镜像: ${OLD_IMAGE}"
    echo -e "  新镜像: ${NEW_IMAGE}"
    
    # 使用 awk 替换镜像名称（更安全，避免 sed 特殊字符问题）
    awk -v line="$ACTUAL_IMAGE_LINE" -v new_image="$NEW_IMAGE" '
        NR == line {
            # 匹配 image: 行，替换整个镜像名称
            if (match($0, /^([[:space:]]*image:[[:space:]]*)(.*)$/, arr)) {
                print arr[1] new_image
            } else {
                print $0
            }
            next
        }
        { print }
    ' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"
    
    # 检查替换是否成功
    if [ $? -ne 0 ]; then
        echo -e "${RED}  ✗ 镜像更新失败${NC}"
        exit 1
    fi
    
    # 验证更新是否成功
    UPDATED_LINE=$(sed -n "${ACTUAL_IMAGE_LINE}p" "$COMPOSE_FILE")
    if echo "$UPDATED_LINE" | grep -q "image:.*${NEW_IMAGE}"; then
        echo -e "${GREEN}  ✓ 镜像已更新${NC}"
        
        # 记录部署历史
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        echo "${TIMESTAMP} update image [${OLD_IMAGE}] -> [${NEW_IMAGE}]" >> "$DEPLOY_HISTORY"
    else
        echo -e "${RED}  ✗ 镜像更新失败${NC}"
        exit 1
    fi
    echo ""
done

# 进入服务目录并执行部署
cd "$SERVICE_DIR"
echo -e "${YELLOW}正在部署服务...${NC}"

# 检测 docker-compose 命令（按优先级：docker compose > docker-compose）
DOCKER_COMPOSE_CMD=""

# 优先使用 docker compose（新版本 Docker Compose V2）
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
    echo -e "${BLUE}使用命令: docker compose${NC}"
# 如果 docker compose 不可用，尝试 docker-compose（旧版本）
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
    echo -e "${BLUE}使用命令: docker-compose${NC}"
else
    echo -e "${RED}错误: 未找到 docker-compose 相关命令${NC}"
    echo -e "${YELLOW}请确保已安装 docker-compose 或 docker compose${NC}"
    exit 1
fi

if $DOCKER_COMPOSE_CMD pull && $DOCKER_COMPOSE_CMD up -d; then
    echo -e "${GREEN}✓ 服务部署成功!${NC}"
    echo ""
    echo "服务状态:"
    $DOCKER_COMPOSE_CMD ps
else
    echo -e "${RED}✗ 服务部署失败!${NC}"
    exit 1
fi

