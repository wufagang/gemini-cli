# ConsolePatcher 使用模式详解

## 概述

这段代码展示了 **ConsolePatcher 的标准使用模式**，用于在 Gemini
CLI 中管理控制台输出，确保调试信息和正常输出的分离，以及程序退出时的资源清理。

## 代码分析

```javascript
const consolePatcher = new ConsolePatcher({
  stderr: true,
  debugMode: isDebugMode,
});
consolePatcher.patch();
registerCleanup(consolePatcher.cleanup);
```

## 逐行解析

### 第一行：创建 ConsolePatcher 实例

```javascript
const consolePatcher = new ConsolePatcher({
  stderr: true,
  debugMode: isDebugMode,
});
```

#### 参数说明

- **`stderr: true`**: 将所有控制台输出重定向到标准错误流（stderr）
- **`debugMode: isDebugMode`**: 根据调试模式控制 debug 级别日志的输出

#### 配置效果

```javascript
// 当 stderr: true 时，所有 console 输出都会重定向
console.log('正常信息'); // 输出到 stderr 而不是 stdout
console.warn('警告信息'); // 输出到 stderr
console.error('错误信息'); // 输出到 stderr

// 当 debugMode: false 时
console.debug('调试信息'); // 不会输出

// 当 debugMode: true 时
console.debug('调试信息'); // 正常输出到 stderr
```

### 第二行：激活拦截功能

```javascript
consolePatcher.patch();
```

#### 功能说明

- **替换原始方法**: 将 `console.log`、`console.warn`、`console.error`
  等方法替换为自定义实现
- **立即生效**: 从这一刻开始，所有的 console 调用都会被拦截
- **透明拦截**: 对于调用者来说，console 方法的使用方式不变

#### 内部工作原理

```javascript
// patch() 方法内部做的事情（简化版）
patch() {
  // 保存原始方法
  this.originalConsoleLog = console.log;
  this.originalConsoleWarn = console.warn;
  this.originalConsoleError = console.error;

  // 替换为自定义方法
  console.log = this.patchConsoleMethod('log', this.originalConsoleLog);
  console.warn = this.patchConsoleMethod('warn', this.originalConsoleWarn);
  console.error = this.patchConsoleMethod('error', this.originalConsoleError);
}
```

### 第三行：注册清理函数

```javascript
registerCleanup(consolePatcher.cleanup);
```

#### 功能说明

- **资源清理**: 确保程序退出时恢复原始的 console 方法
- **防止副作用**: 避免影响其他可能运行的代码
- **优雅退出**: 保证程序的清理过程完整

#### 清理机制

```javascript
// cleanup 方法内部做的事情
cleanup = () => {
  // 恢复所有原始的 console 方法
  console.log = this.originalConsoleLog;
  console.warn = this.originalConsoleWarn;
  console.error = this.originalConsoleError;
  console.debug = this.originalConsoleDebug;
  console.info = this.originalConsoleInfo;
};
```

## 完整工作流程

### 1. 初始化阶段

```javascript
// 程序启动时
console.log('启动前的日志'); // 正常输出到 stdout

// 创建并激活 ConsolePatcher
const consolePatcher = new ConsolePatcher({
  stderr: true,
  debugMode: true,
});
consolePatcher.patch();
registerCleanup(consolePatcher.cleanup);

console.log('启动后的日志'); // 被重定向到 stderr
```

### 2. 运行阶段

```javascript
// 在程序运行期间
console.log('这会输出到 stderr');
console.warn('警告信息也到 stderr');
console.debug('调试信息（如果 debugMode 为 true）');

// 第三方库的 console 调用也会被拦截
someLibrary.doSomething(); // 内部的 console 调用也被重定向
```

### 3. 清理阶段

```javascript
// 程序退出时，registerCleanup 注册的函数会被调用
// consolePatcher.cleanup() 被执行

console.log('清理后的日志'); // 恢复到正常的 stdout
```

## 使用场景分析

### 1. CLI 工具中的应用

```javascript
// 在 gemini.tsx 中的使用
const isDebugMode = cliConfig.isDebugMode(argv);
const consolePatcher = new ConsolePatcher({
  stderr: true, // CLI 输出分离
  debugMode: isDebugMode, // 调试控制
});
consolePatcher.patch();
registerCleanup(consolePatcher.cleanup);

// 之后所有的 console 输出都不会干扰 CLI 的主要输出
console.log('内部调试信息'); // 到 stderr
// 而 CLI 的正常响应仍然可以通过其他方式输出到 stdout
```

