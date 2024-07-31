#!/usr/bin/env bash

REPOSITORY="reg.weattech.com/dockerhub/"

if [ "$1" == "" ]; then
    echo -e "\033[31mError: imageName is blank!\033[0m"
    exit 1
fi

image=$1

echo -e "\033[32mAuto pull docker.io/library/${image} \033[0m"
echo -e ""
docker pull ${image}

echo -e "\033[33mTag docker.io/library/${image} -> ${REPOSITORY}${image} \033[0m"
echo -e ""
docker tag ${image} ${REPOSITORY}${image}

echo -e "\033[34mPush ${REPOSITORY}${image} \033[0m"
echo -e ""
docker push ${REPOSITORY}${image}

TITLE="Harbor dockerhub 镜像搬运组"
DOCKER_HUB="from docker.io/library/${image}"
REG_HUB="retag push ${REPOSITORY}${image}"

generate_post_data()
{
  cat <<EOF
{
    "msg_type": "post",
    "content": {
        "post": {
            "zh_cn": {
                "title": "$TITLE",
                "content": [
                    [
                        {
                            "tag": "text",
                            "text": "$DOCKER_HUB"
                        }
                    ],
                    [
                        {
                            "tag": "text",
                            "text": "$REG_HUB"
                        }
                    ]
                ]
            }
        }
    }
}
EOF
}

curl -X "POST" "https://open.feishu.cn/open-apis/bot/v2/hook/xxxxxxxxxxxxxxxxxxxxxxxxxx" \
     -H 'Content-Type: application/json; charset=utf-8' \
     -d "$(generate_post_data)"