# process.cwd() 详解

## 概述

`process.cwd()` 是 Node.js 的内置方法，用于获取**当前工作目录**（Current Working
Directory）的绝对路径。这是 Node.js 开发中最基础和常用的路径操作方法之一。

## 基本概念

### CWD 含义

- **CWD** = Current Working Directory（当前工作目录）
- **定义**: 执行 Node.js 进程时所在的目录
- **特征**: 返回完整的绝对路径字符串
- **动态性**: 可以在程序运行期间改变

### 语法格式

```javascript
process.cwd();
```

- **参数**: 无参数
- **返回值**: `string` - 当前工作目录的绝对路径
- **同步执行**: 立即返回结果

## 基本使用

### 1. 获取当前目录

```javascript
const currentDir = process.cwd();
console.log('当前工作目录:', currentDir);
// 输出: /Users/wufagang/project/aiopen/gemini-cli
```

### 2. 在不同目录执行的结果

```bash
# 在 /Users/wufagang/Documents 目录执行
$ node -e "console.log(process.cwd())"
/Users/wufagang/Documents

# 在 /Users/wufagang/project 目录执行
$ node -e "console.log(process.cwd())"
/Users/wufagang/project

# 在任意目录执行都会返回该目录的绝对路径
```

## 与其他路径方法对比

### process.cwd() vs **dirname vs **filename

```javascript
// 假设脚本文件位于: /Users/wufagang/project/src/app.js
// 在 /Users/wufagang/project 目录下执行: node src/app.js

console.log('当前工作目录:', process.cwd());
// 输出: /Users/wufagang/project

console.log('脚本文件目录:', __dirname);
// 输出: /Users/wufagang/project/src

console.log('脚本文件路径:', __filename);
// 输出: /Users/wufagang/project/src/app.js
```

### 场景对比表

| 方法            | 含义             | 示例输出                             | 变化性 |
| --------------- | ---------------- | ------------------------------------ | ------ |
| `process.cwd()` | 执行命令的目录   | `/Users/wufagang/project`            | 可变   |
| `__dirname`     | 脚本文件所在目录 | `/Users/wufagang/project/src`        | 固定   |
| `__filename`    | 脚本文件完整路径 | `/Users/wufagang/project/src/app.js` | 固定   |

## 实际应用场景

### 1. 构建文件路径

```javascript
import path from 'path';

// 读取当前目录下的配置文件
const configPath = path.join(process.cwd(), 'config.json');
console.log('配置文件路径:', configPath);
// /Users/wufagang/project/config.json

// 创建输出目录
const outputDir = path.join(process.cwd(), 'dist', 'build');
console.log('输出目录:', outputDir);
// /Users/wufagang/project/dist/build

// 读取用户数据目录
const userDataPath = path.join(process.cwd(), 'data', 'users.json');
console.log('用户数据路径:', userDataPath);
// /Users/wufagang/project/data/users.json
```

### 2. 检查文件/目录存在性

```javascript
import fs from 'fs';
import path from 'path';

function checkProjectFiles() {
  const cwd = process.cwd();

  // 检查 package.json
  const packageJsonPath = path.join(cwd, 'package.json');
  const hasPackageJson = fs.existsSync(packageJsonPath);
  console.log('是否存在 package.json:', hasPackageJson);

  // 检查 src 目录
  const srcDir = path.join(cwd, 'src');
  const hasSrcDir = fs.existsSync(srcDir);
  console.log('是否存在 src 目录:', hasSrcDir);

  // 检查 .gitignore
  const gitignorePath = path.join(cwd, '.gitignore');
  const hasGitignore = fs.existsSync(gitignorePath);
  console.log('是否存在 .gitignore:', hasGitignore);
}

checkProjectFiles();
```

### 3. CLI 工具开发

```javascript
import path from 'path';
import fs from 'fs';

function initProject(projectName) {
  const cwd = process.cwd();
  const projectDir = path.join(cwd, projectName);

  // 创建项目目录
  if (!fs.existsSync(projectDir)) {
    fs.mkdirSync(projectDir, { recursive: true });
    console.log(`✅ 创建项目目录: ${projectDir}`);
  }

  // 创建基础文件
  const packageJsonPath = path.join(projectDir, 'package.json');
  const packageJson = {
    name: projectName,
    version: '1.0.0',
    description: '',
    main: 'index.js',
  };

  fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
  console.log(`✅ 创建 package.json: ${packageJsonPath}`);

  // 创建入口文件
  const indexPath = path.join(projectDir, 'index.js');
  fs.writeFileSync(indexPath, 'console.log("Hello World!");');
  console.log(`✅ 创建入口文件: ${indexPath}`);
}

// 使用示例
initProject('my-new-project');
```

### 4. 相对路径转绝对路径

