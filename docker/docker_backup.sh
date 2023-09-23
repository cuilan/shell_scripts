#!/bin/bash

# 查看当前所有数据卷
docker volume ls

# local     confluence_conf
# local     confluence_data
# local     confluence_template

# 备份
# 将数据卷挂载到容器内 /tmp 目录下
# 将当前目录挂载到容器内 /backup 目录下
# 将 /tmp 目录打包到 /backup 下的tar文件
docker run --rm --volume confluence_template:/tmp --volume $(pwd):/backup cuilan/alpine tar cvf /backup/confluence_template.tar /tmp

# 恢复
# 首先创建一个空数据卷
docker volume create confluence_template

# 将新数据卷挂载到容器内 /tmp 目录下
# 将当前目录挂载到容器内 /backup 目录下
# 将 /backup 目录下的 tar 解压至 /tmp 目录下
docker run --rm --volume confluence_template:/tmp -v $(pwd):/backup cuilan/alpine tar xvf /backup/confluence_template.tar -C /tmp --strip 1