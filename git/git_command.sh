#!/bin/bash

# 查看git仓库创建多久
git log --reverse | grep Date

# 查看git仓库有多大
git count-objects -vH