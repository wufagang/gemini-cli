# GitService 单元测试运行指南

## 文件概述

`packages/core/src/services/gitService.test.ts` 是 `GitService`
类的单元测试文件，使用 Vitest 测试框架编写。

## 文件作用

这个测试文件专门用来测试 `GitService`
类的各种功能，确保Git相关的服务能够正常工作。

### 主要测试内容

#### 1. 构造函数测试

- 验证 `GitService` 实例能够成功创建

#### 2. Git可用性验证 (`verifyGitAvailability`)

- 测试当系统中有Git时返回 `true`
- 测试当系统中没有Git时返回 `false`

#### 3. 初始化功能 (`initialize`)

- 测试当Git不可用时抛出错误
- 测试当Git可用时正确调用设置方法

#### 4. 影子Git仓库设置 (`setupShadowGitRepository`)

这是最复杂的测试部分，包括：

- 创建历史记录和仓库目录
- 创建 `.gitconfig` 配置文件
- 初始化Git仓库（如果未初始化）
- 复制项目的 `.gitignore` 文件到影子仓库
- 创建初始提交（如果仓库为空）

## 如何运行测试

### 方法一：运行所有 core 包的测试

**从项目根目录：**

```bash
npm run test --workspace @google/gemini-cli-core
```

**或者进入 packages/core 目录：**

```bash
cd packages/core
npm test
```

### 方法二：运行特定的测试文件

**从项目根目录：**

```bash
cd packages/core
npx vitest run src/services/gitService.test.ts
```

**或者使用文件匹配模式：**

```bash
cd packages/core
npx vitest run --reporter=verbose gitService
```

### 方法三：交互式测试模式

**监听模式（文件变更时自动重新运行）：**

```bash
cd packages/core
npx vitest gitService
```

### 方法四：带覆盖率报告

```bash
cd packages/core
npx vitest run --coverage src/services/gitService.test.ts
```

### 方法五：调试模式

```bash
cd packages/core
npx vitest run --reporter=verbose --no-coverage src/services/gitService.test.ts
```

## 测试配置说明

根据 `packages/core/vitest.config.ts`，这个项目的测试配置包括：

- **超时时间**：30秒
- **静默模式**：启用（减少输出噪音）
- **覆盖率**：自动生成，支持多种格式（HTML、JSON、LCOV、Cobertura）
- **线程池**：8-16个线程并行运行
- **输出格式**：默认格式 + JUnit XML
- **设置文件**：`test-setup.ts`

## 推荐的运行方式

对于开发调试，推荐使用：

```bash
cd packages/core
npx vitest run --reporter=verbose src/services/gitService.test.ts
```

这样可以看到详细的测试输出，方便调试和理解测试结果。

## 核心概念

从测试可以看出，`GitService` 实现了一个"**影子Git仓库**"功能：

- 在用户主目录下的 `.gemini/history/{项目hash}` 创建一个独立的Git仓库
- 这个仓库用于保存某种形式的历史记录或检查点
- 配置了专门的Git用户信息（Gemini CLI）

## 测试技术

文件使用了大量的**mock技术**来隔离测试：

- Mock了 `simple-git` 库
- Mock了文件系统操作
- Mock了shell命令执行
- 创建临时目录进行测试，测试完成后清理

这个测试文件确保了Gemini
CLI的Git集成功能能够可靠地工作，特别是历史记录和检查点功能。

## 常见问题

### 测试失败时的排查步骤

1. **检查Git是否安装**：确保系统中安装了Git
2. **检查文件权限**：确保测试有权限创建临时目录
3. **检查依赖**：运行 `npm install` 确保依赖完整
4. **查看详细输出**：使用 `--reporter=verbose` 参数获取详细信息

### 性能优化

如果测试运行较慢，可以：

1. 使用 `--no-coverage` 跳过覆盖率计算
2. 调整线程数：`--poolOptions.threads.maxThreads=4`
3. 只运行特定测试：使用文件名或模式匹配

## 相关文件

- 源码文件：`packages/core/src/services/gitService.ts`
- 测试配置：`packages/core/vitest.config.ts`
- 测试设置：`packages/core/test-setup.ts`
