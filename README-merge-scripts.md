# 合并wfg-main分支到main分支的脚本使用说明

## 脚本列表

### 1. merge-wfg-to-main.sh

**功能**: 命令行参数方式合并指定目录 **用法**:

```bash
# 合并单个目录
./merge-wfg-to-main.sh packages/core/src/core

# 合并多个目录
./merge-wfg-to-main.sh packages/core/src/core packages/core/src/utils

# 合并特定模块
./merge-wfg-to-main.sh packages/core packages/cli
```

### 2. merge-wfg-to-main-interactive.sh

**功能**: 交互式选择要合并的目录 **用法**:

```bash
./merge-wfg-to-main-interactive.sh
```

## 使用步骤

### 前提条件

1. 当前必须在main分支
2. 工作目录必须是干净的（没有未提交的更改）

### 使用示例

#### 示例1: 合并核心模块

```bash
# 合并核心功能模块
./merge-wfg-to-main.sh packages/core/src/core
```

#### 示例2: 合并多个相关模块

```bash
# 合并多个相关目录
./merge-wfg-to-main.sh \
  packages/core/src/core \
  packages/core/src/utils \
  packages/core/src/config
```

#### 示例3: 使用交互式选择

```bash
# 运行交互式脚本，会显示所有可合并的目录
./merge-wfg-to-main-interactive.sh

# 然后根据提示输入数字选择要合并的目录
# 例如输入: 1 3 5
```

## 脚本特性

### 安全特性

- ✅ 检查当前分支是否为main
- ✅ 检查是否有未提交的更改
- ✅ 显示详细的变更摘要
- ✅ 每个目录合并前都会询问确认
- ✅ 支持查看详细差异

### 高级特性

- ✅ 自动创建临时分支
- ✅ 自动清理临时分支
- ✅ 支持合并所有目录（选项0）
- ✅ 详细的提交信息
- ✅ 支持重试和跳过

### 输出说明

- 🔴 `[无变更]` - 该目录在两个分支间没有差异
- 🟡 `[有变更]` - 该目录在wfg-main分支有更新

## 常见问题

### Q: 合并过程中断怎么办？

A: 脚本会清理临时分支，你可以重新运行。已合并的目录不会重复合并。

### Q: 如何查看合并后的结果？

A: 使用 `git log` 查看提交历史，或使用 `git diff HEAD~1` 查看最新更改。

### Q: 合并错了怎么办？

A: 使用 `git revert` 回退提交，或 `git reset` 回退到合并前的状态。

### Q: 可以合并特定文件吗？

A: 这些脚本设计用于目录级别。如需文件级别合并，建议使用
`git checkout wfg-main -- path/to/file`。

## 最佳实践

1. **小批量合并**: 一次不要合并太多目录，便于review
2. **先测试**: 合并后在本地测试功能是否正常
3. **及时推送**: 确认无误后及时推送到远程仓库
4. **备份重要分支**: 对于重要分支，可以先创建备份分支
