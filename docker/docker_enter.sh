#!/bin/bash

# =============================
# docker-enter 快速进入docker容器
# @auther: zhang.yan
# @date: 2021-10-15
# =============================

# 获取容器名称
arr=$(docker ps -a | awk '{print $NF}')

index=-1
echo -e "\033[34m =================== \033[0m"

# 循环打印容器名称
for i in ${arr[@]}
do
  index=$((index+1))
  if [ $index != 0 ]; then
    echo -e "\033[37m   [$index]    $i\033[0m"
  fi
done
echo -e "\033[34m =================== \033[0m"

echo -n "which docker contanier you want enter[1-$index]:"
read docker_index
echo -e "\033[31m index: $docker_index\033[0m"

index=-1
for i in ${arr[@]}
do
  index=$((index+1))
  if [ $index = "$docker_index" ]; then
    echo $i
    docker exec -it $i /bin/bash
  fi
done