```javascript
import path from 'path';

function resolveUserPath(userInput) {
  const cwd = process.cwd();

  // 处理相对路径
  if (!path.isAbsolute(userInput)) {
    return path.resolve(cwd, userInput);
  }

  // 已经是绝对路径
  return userInput;
}

// 示例用法
console.log(resolveUserPath('./src')); // /Users/wufagang/project/src
console.log(resolveUserPath('../config')); // /Users/wufagang/config
console.log(resolveUserPath('/absolute/path')); // /absolute/path
```

### 5. 项目根目录查找

```javascript
import path from 'path';
import fs from 'fs';

function findProjectRoot(startDir = process.cwd()) {
  let currentDir = startDir;

  while (currentDir !== path.parse(currentDir).root) {
    // 检查是否有 package.json
    const packageJsonPath = path.join(currentDir, 'package.json');
    if (fs.existsSync(packageJsonPath)) {
      return currentDir;
    }

    // 向上一层目录查找
    currentDir = path.dirname(currentDir);
  }

  return null; // 未找到项目根目录
}

// 使用示例
const projectRoot = findProjectRoot();
if (projectRoot) {
  console.log('项目根目录:', projectRoot);
} else {
  console.log('未找到项目根目录');
}
```

### 6. 备份和恢复工作目录

```javascript
function withDirectory(targetDir, callback) {
  const originalCwd = process.cwd();

  try {
    // 切换到目标目录
    process.chdir(targetDir);
    console.log(`切换到目录: ${process.cwd()}`);

    // 执行回调函数
    return callback();
  } finally {
    // 恢复原始工作目录
    process.chdir(originalCwd);
    console.log(`恢复到目录: ${process.cwd()}`);
  }
}

// 使用示例
withDirectory('/tmp', () => {
  console.log('当前在临时目录:', process.cwd());
  // 在这里执行需要在特定目录下的操作
});
```

## 高级用法

### 1. 动态路径配置

```javascript
import path from 'path';

class PathManager {
  constructor() {
    this.root = process.cwd();
    this.paths = {};
  }

  // 定义路径别名
  definePath(alias, relativePath) {
    this.paths[alias] = path.join(this.root, relativePath);
    return this;
  }

  // 获取路径
  getPath(alias) {
    return this.paths[alias];
  }

  // 获取相对于某个别名的路径
  resolve(alias, ...segments) {
    const basePath = this.paths[alias] || this.root;
    return path.join(basePath, ...segments);
  }
}

// 使用示例
const pathManager = new PathManager()
  .definePath('src', 'src')
  .definePath('dist', 'dist')
  .definePath('config', 'config')
  .definePath('assets', 'public/assets');

console.log(pathManager.getPath('src')); // /project/src
console.log(pathManager.resolve('src', 'components')); // /project/src/components
console.log(pathManager.resolve('assets', 'images')); // /project/public/assets/images
```

### 2. 跨平台路径处理

```javascript
import path from 'path';
import os from 'os';

class CrossPlatformPath {
  static getCurrentDirectory() {
    return process.cwd();
  }

  static getHomeDirectory() {
    return os.homedir();
  }

  static getTempDirectory() {
    return os.tmpdir();
  }

  static joinPath(...segments) {
    return path.join(...segments);
  }

  static resolvePath(...segments) {
    return path.resolve(...segments);
  }

  static getRelativePath(from, to) {
    return path.relative(from, to);
  }

  // 规范化路径（处理 Windows 和 Unix 差异）
  static normalizePath(inputPath) {
    return path.normalize(inputPath).replace(/\\/g, '/');
  }
}

// 使用示例
console.log('当前目录:', CrossPlatformPath.getCurrentDirectory());
console.log('用户目录:', CrossPlatformPath.getHomeDirectory());
console.log('临时目录:', CrossPlatformPath.getTempDirectory());

const configPath = CrossPlatformPath.joinPath(
  CrossPlatformPath.getCurrentDirectory(),
  'config',
  'app.json',
);
console.log('配置路径:', configPath);
```

## 注意事项和最佳实践

### 1. 工作目录可能变化

```javascript
console.log('初始工作目录:', process.cwd());

// 改变工作目录
process.chdir('/tmp');
console.log('切换后工作目录:', process.cwd());

// 最佳实践: 保存原始目录
const originalCwd = process.cwd();

// 执行需要特定目录的操作...

// 恢复原始目录
process.chdir(originalCwd);
```

### 2. 权限问题处理

```javascript
function safeGetCwd() {
  try {
    return process.cwd();
  } catch (error) {
    console.error('获取当前目录失败:', error.message);
    // 降级方案
    return process.env.PWD || process.env.INIT_CWD || '/';
  }
}

const currentDir = safeGetCwd();
console.log('当前目录:', currentDir);
```

### 3. 性能优化

