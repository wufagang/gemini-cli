# CLI命令参考

<cite>
**本文档中引用的文件**  
- [extensions.tsx](file://packages/cli/src/commands/extensions.tsx)
- [mcp.ts](file://packages/cli/src/commands/mcp.ts)
- [extensions/install.ts](file://packages/cli/src/commands/extensions/install.ts)
- [extensions/uninstall.ts](file://packages/cli/src/commands/extensions/uninstall.ts)
- [extensions/list.ts](file://packages/cli/src/commands/extensions/list.ts)
- [extensions/update.ts](file://packages/cli/src/commands/extensions/update.ts)
- [extensions/disable.ts](file://packages/cli/src/commands/extensions/disable.ts)
- [extensions/enable.ts](file://packages/cli/src/commands/extensions/enable.ts)
- [extensions/link.ts](file://packages/cli/src/commands/extensions/link.ts)
- [extensions/new.ts](file://packages/cli/src/commands/extensions/new.ts)
- [mcp/add.ts](file://packages/cli/src/commands/mcp/add.ts)
- [mcp/remove.ts](file://packages/cli/src/commands/mcp/remove.ts)
- [mcp/list.ts](file://packages/cli/src/commands/mcp/list.ts)
</cite>

## 目录

1. [简介](#简介)
2. [扩展命令](#扩展命令)
3. [MCP命令](#mcp命令)

## 简介

`gemini-cli` 是一个命令行工具，用于管理Gemini扩展和MCP（Model Context
Protocol）服务器。本参考文档详细介绍了所有可用的CLI命令，包括它们的语法、标志、选项和参数。文档结构反映了命令的层次结构，主要分为`extensions`和`mcp`两大子命令类别。

**Section sources**

- [extensions.tsx](file://packages/cli/src/commands/extensions.tsx)
- [mcp.ts](file://packages/cli/src/commands/mcp.ts)

## 扩展命令

`gemini extensions` 命令用于管理Gemini
CLI的扩展。它提供了一系列子命令来安装、卸载、列出和更新扩展。

### 安装扩展

`gemini extensions install` 命令用于从Git仓库URL或本地路径安装扩展。

**语法**

```
gemini extensions install <source> [--ref <ref>] [--auto-update] [--pre-release] [--consent]
```

**选项**

- `source` (必需): 要安装的扩展的GitHub URL或本地路径。
- `--ref <ref>`: 要从其安装的Git引用（例如分支、标签或提交哈希）。
- `--auto-update`: 为此扩展启用自动更新。
- `--pre-release`: 允许使用此扩展的预发布版本。
- `--consent`: 确认安装扩展的安全风险并跳过确认提示。

**示例**

```bash
# 从GitHub安装扩展
gemini extensions install https://github.com/user/repo.git

# 从特定分支安装
gemini extensions install https://github.com/user/repo.git --ref main

# 从本地路径安装
gemini extensions install /path/to/local/extension
```

**预期输出** 安装成功后，将输出类似
`Extension "extension-name" installed successfully and enabled.` 的消息。

**Section sources**

- [extensions/install.ts](file://packages/cli/src/commands/extensions/install.ts)

### 卸载扩展

`gemini extensions uninstall` 命令用于卸载已安装的扩展。

**语法**

```
gemini extensions uninstall <name>
```

**选项**

- `name` (必需): 要卸载的扩展的名称或源路径。

**示例**

```bash
gemini extensions uninstall my-extension
```

**预期输出** 卸载成功后，将输出类似
`Extension "my-extension" successfully uninstalled.` 的消息。

**Section sources**

- [extensions/uninstall.ts](file://packages/cli/src/commands/extensions/uninstall.ts)

### 列出扩展

`gemini extensions list` 命令用于列出所有已安装的扩展。

**语法**

```
gemini extensions list
```

**示例**

```bash
gemini extensions list
```

**预期输出**
将列出所有已安装的扩展，每个扩展显示其名称、版本和源。如果没有安装扩展，则输出
`No extensions installed.`。

**Section sources**

- [extensions/list.ts](file://packages/cli/src/commands/extensions/list.ts)

### 更新扩展

`gemini extensions update` 命令用于更新一个或所有扩展到最新版本。

**语法**

```
gemini extensions update [<name>] [--all]
```

**选项**

- `name`: 要更新的特定扩展的名称。
- `--all`: 更新所有可更新的扩展。

**示例**

```bash
# 更新特定扩展
gemini extensions update my-extension

# 更新所有扩展
gemini extensions update --all
```

**预期输出** 更新成功后，将输出类似
`Extension "my-extension" successfully updated: 1.0.0 → 1.1.0.`
的消息。如果没有扩展需要更新，则输出 `No extensions to update.`。

**Section sources**

- [extensions/update.ts](file://packages/cli/src/commands/extensions/update.ts)

### 禁用扩展

`gemini extensions disable` 命令用于禁用一个扩展。

**语法**

```
gemini extensions disable [--scope <scope>] <name>
```

**选项**

- `name` (必需): 要禁用的扩展的名称。
- `--scope <scope>`: 禁用扩展的作用域（`user` 或 `workspace`），默认为 `user`。

**示例**

```bash
gemini extensions disable my-extension --scope workspace
```

**预期输出** 禁用成功后，将输出类似
`Extension "my-extension" successfully disabled for scope "workspace".` 的消息。

**Section sources**

- [extensions/disable.ts](file://packages/cli/src/commands/extensions/disable.ts)

### 启用扩展

`gemini extensions enable` 命令用于启用一个扩展。

**语法**

```
gemini extensions enable [--scope <scope>] <name>
```

**选项**

- `name` (必需): 要启用的扩展的名称。
- `--scope <scope>`: 启用扩展的作用域（`user` 或
  `workspace`）。如果不设置，则在所有作用域中启用。

**示例**

```bash
gemini extensions enable my-extension --scope user
```

**预期输出** 启用成功后，将输出类似
`Extension "my-extension" successfully enabled for scope "user".` 的消息。

**Section sources**

- [extensions/enable.ts](file://packages/cli/src/commands/extensions/enable.ts)

### 链接扩展

`gemini extensions link`
命令用于从本地路径链接一个扩展。对本地路径所做的更改将始终反映出来。

**语法**

```
gemini extensions link <path>
```

**选项**

- `path` (必需): 要链接的扩展的本地路径。

**示例**

```bash
gemini extensions link /path/to/my-extension
```

**预期输出** 链接成功后，将输出类似
`Extension "my-extension" linked successfully and enabled.` 的消息。

**Section sources**

- [extensions/link.ts](file://packages/cli/src/commands/extensions/link.ts)

### 创建新扩展

`gemini extensions new` 命令用于从样板示例创建一个新的扩展。

**语法**

```
gemini extensions new <path> [template]
```

**选项**

- `path` (必需): 创建扩展的路径。
- `template`: 要使用的样板模板名称。

**示例**

```bash
# 创建一个空的扩展
gemini extensions new my-new-extension

# 使用特定模板创建扩展
gemini extensions new my-new-extension scrollable-list-demo
```

**预期输出** 创建成功后，将输出类似
`Successfully created new extension at my-new-extension.`
的消息，并提示如何链接和测试该扩展。

**Section sources**

- [extensions/new.ts](file://packages/cli/src/commands/extensions/new.ts)

## MCP命令

`gemini mcp` 命令用于管理MCP（Model Context
Protocol）服务器，这些服务器为Gemini提供额外的工具和功能。

### 添加MCP服务器

`gemini mcp add` 命令用于添加一个新的MCP服务器配置。

**语法**

```
gemini mcp add [options] <name> <commandOrUrl> [args...]
```

**选项**

- `name` (必需): 服务器的名称。
- `commandOrUrl` (必需): 对于stdio传输是命令，对于sse/http传输是URL。
- `--scope, -s <scope>`: 配置作用域（`user` 或 `project`），默认为 `project`。
- `--transport, -t <transport>`: 传输类型（`stdio`, `sse`, `http`），默认为
  `stdio`。
- `--env, -e <KEY=VALUE>`: 为服务器设置环境变量。
- `--header, -H <KEY: VALUE>`: 为SSE和HTTP传输设置HTTP头。
- `--timeout <ms>`: 设置连接超时（毫秒）。
- `--trust`: 信任服务器（绕过所有工具调用确认提示）。
- `--description <desc>`: 设置服务器的描述。
- `--include-tools <tool1,tool2>`: 要包含的工具的逗号分隔列表。
- `--exclude-tools <tool1,tool2>`: 要排除的工具的逗号分隔列表。

**示例**

```bash
# 添加一个stdio传输的服务器
gemini mcp add my-server "python3 -m my_server" --env API_KEY=abc123

# 添加一个SSE传输的服务器
gemini mcp add my-sse-server https://example.com/sse --transport sse --header "Authorization: Bearer token123"
```

**预期输出** 添加成功后，将输出类似
`MCP server "my-server" added to project settings. (stdio)` 的消息。

**Section sources**

- [mcp/add.ts](file://packages/cli/src/commands/mcp/add.ts)

### 移除MCP服务器

`gemini mcp remove` 命令用于移除一个MCP服务器配置。

**语法**

```
gemini mcp remove [options] <name>
```

**选项**

- `name` (必需): 要移除的服务器的名称。
- `--scope, -s <scope>`: 配置作用域（`user` 或 `project`），默认为 `project`。

**示例**

```bash
gemini mcp remove my-server --scope user
```

**预期输出** 移除成功后，将输出类似
`Server "my-server" removed from user settings.`
的消息。如果服务器未找到，则输出
`Server "my-server" not found in user settings.`。

**Section sources**

- [mcp/remove.ts](file://packages/cli/src/commands/mcp/remove.ts)

### 列出MCP服务器

`gemini mcp list` 命令用于列出所有已配置的MCP服务器，并测试其连接状态。

**语法**

```
gemini mcp list
```

**示例**

```bash
gemini mcp list
```

**预期输出**
将列出所有配置的MCP服务器，每个服务器前有一个状态指示符（✓表示已连接，✗表示已断开连接），并显示其名称、URL/命令和状态。例如：

```
✓ my-server: python3 -m my_server (stdio) - Connected
✗ my-sse-server: https://example.com/sse (sse) - Disconnected
```

如果没有配置服务器，则输出 `No MCP servers configured.`。

**Section sources**

- [mcp/list.ts](file://packages/cli/src/commands/mcp/list.ts)