### 2. 非交互式模式

```javascript
// 在 nonInteractiveCli.ts 中的使用
const consolePatcher = new ConsolePatcher({
  stderr: true, // 避免干扰管道输出
  debugMode: config.getDebugMode(), // 调试模式控制
});
consolePatcher.patch();

// 用户可以安全地使用管道
// $ gemini generate "code" > output.txt
// 所有调试信息去 stderr，生成的代码去 stdout
```

### 3. 沙箱环境

```javascript
// 在 sandbox.ts 中的使用
const patcher = new ConsolePatcher({
  debugMode: cliConfig?.getDebugMode() || !!process.env['DEBUG'],
  stderr: true, // 沙箱内的输出隔离
});
patcher.patch();

// 沙箱内的代码执行不会干扰主程序的输出
```

## 设计意图和好处

### 1. 输出流分离

```bash
# 没有 ConsolePatcher 的情况
$ gemini chat "hello" > response.txt
# response.txt 包含：
# [DEBUG] Loading config...
# [INFO] Connecting to API...
# AI: Hello! How can I help you?
# [DEBUG] Request completed

# 使用 ConsolePatcher 后
$ gemini chat "hello" > response.txt
# response.txt 只包含：
# AI: Hello! How can I help you?
#
# 调试信息输出到 stderr（不被重定向）
```

### 2. 调试模式控制

```javascript
// 生产模式
const consolePatcher = new ConsolePatcher({
  stderr: true,
  debugMode: false, // debug 信息被过滤
});

// 开发模式
const consolePatcher = new ConsolePatcher({
  stderr: true,
  debugMode: true, // 显示所有调试信息
});
```

### 3. 第三方库输出管理

```javascript
// 即使第三方库有 console 输出，也会被统一管理
import someNoisyLibrary from 'noisy-lib';

consolePatcher.patch();

// someNoisyLibrary 的内部 console 调用也被重定向
someNoisyLibrary.doSomething();
```

## 错误处理和边界情况

### 1. 重复 patch 防护

```javascript
class ConsolePatcher {
  constructor(params) {
    this.params = params;
    this.isPatched = false;
  }

  patch() {
    if (this.isPatched) {
      console.warn('ConsolePatcher 已经被应用');
      return;
    }

    // 执行 patch 逻辑...
    this.isPatched = true;
  }

  cleanup() {
    if (!this.isPatched) {
      return;
    }

    // 执行清理逻辑...
    this.isPatched = false;
  }
}
```

### 2. 异常安全

```javascript
function safelyApplyConsolePatcher(config) {
  let consolePatcher;

  try {
    consolePatcher = new ConsolePatcher(config);
    consolePatcher.patch();

    // 确保即使程序异常退出也能清理
    process.on('exit', () => {
      consolePatcher?.cleanup();
    });

    process.on('SIGINT', () => {
      consolePatcher?.cleanup();
      process.exit(0);
    });

    registerCleanup(consolePatcher.cleanup);
  } catch (error) {
    console.error('ConsolePatcher 初始化失败:', error);
    // 降级处理，不影响主要功能
  }

  return consolePatcher;
}
```

## 高级使用模式

### 1. 条件性应用

```javascript
function createConsolePatcher(options) {
  // 只在需要时才应用
  if (!options.needsOutputRedirection) {
    return null;
  }

  const consolePatcher = new ConsolePatcher({
    stderr: options.redirectToStderr,
    debugMode: options.enableDebug,
  });

  consolePatcher.patch();
  registerCleanup(consolePatcher.cleanup);

  return consolePatcher;
}

// 使用
const patcher = createConsolePatcher({
  needsOutputRedirection: isCliMode,
  redirectToStderr: true,
  enableDebug: process.env.DEBUG === '1',
});
```

### 2. 多实例管理

```javascript
class ConsolePatcherManager {
  constructor() {
    this.patchers = [];
  }

  createPatcher(config) {
    const patcher = new ConsolePatcher(config);
    patcher.patch();

    this.patchers.push(patcher);
    registerCleanup(() => this.cleanup());

    return patcher;
  }

  cleanup() {
    this.patchers.forEach((patcher) => patcher.cleanup());
    this.patchers = [];
  }
}

// 使用
const manager = new ConsolePatcherManager();
const mainPatcher = manager.createPatcher({ stderr: true, debugMode: true });
```

