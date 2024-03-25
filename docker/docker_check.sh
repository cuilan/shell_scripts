#!/bin/bash

set -e

# 检查运行中的
running=$(docker ps -f status=running --format {{.Names}})

# 检查已停止的
stop=$(docker ps -f status=exited --format {{.Names}})

# 检查重启的
restarting=$(docker ps -f status=restarting --format {{.Names}})

function generate_post_data() {
    local result="$1"
    # 通知时间
    notice_time=$(date +"%Y-%m-%d %H:%M:%S")
    cat <<EOF
{
    "msg_type": "post",
    "content": {
        "post": {
            "zh_cn": {
                "title": "$notice_time【Docker检查】",
                "content": [
                    $result
                ]
            }
        }
    }
}
EOF
}

function format_json() {
    local container_name="$1"
    cat <<EOF
[{
    "tag": "text",
    "text": "$container_name"
}]
EOF
}

function generate_content() {
    local content=""
    for container_name in $running; do
        content+="$(format_json "容器 $container_name 正在运行 (^_^)")"
        content+=","
    done
    for container_name in $stop; do
        content+="$(format_json "容器 $container_name 已停止 (-_-)")"
        content+=","
    done
    for container_name in $restarting; do
        content+="$(format_json "容器 $container_name 无限重启 (*_*)")"
        content+=","
    done
    if [ -z "$content" ]; then
        echo "一切正常"
    else
        content+=$(format_json "请尽快处理!")
        echo "$content"
    fi
}

result=$(generate_content)

# echo $(generate_post_data "$result")
if [ -z "$result"]; then
    echo ""
else
    curl -X "POST" "https://open.feishu.cn/open-apis/bot/v2/hook/" \
        -H 'Content-Type: application/json; charset=utf-8' \
        -d "$(generate_post_data "$result")"
fi
