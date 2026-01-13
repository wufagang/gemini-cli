1. 安装依赖：npm install
2. 构建 CLI：cd packages/cli npm run build
3. 运行 CLI（三种方式）：

4. 方式 1：直接运行 node dist/index.js [命令]

# 例如：

node dist/index.js --help

3. 方式 2：使用 npm 脚本 npm run start -- [命令]

# 例如：

npm run start -- --help

3. 方式 3：全局安装 npm link

# 现在可以在任何地方使用：

gemini --help gemini "请帮我写一个 Python 函数"

常用命令

# 查看帮助

gemini --help

# 交互模式

gemini

# 一次性提问

gemini "请帮我写一个快速排序算法"

# 使用特定模型

gemini -m gemini-2.0-flash-exp "解释量子计算"

# 启用沙箱模式

gemini -s "运行这个 Python 脚本"

# 自动模式（无需确认）

gemini -y "修改 package.json 文件"

# 调试模式

gemini -d "调试这个错误"

开发模式

如果你想在开发时实时看到更改：

# 监听 TypeScript 文件变化

npm run typecheck -- --watch

# 重新构建

npm run build

# 本地调试使用

echo "Hello" | npm run start -- --debug

注意事项

1. Node.js 版本：需要 Node.js 20 或更高版本
2. 权限：某些操作可能需要文件系统权限
3. API 密钥：使用 Gemini API 需要配置相应的认证
4. 沙箱：沙箱模式需要 Docker 支持

自测1.工作拆分

# wfg-main 分支代码修改说明

为了wfg-main分支很友好的进行代码合并，同步main分支代码请遵守下面的原则，避免代码合并的出现冲突的情况

1. 采用“插件化”或“钩子（Hooks）”机制不要直接修改原项目的核心逻辑。如果原项目支持插件，尽量通过插件开发功能。做法：在原项目关键生命周期处寻找是否有拦截器、过滤器或事件监听。好处：原项目代码保持纯净，升级时只管覆盖，你的逻辑在外部。
2. 装饰器模式 / 代理模式 (AOP) 如果需要修改某个类的行为，不要直接改那个 .java 或 .js 文件。做法：继承原有的类或使用代理类，在你的子类中实现新功能，然后通过配置或依赖注入替换原有的类。
3. 目录结构分离（最推荐）Core 目录：存放原项目的原始代码，原则上禁止修改。Ext 目录/Custom 目录：存放你自己的业务逻辑。通过配置覆盖：利用语言特性（如 Java 的 Spring
   Bean 覆盖、Python 的 Monkey
   Patch、前端的 Alias 别名）将核心逻辑指向你的扩展目录。
