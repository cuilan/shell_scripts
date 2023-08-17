#!/bin/bash

# 删除缓存
git filter-branch -f --index-filter 'git rm --cached --ignore-unmatch Rakefile' HEAD

git filter-branch --env-filter '

OLD_EMAIL="zhangyan@weattech.com"
CORRECT_NAME="cuilan"
CORRECT_EMAIL="419475937@qq.com"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags