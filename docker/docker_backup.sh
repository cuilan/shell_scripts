#!/bin/bash

# 查看当前所有数据卷
docker volume ls

docker volume inspect openldap_data

# local     confluence_conf
# local     confluence_data
# local     confluence_template

# 备份
# 将数据卷挂载到容器内 /tmp 目录下
# 将当前目录挂载到容器内 /backup 目录下
# 将 /tmp 目录打包到 /backup 下的tar文件
docker run --rm --volume confluence_template:/tmp --volume $(pwd):/backup cuilan/alpine tar cvf /backup/confluence_template.tar /tmp

docker run --rm --volume grafana_grafana-data:/tmp --volume $(pwd):/backup reg.weattech.com/dockerhub/debian:12.11 tar cvf /backup/grafana_grafana-data.tar /tmp

# 恢复
# 首先创建一个空数据卷
docker volume create confluence_template

docker volume create grafana_grafana-data

# 将新数据卷挂载到容器内 /tmp 目录下
# 将当前目录挂载到容器内 /backup 目录下
# 将 /backup 目录下的 tar 解压至 /tmp 目录下
docker run --rm --volume confluence_template:/tmp -v $(pwd):/backup cuilan/alpine tar xvf /backup/confluence_template.tar -C /tmp --strip 1

docker run --rm --volume grafana_grafana-data:/tmp -v $(pwd):/backup reg.weattech.com/dockerhub/debian:12.11 tar xvf /backup/grafana_grafana-data.tar -C /tmp --strip 1
