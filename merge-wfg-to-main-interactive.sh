#!/bin/bash

# 交互式合并wfg-main分支的指定目录到main分支
# 使用方法: ./merge-wfg-to-main-interactive.sh

set -e  # 遇到错误时退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  wfg-main 到 main 分支合并工具${NC}"
echo -e "${BLUE}========================================${NC}"

# 获取wfg-main分支的最新更改
echo -e "${GREEN}正在获取wfg-main分支的最新更改...${NC}"
git fetch origin wfg-main:wfg-main

# 创建临时分支用于合并
temp_branch="temp-merge-$(date +%Y%m%d-%H%M%S)"
echo -e "${GREEN}创建临时分支: $temp_branch${NC}"
git checkout -b "$temp_branch" wfg-main

# 回到main分支
git checkout main

# 获取wfg-main分支的所有目录
echo -e "${GREEN}正在扫描wfg-main分支的目录结构...${NC}"

directories=$(git ls-tree -d --name-only "$temp_branch" | grep -v '^\.' | sort)

if [ -z "$directories" ]; then
    echo -e "${RED}错误: 无法获取wfg-main分支的目录列表${NC}"
    git branch -D "$temp_branch"
    exit 1
fi

# 显示目录列表并让用户选择
echo -e "${YELLOW}请选择要合并的目录（输入数字，多个用空格分隔）:${NC}"
echo -e "${BLUE}0${NC}. 合并所有目录"

i=1
for dir in $directories; do
    # 检查该目录是否有变更
    if git diff --quiet main "$temp_branch" -- "$dir" 2>/dev/null; then
        status="${GREEN}[无变更]${NC}"
    else
        status="${YELLOW}[有变更]${NC}"
    fi
    echo -e "${BLUE}$i${NC}. $dir $status"
    eval "dir_$i=\"$dir\""
    ((i++))
done

# 读取用户输入
read -p "请输入选择（例如: 1 3 5 或 0）: " choices

# 处理用户选择
if [ "$choices" == "0" ]; then
    selected_dirs="$directories"
else
    selected_dirs=""
    for choice in $choices; do
        if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -gt 0 ] && [ $choice -lt $i ]; then
            eval "dir=\$dir_$choice"
            selected_dirs="$selected_dirs $dir"
        else
            echo -e "${RED}警告: 无效的选择: $choice${NC}"
        fi
    done
fi

if [ -z "$selected_dirs" ]; then
    echo -e "${RED}错误: 没有选择任何目录${NC}"
    git branch -D "$temp_branch"
    exit 1
fi

# 逐个目录进行合并
for dir in $selected_dirs; do
    echo -e "\n${GREEN}正在处理目录: $dir${NC}"

    # 显示详细的变更
    echo -e "${YELLOW}详细变更:${NC}"
    git diff main "$temp_branch" -- "$dir" --stat

    # 询问是否查看详细差异
    read -p "是否查看详细差异? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git diff main "$temp_branch" -- "$dir" | head -50
        echo -e "${YELLOW}... (只显示前50行)${NC}"
    fi

    # 询问是否合并
    read -p "是否合并这个目录? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}跳过 $dir${NC}"
        continue
    fi

    # 从临时分支检出指定目录
    echo -e "${GREEN}正在合并 $dir...${NC}"
    git checkout "$temp_branch" -- "$dir" || {
        echo -e "${RED}错误: 无法从wfg-main分支检出 $dir${NC}"
        continue
    }

    # 添加到暂存区
    git add "$dir"

    # 提交更改
    commit_msg="Merge $dir from wfg-main branch

- Automatically merged using merge-wfg-to-main-interactive.sh
- Source: wfg-main branch
- Merged directory: $dir
- Date: $(date)"

    git commit -m "$commit_msg"
    echo -e "${GREEN}✓ 成功合并 $dir${NC}"
done

# 清理临时分支
echo -e "\n${GREEN}清理临时分支...${NC}"
git branch -D "$temp_branch"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}合并完成！${NC}"
echo -e "${YELLOW}注意: 请检查合并结果并推送到远程仓库${NC}"
echo -e "${GREEN}========================================${NC}"