### 3. 动态配置

```javascript
class DynamicConsolePatcher extends ConsolePatcher {
  updateConfig(newConfig) {
    // 临时取消 patch
    this.cleanup();

    // 更新配置
    this.params = { ...this.params, ...newConfig };

    // 重新应用 patch
    this.patch();
  }

  toggleDebugMode() {
    this.updateConfig({
      debugMode: !this.params.debugMode,
    });
  }
}
```

## 调试和监控

### 1. 拦截统计

```javascript
class InstrumentedConsolePatcher extends ConsolePatcher {
  constructor(params) {
    super(params);
    this.stats = {
      log: 0,
      warn: 0,
      error: 0,
      debug: 0,
      info: 0,
    };
  }

  patchConsoleMethod = (type, originalMethod) => {
    return (...args) => {
      this.stats[type]++;

      // 调用父类方法
      return super.patchConsoleMethod(type, originalMethod)(...args);
    };
  };

  getStats() {
    return { ...this.stats };
  }

  resetStats() {
    Object.keys(this.stats).forEach((key) => {
      this.stats[key] = 0;
    });
  }
}
```

### 2. 性能监控

```javascript
class PerformanceConsolePatcher extends ConsolePatcher {
  constructor(params) {
    super(params);
    this.performanceData = [];
  }

  patchConsoleMethod = (type, originalMethod) => {
    return (...args) => {
      const start = performance.now();

      // 执行原始逻辑
      const result = super.patchConsoleMethod(type, originalMethod)(...args);

      const end = performance.now();
      this.performanceData.push({
        type,
        duration: end - start,
        timestamp: Date.now(),
      });

      return result;
    };
  };

  getPerformanceReport() {
    return {
      totalCalls: this.performanceData.length,
      averageDuration:
        this.performanceData.reduce((sum, item) => sum + item.duration, 0) /
        this.performanceData.length,
      byType: this.performanceData.reduce((acc, item) => {
        acc[item.type] = (acc[item.type] || 0) + 1;
        return acc;
      }, {}),
    };
  }
}
```

## 最佳实践

### 1. 生命周期管理

```javascript
// ✅ 推荐的使用模式
function setupConsolePatcher(config) {
  const consolePatcher = new ConsolePatcher({
    stderr: config.redirectToStderr,
    debugMode: config.debugMode,
  });

  // 立即应用
  consolePatcher.patch();

  // 确保清理
  registerCleanup(consolePatcher.cleanup);

  // 异常情况下也要清理
  process.on('uncaughtException', (error) => {
    consolePatcher.cleanup();
    console.error('未捕获的异常:', error);
    process.exit(1);
  });

  return consolePatcher;
}
```

### 2. 测试友好

```javascript
// 在测试环境中的处理
function createTestSafeConsolePatcher(config) {
  // 测试环境中可能不需要 patch
  if (process.env.NODE_ENV === 'test') {
    return {
      patch: () => {},
      cleanup: () => {},
      isTestStub: true,
    };
  }

  return new ConsolePatcher(config);
}
```

### 3. 配置验证

```javascript
function validateConsolePatcherConfig(config) {
  const errors = [];

  if (typeof config.stderr !== 'boolean') {
    errors.push('stderr 必须是 boolean 类型');
  }

  if (typeof config.debugMode !== 'boolean') {
    errors.push('debugMode 必须是 boolean 类型');
  }

  if (errors.length > 0) {
    throw new Error(`ConsolePatcher 配置错误: ${errors.join(', ')}`);
  }

  return config;
}
```

## 总结

这三行代码实现了一个完整的**控制台输出管理方案**：

### 🎯 核心功能

- **输出重定向**: 将 console 输出从 stdout 重定向到 stderr
- **调试控制**: 根据模式开关调试信息的显示
- **资源清理**: 确保程序退出时恢复原始状态

### 📈 价值体现

- **用户体验**: CLI 工具的输出更加清晰，支持管道操作
- **开发体验**: 调试信息和正常输出分离，便于问题排查
- **系统稳定**: 优雅的资源清理，避免副作用

### 🔧 适用场景

- **CLI 工具开发**: 分离用户输出和调试信息
- **非交互式脚本**: 支持管道和重定向操作
- **沙箱环境**: 隔离第三方代码的输出

这种模式在 Gemini CLI 中被广泛使用，是实现专业级 CLI 工具的重要技术手段。
