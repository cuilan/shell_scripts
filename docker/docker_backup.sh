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

# 恢复
# 首先创建一个空数据卷
docker volume create confluence_template

# 将新数据卷挂载到容器内 /tmp 目录下
# 将当前目录挂载到容器内 /backup 目录下
# 将 /backup 目录下的 tar 解压至 /tmp 目录下
docker run --rm --volume confluence_template:/tmp -v $(pwd):/backup cuilan/alpine tar xvf /backup/confluence_template.tar -C /tmp --strip 1

# ------------

docker run --rm --volume gitlab_config:/tmp --volume $(pwd):/backup cuilan/alpine tar cvf /backup/gitlab_config.tar /tmp
docker run --rm --volume gitlab_data:/tmp --volume $(pwd):/backup cuilan/alpine tar cvf /backup/gitlab_data.tar /tmp
docker run --rm --volume gitlab_logs:/tmp --volume $(pwd):/backup cuilan/alpine tar cvf /backup/gitlab_logs.tar /tmp

docker save gitlab/gitlab-ce:13.7.4-ce.0 > gitlab_gitlab-ce_13.7.4-ce.0.tar

scp gitlab_config.tar root@10.121.1.75:/home/docker-compose/gitlab

weattech.com

docker run --rm --volume gitlab_config:/tmp -v $(pwd):/backup cuilan/alpine tar xvf /backup/gitlab_config.tar -C /tmp --strip 1
docker run --rm --volume gitlab_data:/tmp -v $(pwd):/backup cuilan/alpine tar xvf /backup/gitlab_data.tar -C /tmp --strip 1
docker run --rm --volume gitlab_logs:/tmp -v $(pwd):/backup cuilan/alpine tar xvf /backup/gitlab_logs.tar -C /tmp --strip 1
