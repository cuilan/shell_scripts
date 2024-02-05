#!/bin/bash

# 列出前10个大文件
git rev-list --objects --all | grep "$(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -10 | awk '{print$1}')"

# git rm 指定大文件
git filter-branch --force --index-filter 'git rm -rf --cached --ignore-unmatch 大文件名称' --prune-empty --tag-name-filter cat -- --all

rm -rf .git/refs/original/

git reflog expire --expire=now --all

git gc --prune=now

git gc --aggressive --prune=now

git push origin master --force
