#!/bin/bash

# 合并wfg-main分支的指定目录到main分支
# 使用方法: ./merge-wfg-to-main.sh [目录1] [目录2] ...
# 例如: ./merge-wfg-to-main.sh packages/core/src/core packages/core/src/utils

set -e  # 遇到错误时退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查当前分支
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" != "main" ]; then
    echo -e "${RED}错误: 当前不在main分支，请先切换到main分支${NC}"
    exit 1
fi

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}错误: 有未提交的更改，请先提交或暂存${NC}"
    exit 1
fi

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}用法: $0 [目录1] [目录2] ...${NC}"
    echo -e "${YELLOW}例如: $0 packages/core/src/core packages/core/src/utils${NC}"
    exit 1
fi

# 获取wfg-main分支的最新更改
echo -e "${GREEN}正在获取wfg-main分支的最新更改...${NC}"
git fetch origin wfg-main:wfg-main

# 创建临时分支用于合并
temp_branch="temp-merge-$(date +%Y%m%d-%H%M%S)"
echo -e "${GREEN}创建临时分支: $temp_branch${NC}"
git checkout -b "$temp_branch" wfg-main

# 回到main分支
git checkout main

# 逐个目录进行合并
for dir in "$@"; do
    echo -e "${GREEN}正在合并目录: $dir${NC}"

    # 检查目录是否存在
    if [ ! -d "$dir" ]; then
        echo -e "${RED}警告: 目录 $dir 不存在，跳过${NC}"
        continue
    fi

    # 从临时分支检出指定目录
echo -e "${GREEN}从wfg-main分支检出 $dir 到临时区域...${NC}"
    git checkout "$temp_branch" -- "$dir" 2>/dev/null || {
            echo -e "${RED}错误: 无法从wfg-main分支检出 $dir${NC}"
      continue
    }

    # 显示变更摘要
    echo -e "${YELLOW}变更摘要:${NC}"
    git diff --stat HEAD -- "$dir"

    # 询问是否继续
    read -p "是否继续合并这个目录? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}跳过 $dir${NC}"
        git checkout HEAD -- "$dir"
        continue
    fi

    # 添加到暂存区
    git add "$dir"

    # 提交更改
    commit_msg="Merge $dir from wfg-main branch

- Automatically merged using merge-wfg-to-main.sh script
- Source: wfg-main branch
- Merged directory: $dir"

    git commit -m "$commit_msg"
    echo -e "${GREEN}成功合并 $dir${NC}"
done

# 清理临时分支
echo -e "${GREEN}清理临时分支...${NC}"
git branch -D "$temp_branch"

echo -e "${GREEN}合并完成！${NC}"
echo -e "${YELLOW}注意: 请检查合并结果并推送到远程仓库${NC}"