#!/bin/bash

set -e

# 扫描目录
SCAN_PATH=/tmp/test
# 递归深度，从 SCAN_PATH 目录开始算起
DEPTH=3
# 结果文件目录
RESULT_PATH=/tmp

function scan_files() {
    # 确保结果文件目录存在
    mkdir -p "$RESULT_PATH"
    
    # 生成基于当前时间的文件名（年月日时分秒.txt）
    local result_file="$RESULT_PATH/$(date +%Y%m%d%H%M%S).txt"
    
    # 清空结果文件
    > "$result_file"
    
    # 查找0字节文件并写入结果文件
    find "$SCAN_PATH" -type f -size 0 -maxdepth "$DEPTH" -print0 | while IFS= read -r -d '' file; do
        echo "$file" >> "$result_file"
    done
    
    echo "扫描完成，结果已保存到: $result_file"
}

scan_files