```javascript
// ❌ 不好的做法 - 重复调用
function processFiles(files) {
  files.forEach((file) => {
    const fullPath = path.join(process.cwd(), file); // 每次都调用
    // 处理文件...
  });
}

// ✅ 好的做法 - 缓存结果
function processFiles(files) {
  const cwd = process.cwd(); // 只调用一次
  files.forEach((file) => {
    const fullPath = path.join(cwd, file);
    // 处理文件...
  });
}
```

### 4. 类型安全 (TypeScript)

```typescript
import path from 'path';

interface PathConfig {
  root: string;
  src: string;
  dist: string;
  config: string;
}

function createPathConfig(): PathConfig {
  const root = process.cwd();

  return {
    root,
    src: path.join(root, 'src'),
    dist: path.join(root, 'dist'),
    config: path.join(root, 'config'),
  };
}

const paths: PathConfig = createPathConfig();
console.log('路径配置:', paths);
```

## 常见问题和解决方案

### 1. 找不到文件问题

```javascript
import fs from 'fs';
import path from 'path';

function safeReadFile(relativePath) {
  const fullPath = path.join(process.cwd(), relativePath);

  console.log('尝试读取文件:', fullPath);
  console.log('当前工作目录:', process.cwd());

  if (!fs.existsSync(fullPath)) {
    throw new Error(`文件不存在: ${fullPath}`);
  }

  return fs.readFileSync(fullPath, 'utf-8');
}

// 调试用法
try {
  const content = safeReadFile('package.json');
  console.log('文件读取成功');
} catch (error) {
  console.error('错误:', error.message);
}
```

### 2. 符号链接处理

```javascript
import fs from 'fs';

function getRealCwd() {
  const cwd = process.cwd();

  try {
    // 解析符号链接
    const realPath = fs.realpathSync(cwd);
    return realPath;
  } catch (error) {
    console.warn('无法解析真实路径:', error.message);
    return cwd;
  }
}

console.log('工作目录:', process.cwd());
console.log('真实路径:', getRealCwd());
```

### 3. 多进程环境

```javascript
import cluster from 'cluster';

if (cluster.isMaster) {
  console.log('主进程工作目录:', process.cwd());

  // 创建工作进程
  const worker = cluster.fork();

  worker.on('message', (msg) => {
    console.log('工作进程反馈:', msg);
  });
} else {
  // 工作进程
  process.send({
    pid: process.pid,
    cwd: process.cwd(),
  });
}
```

## 环境变量相关

### 常用环境变量

```javascript
function getDirectoryInfo() {
  return {
    // 当前工作目录
    cwd: process.cwd(),

    // 环境变量中的目录信息
    pwd: process.env.PWD, // Unix 系统的当前目录
    initCwd: process.env.INIT_CWD, // npm/yarn 的初始目录
    home: process.env.HOME, // 用户主目录
    userProfile: process.env.USERPROFILE, // Windows 用户目录

    // Node.js 相关
    nodeEnv: process.env.NODE_ENV,
    nodePath: process.env.NODE_PATH,
  };
}

console.log('目录信息:', getDirectoryInfo());
```

## 调试技巧

### 1. 调试路径问题

```javascript
function debugPaths(label = '') {
  console.log(`\n=== 路径调试 ${label} ===`);
  console.log('process.cwd():', process.cwd());
  console.log('__dirname:', __dirname);
  console.log('__filename:', __filename);
  console.log('process.argv[1]:', process.argv[1]);
  console.log('process.env.PWD:', process.env.PWD);
  console.log('process.env.INIT_CWD:', process.env.INIT_CWD);
  console.log('=========================\n');
}

// 在关键位置调用
debugPaths('程序启动时');
```

### 2. 路径变化监控

```javascript
let lastCwd = process.cwd();

function checkCwdChange() {
  const currentCwd = process.cwd();
  if (currentCwd !== lastCwd) {
    console.log(`工作目录已改变: ${lastCwd} -> ${currentCwd}`);
    lastCwd = currentCwd;
  }
}

// 定期检查
setInterval(checkCwdChange, 1000);
```

## 总结

`process.cwd()` 是 Node.js 开发中的基础工具，主要用于：

- 🎯 **获取执行目录**: 确定 Node.js 进程的当前位置
- 🎯 **构建文件路径**: 与相对路径组合生成绝对路径
- 🎯 **CLI 工具开发**: 处理用户指定的相对路径
- 🎯 **项目配置管理**: 定位配置文件和资源
- 🎯 **跨平台兼容**: 提供统一的路径获取方式

### 关键要点

1. **动态性**: 工作目录可以在运行时改变
2. **绝对性**: 始终返回完整的绝对路径
3. **环境相关**: 取决于执行命令时所在的目录
4. **权限敏感**: 可能因权限问题而失败

在实际开发中，合理使用 `process.cwd()`
可以让你的 Node.js 应用更加灵活和用户友好。
