# 🚀 Gemini CLI 项目启动指南

## 📋 项目概述

这是 **Google Gemini CLI** 项目，一个基于 Node.js 的 TypeScript 项目，使用
**monorepo** 架构（npm workspaces）。

## 🏗️ 项目架构

```
gemini-cli/
├── packages/
│   ├── cli/           # 主要的 CLI 应用
│   ├── core/          # 核心功能库
│   ├── a2a-server/    # A2A 服务器
│   ├── test-utils/    # 测试工具
│   └── vscode-ide-companion/  # VS Code 扩展
├── scripts/           # 构建和工具脚本
└── package.json       # 根配置文件
```

## ⚡ 快速启动（完整流程）

### 1. 环境要求

```bash
# 检查 Node.js 版本（需要 >=20.0.0）
node --version
```

### 2. 安装依赖

```bash
# 安装所有 workspace 的依赖
npm install
```

### 3. 构建项目

```bash
# 构建所有包（必须步骤）
npm run build
```

### 4. 启动开发环境

```bash
# 启动开发模式
npm start
```

## 🔧 详细启动命令说明

### 核心命令

| 命令                      | 说明         | 用途             |
| ------------------------- | ------------ | ---------------- |
| `npm start`               | 启动开发环境 | 日常开发使用     |
| `npm run build`           | 构建所有包   | 首次运行必须执行 |
| `npm run build-and-start` | 构建后启动   | 一键构建启动     |
| `npm run debug`           | 调试模式启动 | 带调试器启动     |

### 测试命令

| 命令                           | 说明         |
| ------------------------------ | ------------ |
| `npm test`                     | 运行所有测试 |
| `npm run test:e2e`             | 端到端测试   |
| `npm run test:integration:all` | 集成测试     |

### 代码质量命令

| 命令                | 说明                |
| ------------------- | ------------------- |
| `npm run lint`      | 代码检查            |
| `npm run lint:fix`  | 自动修复代码问题    |
| `npm run format`    | 代码格式化          |
| `npm run typecheck` | TypeScript 类型检查 |

## 🎯 常见启动场景

### 场景1：首次克隆项目

```bash
git clone https://github.com/google-gemini/gemini-cli.git
cd gemini-cli
npm install
npm run build
npm start
```

### 场景2：代码更改后重启

```bash
# 如果修改了源码，需要重新构建
npm run build
npm start
```

### 场景3：调试模式开发

```bash
# 启动调试模式
npm run debug
# 或设置环境变量
DEBUG=1 npm start
```

### 场景4：沙盒环境测试

```bash
# 构建沙盒镜像
npm run build:sandbox
# 运行沙盒测试
npm run test:integration:sandbox:docker
```

## 🔍 启动原理分析

### 启动流程

1. **`npm start`** → 执行 `scripts/start.js`
2. **start.js** → 检查构建状态，设置环境变量
3. **启动目标** → `packages/cli/dist/index.js`
4. **CLI 运行** → 加载核心模块，启动交互界面

### 关键文件

- **`scripts/start.js`**: 开发启动脚本
- **`packages/cli/dist/index.js`**: CLI 主入口点
- **`packages/core/`**: 核心功能库
- **`bundle/gemini.js`**: 最终打包的可执行文件

### 环境变量

```bash
NODE_ENV=development    # 开发模式
CLI_VERSION=0.15.0      # 版本号
DEV=true               # 开发标志
DEBUG=1                # 调试模式（可选）
```

## ⚠️ 常见问题

### 1. 构建失败

```bash
# 清理并重新构建
npm run clean
npm install
npm run build
```

### 2. 依赖缺失

```bash
# 重新安装依赖
rm -rf node_modules package-lock.json
npm install
```

### 3. TypeScript 错误

```bash
# 检查类型错误
npm run typecheck
```

### 4. dist 目录不存在

```bash
# 错误：packages/cli/dist/ 不存在
# 解决：必须先构建
npm run build
```

## 🚀 推荐开发流程

1. **首次设置**

   ```bash
   npm install
   npm run build
   ```

2. **日常开发**

   ```bash
   # 代码修改后
   npm run build    # 重建
   npm start        # 启动测试
   ```

3. **提交前检查**
   ```bash
   npm run lint:fix
   npm run typecheck
   npm test
   ```

## 📚 额外信息

- **项目类型**: TypeScript + React CLI 应用
- **UI 框架**: Ink (用于终端 UI)
- **包管理**: npm workspaces
- **构建工具**: esbuild + 自定义脚本
- **测试框架**: Vitest

## 🔧 开发调试技巧

### 1. 启用详细日志

```bash
# 设置调试环境变量
DEBUG=* npm start
```

### 2. 单独测试某个包

```bash
# 只测试 core 包
npm test --workspace @google/gemini-cli-core
```

### 3. 清理和重置

```bash
# 完全清理项目
npm run clean
rm -rf node_modules package-lock.json
npm install
npm run build
```

### 4. 查看构建产物

```bash
# 检查构建后的文件
ls -la packages/cli/dist/
ls -la bundle/
```

## 📋 项目脚本详解

### 构建相关

- `npm run generate` - 生成 Git 提交信息
- `npm run build:packages` - 只构建 npm packages
- `npm run build:sandbox` - 构建沙盒环境
- `npm run build:vscode` - 构建 VS Code 扩展
- `npm run bundle` - 创建最终打包文件

### 工具脚本

- `npm run schema:settings` - 生成设置 schema
- `npm run docs:settings` - 生成设置文档
- `npm run telemetry` - 遥测工具
- `npm run prepare:package` - 准备发布包

现在你就可以成功启动 Gemini CLI 项目了！🎉
