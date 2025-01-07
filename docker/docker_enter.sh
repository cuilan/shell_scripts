#!/bin/bash

# =============================
# docker-enter 快速进入docker容器
# @auther: zhang.yan
# @date: 2025/01/07
# =============================

# 获取正在运行的容器名称
container_list=$(docker ps --format "{{.Names}}")
container_count=$(echo "$container_list" | wc -l)

# 检查是否有容器在运行
if [ "$container_count" -eq 0 ]; then
  echo -e "\033[31m No running Docker containers found. \033[0m"
  exit 1
fi

# 显示容器列表
echo -e "\033[34m =================== Docker Containers =================== \033[0m"

# 判断容器数量是否大于等于 10
if [ "$container_count" -ge 10 ]; then
  # 容器数量大于等于 10，格式化为两位数右对齐
  index=0
  for container in $container_list; do
    index=$((index + 1))
    printf "\033[37m   [%2d]  %s\033[0m\n" $index "$container"
  done
else
  # 容器数量小于 10，直接输出
  index=0
  for container in $container_list; do
    index=$((index + 1))
    echo -e "\033[37m   [$index]  $container\033[0m"
  done
fi

echo -e "\033[34m ========================================================= \033[0m"

# 选择要进入的容器
echo -n "Enter the container index [1-$container_count]: "
read docker_index

# 输入验证
if ! [[ "$docker_index" =~ ^[0-9]+$ ]] || [ "$docker_index" -lt 1 ] || [ "$docker_index" -gt "$container_count" ]; then
  echo -e "\033[31m Invalid input. Please enter a valid container index. \033[0m"
  exit 1
fi

# 获取选择的容器名称
selected_container=$(echo "$container_list" | sed -n "${docker_index}p")
echo -e "\033[32m Entering container: $selected_container \033[0m"

# 尝试进入容器的 bash，如果失败则使用 sh
if docker exec "$selected_container" which bash > /dev/null 2>&1; then
  # 如果 bash 存在，使用 bash
  docker exec -it "$selected_container" /bin/bash
else
  # 如果 bash 不存在，使用 sh
  echo -e "\033[33m /bin/bash not found. Falling back to /bin/sh. \033[0m"
  docker exec -it "$selected_container" /bin/sh
fi
