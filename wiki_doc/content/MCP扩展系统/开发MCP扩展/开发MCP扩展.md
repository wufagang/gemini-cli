# 开发MCP扩展

<cite>
**本文档中引用的文件**  
- [gemini-extension.json](file://hello/gemini-extension.json)
- [grep-code.toml](file://hello/commands/fs/grep-code.toml)
- [mcp-server.example.json](file://packages/cli/src/commands/extensions/examples/mcp-server/gemini-extension.json)
- [package.json](file://packages/cli/src/commands/extensions/examples/mcp-server/package.json)
- [settingsSchema.ts](file://packages/cli/src/config/settingsSchema.ts)
- [oauth-provider.ts](file://packages/core/src/mcp/oauth-provider.ts)
- [google-auth-provider.ts](file://packages/core/src/mcp/google-auth-provider.ts)
- [sa-impersonation-provider.ts](file://packages/core/src/mcp/sa-impersonation-provider.ts)
- [test-mcp-server.ts](file://integration-tests/test-mcp-server.ts)
</cite>

## 目录

1. [简介](#简介)
2. [MCP扩展清单文件](#mcp扩展清单文件)
3. [工具规范定义](#工具规范定义)
4. [创建MCP服务器](#创建mcp服务器)
5. [认证机制](#认证机制)
6. [测试与调试](#测试与调试)

## 简介

本指南旨在为开发者提供创建MCP（Model Context
Protocol）扩展的全面指导。通过分析`hello/`目录中的示例，我们将详细解释如何配置扩展清单文件、定义工具规范、创建MCP服务器、实现认证机制以及测试和调试扩展。MCP扩展允许开发者将自定义工具集成到Gemini
CLI中，从而扩展其功能。

## MCP扩展清单文件

MCP扩展清单文件（`gemini-extension.json`）是扩展的核心配置文件，定义了扩展的基本信息和服务器配置。

### 基本字段

`gemini-extension.json`文件包含以下基本字段：

- **name**: 扩展的唯一标识名称。例如，在`hello/`目录的示例中，名称为`custom-commands`。
- **version**: 扩展的版本号，遵循语义化版本控制。示例中版本为`1.0.0`。

```json
{
  "name": "custom-commands",
  "version": "1.0.0"
}
```

**Section sources**

- [gemini-extension.json](file://hello/gemini-extension.json#L1-L5)

### 服务器配置

扩展可以定义一个或多个MCP服务器。服务器配置包含启动服务器所需的所有信息。

#### 服务器配置示例

在`mcp-server-example`扩展中，`gemini-extension.json`文件定义了一个名为`nodeServer`的服务器：

```json
{
  "name": "mcp-server-example",
  "version": "1.0.0",
  "mcpServers": {
    "nodeServer": {
      "command": "node",
      "args": ["${extensionPath}${/}dist${/}example.js"],
      "cwd": "${extensionPath}"
    }
  }
}
```

- **command**: 启动服务器的命令，此处为`node`。
- **args**: 传递给命令的参数，使用`${extensionPath}`变量引用扩展的根目录。
- **cwd**: 服务器的工作目录，同样使用`${extensionPath}`变量。

**Section sources**

- [mcp-server.example.json](file://packages/cli/src/commands/extensions/examples/mcp-server/gemini-extension.json#L1-L11)

## 工具规范定义

工具规范定义了MCP服务器提供的工具，包括工具名称、描述和参数。

### 工具参数

工具的参数通过`inputSchema`字段定义，该字段遵循JSON
Schema规范。例如，在`grep-code.toml`文件中，定义了一个使用`grep`命令的工具：

```toml
prompt = """
Please summarize the findings for the pattern `{{args}}`.

Search Results:
!{grep -r {{args}} .}
"""
```

此工具接受一个名为`args`的参数，用于指定要搜索的模式。

**Section sources**

- [grep-code.toml](file://hello/commands/fs/grep-code.toml#L1-L7)

## 创建MCP服务器

创建MCP服务器涉及实现HTTP端点以响应工具调用。

### Node.js服务器示例

使用Node.js创建MCP服务器的步骤如下：

1. **安装依赖**: 在`package.json`中添加`@modelcontextprotocol/sdk`依赖。
2. **创建服务器**: 使用Express框架创建HTTP服务器。
3. **实现端点**: 实现`/mcp`端点以处理MCP请求。

```json
{
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.11.0"
  }
}
```

**Section sources**

- [package.json](file://packages/cli/src/commands/extensions/examples/mcp-server/package.json#L1-L19)

### HTTP端点实现

MCP服务器需要实现一个HTTP端点来处理工具调用。以下是一个使用Express框架的示例：

```typescript
import express from 'express';
import {
  McpServer,
  StreamableHTTPServerTransport,
} from '@modelcontextprotocol/sdk/server/mcp.js';

const app = express();
app.use(express.json());

const mcpServer = new McpServer(
  {
    name: 'test-mcp-server',
    version: '1.0.0',
  },
  { capabilities: { tools: {} } },
);

app.post('/mcp', async (req, res) => {
  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
    enableJsonResponse: true,
  });
  res.on('close', () => {
    transport.close();
  });
  await mcpServer.connect(transport);
  await transport.handleRequest(req, res, req.body);
});
```

**Section sources**

- [test-mcp-server.ts](file://integration-tests/test-mcp-server.ts#L1-L51)

## 认证机制

MCP支持多种认证机制，包括OAuth、Google登录和服务账号模拟。

### OAuth认证

OAuth认证通过`oauth`字段配置，支持动态发现和客户端注册。

```typescript
interface MCPOAuthConfig {
  enabled?: boolean;
  clientId?: string;
  clientSecret?: string;
  authorizationUrl?: string;
  tokenUrl?: string;
  scopes?: string[];
  audiences?: string[];
  redirectUri?: string;
  tokenParamName?: string;
  registrationUrl?: string;
}
```

**Section sources**

- [oauth-provider.ts](file://packages/core/src/mcp/oauth-provider.ts#L25-L36)

### Google登录

Google登录使用Google ADC（Application Default Credentials）进行认证。

```typescript
class GoogleCredentialProvider implements OAuthClientProvider {
  constructor(private readonly config?: MCPServerConfig) {
    const url = this.config?.url || this.config?.httpUrl;
    if (!url) {
      throw new Error(
        'URL must be provided in the config for Google Credentials provider',
      );
    }
  }
}
```

**Section sources**

- [google-auth-provider.ts](file://packages/core/src/mcp/google-auth-provider.ts#L1-L127)

### 服务账号模拟

服务账号模拟允许使用服务账号进行认证。

```typescript
class ServiceAccountImpersonationProvider implements OAuthClientProvider {
  constructor(private readonly config: MCPServerConfig) {
    if (!this.config.httpUrl && !this.config.url) {
      throw new Error(
        'A url or httpUrl must be provided for the Service Account Impersonation provider',
      );
    }
  }
}
```

**Section sources**

- [sa-impersonation-provider.ts](file://packages/core/src/mcp/sa-impersonation-provider.ts#L1-L159)

## 测试与调试

测试和调试MCP扩展是确保其正确性的关键步骤。

### 测试服务器连接

使用`/mcp list`命令可以列出所有配置的MCP服务器并测试其连接状态。

```typescript
async function testMCPConnection(
  serverName: string,
  config: MCPServerConfig,
): Promise<MCPServerStatus> {
  const client = new Client({
    name: 'mcp-test-client',
    version: '0.0.1',
  });

  let transport;
  try {
    transport = await createTransport(serverName, config, false);
  } catch (_error) {
    await client.close();
    return MCPServerStatus.DISCONNECTED;
  }

  try {
    await client.connect(transport, { timeout: 5000 });
    await client.ping();
    await client.close();
    return MCPServerStatus.CONNECTED;
  } catch (_error) {
    await transport.close();
    return MCPServerStatus.DISCONNECTED;
  }
}
```

**Section sources**

- [list.ts](file://packages/cli/src/commands/mcp/list.ts#L21-L72)
