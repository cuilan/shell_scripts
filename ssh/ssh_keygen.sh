#!/bin/bash

# ---- 可配置参数 ----
KEY_NAME="my45_id_ed25519"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
EMAIL="zhangyan@example.com"

REMOTE_USER="zy"
REMOTE_HOST="10.123.1.45"
REMOTE_PORT=22
COPY_TO_REMOTE=true   # 是否上传公钥到远程主机

# -------------------

echo "📦 准备生成 SSH 密钥: $KEY_PATH"

# 检查是否已存在
if [ -f "$KEY_PATH" ]; then
  echo "⚠️ 发现已有密钥文件：$KEY_PATH"
  read -p "是否覆盖？[y/N] " answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "❌ 取消生成密钥"
    exit 1
  fi
fi

# 生成 SSH 密钥
ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$EMAIL" -N ""

if [ $? -ne 0 ]; then
  echo "❌ 密钥生成失败"
  exit 1
fi

echo "✅ 密钥生成成功：$KEY_PATH 和 $KEY_PATH.pub"

# 拷贝到远程主机
if [ "$COPY_TO_REMOTE" = true ]; then
  echo "🚀 正在将公钥拷贝到远程主机：$REMOTE_USER@$REMOTE_HOST"
  ssh-copy-id -i "$KEY_PATH.pub" -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST"
  
  if [ $? -ne 0 ]; then
    echo "❌ 公钥拷贝失败，请手动确认远程连接是否正常"
    exit 1
  fi
  echo "✅ 公钥成功上传，可使用免密登录 SSH"
fi

# 测试 SSH 登录
echo "🔗 测试免密 SSH 连接：ssh -i $KEY_PATH -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST"
ssh -i "$KEY_PATH" -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" hostname

echo "🎉 全部完成"
