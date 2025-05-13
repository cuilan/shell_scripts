#!/bin/bash

set -e

# 每台服务器都需要修改此配置部分

# 标题
TITLE="142-磁盘分区检查"

# 按照顺序声明
DISK_MOUNT_POINTS=(
    "/"
    "/home"
    "/data_download"
)

# 磁盘监控配置 (分区挂载点:告警阈值)
declare -A DISK_THRESHOLDS=(
    ["/"]=80
    ["/home"]=80
    ["/data_download"]=75
)

# ========== 不要修改以下内容 ==========

# 飞书机器人配置
FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxxxxxxxxxxxxxxxxxxxxxx"

# ========== 不要修改以下内容 ==========

# 临时文件目录
# TEMP_DIR="/tmp/disk_monitor"
# mkdir -p "$TEMP_DIR"

# 获取磁盘使用信息
get_disk_usage() {
    local mount_point=$1
    df -h | awk -v mp="$mount_point" '$NF == mp {print $5,$4}' | sed 's/%//g'
}

# 检查单个分区
check_single_partition() {
    local mount_point=$1
    local threshold=$2
    
    local usage_info=$(get_disk_usage "$mount_point")
    if [ -z "$usage_info" ]; then
        echo "错误：未找到挂载点: $mount_point"
        return 1
    fi
    
    local usage=$(echo "$usage_info" | awk '{print $1}')
    local available=$(echo "$usage_info" | awk '{print $2}')
    
    if [ "$usage" -ge "$threshold" ]; then
        echo "警告: $mount_point 分区已使用 ${usage}%，大于 ${threshold}% 阈值，剩余可用: ${available}"
    else
        echo "正常：$mount_point 分区已使用: ${usage}%，剩余可用: ${available}"
    fi
}

# 检查所有配置的分区
check_all_partitions() {
    local messages=()
    
    for mount_point in "${DISK_MOUNT_POINTS[@]}"; do
        local threshold=${DISK_THRESHOLDS[$mount_point]}
        local message=$(check_single_partition "$mount_point" "$threshold")
        messages+=("$message")
    done
    
    printf '%s\n' "${messages[@]}"
}

# 生成飞书消息
generate_feishu_message() {
    local messages=("$@")
    local current_time=$(date "+%Y-%m-%d %H:%M")
    local title="${TITLE} ${current_time}"
    
    # 构建消息内容数组
    local content_items=()
    for msg in "${messages[@]}"; do
        # 根据消息类型添加不同表情
        if [[ $msg == *"警告"* ]]; then
            content_items+=("[{\"tag\":\"text\",\"text\":\"\u26a0\ufe0f $msg\"}]")  # ⚠️
        elif [[ $msg == *"错误"* ]]; then
            content_items+=("[{\"tag\":\"text\",\"text\":\"\u274c $msg\"}]")  # ❌
        else
            content_items+=("[{\"tag\":\"text\",\"text\":\"\u2705 $msg\"}]")  # ✅
        fi
    done
    
    # 用逗号连接所有消息
    local content_list=$(IFS=,; echo "${content_items[*]}")
    
    cat <<EOF
{
    "msg_type": "post",
    "content": {
        "post": {
            "zh_cn": {
                "title": "$title",
                "content": [
                    ${content_list}
                ]
            }
        }
    }
}
EOF
}

# 发送通知到飞书
send_feishu_alert() {
    local messages=("$@")
    local post_data=$(generate_feishu_message "${messages[@]}")
    
    #echo $post_data
    curl -X POST "$FEISHU_WEBHOOK" \
         -H 'Content-Type: application/json; charset=utf-8' \
         -d "$post_data"
}

# 主函数
main() {
    # 检查所有分区并收集消息
    IFS=$'\n' read -r -d '' -a messages < <(check_all_partitions && printf '\0')
    
    # 发送飞书通知
    send_feishu_alert "${messages[@]}"
}

# 执行主函数
main

# 每天早08:01执行磁盘检查
# 01 08 * * *  /home/shell/check_disk.sh