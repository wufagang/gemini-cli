# 扩展清单(gemini-extension.json)

<cite>
**本文档中引用的文件**  
- [gemini-extension.json](file://hello/gemini-extension.json)
- [gemini-extension.json](file://packages/cli/src/commands/extensions/examples/mcp-server/gemini-extension.json)
- [extension.ts](file://packages/cli/src/config/extension.ts)
- [settingsSchema.ts](file://packages/cli/src/config/settingsSchema.ts)
- [mcp-client.ts](file://packages/core/src/tools/mcp-client.ts)
- [oauth-provider.ts](file://packages/core/src/mcp/oauth-provider.ts)
- [google-auth-provider.ts](file://packages/core/src/mcp/google-auth-provider.ts)
- [sa-impersonation-provider.ts](file://packages/core/src/mcp/sa-impersonation-provider.ts)
</cite>

## 目录

1. [简介](#简介)
2. [核心字段详解](#核心字段详解)
3. [MCP服务器配置](#mcp服务器配置)
4. [认证机制详解](#认证机制详解)
5. [完整示例清单](#完整示例清单)
6. [验证规则与常见错误](#验证规则与常见错误)

## 简介

扩展清单文件（gemini-extension.json）是Gemini CLI系统中用于定义和配置MCP（Model
Context
Protocol）扩展的核心配置文件。该文件允许开发者声明扩展的元数据，并配置一个或多个MCP服务器，这些服务器为Gemini
CLI提供特定的功能。本指南将基于`hello/`和`packages/cli/src/commands/extensions/examples/mcp-server/`目录中的示例文件，详细解释该清单文件的结构、字段含义、配置方法以及验证规则。

**Section sources**

- [gemini-extension.json](file://hello/gemini-extension.json)
- [gemini-extension.json](file://packages/cli/src/commands/extensions/examples/mcp-server/gemini-extension.json)

## 核心字段详解

每个扩展清单文件都包含一组定义扩展基本信息的核心字段。这些字段是清单文件的必需组成部分。

### name

`name`字段是扩展的唯一标识符。它必须是一个有效的字符串，且在系统中必须是唯一的。根据代码库中的验证逻辑，名称不能包含下划线等无效字符，以确保其作为标识符的合法性。

### version

`version`字段指定了扩展的版本号。建议使用标准的语义化版本控制（SemVer）格式，例如`1.0.0`。虽然系统不会因非标准格式而完全失败，但会发出警告，因此遵循`主版本号.次版本号.修订号`的格式是最佳实践。

### description

`description`字段为扩展提供一个人类可读的描述。它解释了扩展的用途和功能，帮助用户理解该扩展的作用。这是一个可选字段，但强烈建议提供，以增强扩展的可发现性和可用性。

### apiVersion

`apiVersion`字段指定了该扩展所遵循的MCP API版本。它确保了扩展与Gemini
CLI核心系统之间的兼容性。开发者应查阅官方文档以确定当前支持的API版本，并据此设置此字段。

**Section sources**

- [extension.ts](file://packages/cli/src/config/extension.ts#L23-L30)

## MCP服务器配置

`mcpServers`字段是扩展清单中最重要的部分，它定义了一个对象，其中包含一个或多个MCP服务器的配置。每个服务器配置都以一个唯一的名称作为键。

### 服务器条目配置

每个服务器条目可以包含多种配置选项，以定义如何连接和与服务器交互。

#### command 和 args

当MCP服务器通过标准输入/输出（stdio）传输运行时，`command`字段指定要执行的可执行文件（如`node`），而`args`字段则提供传递给该命令的参数列表。在示例中，`args`使用了`${extensionPath}`变量，该变量会被替换为扩展的实际安装路径，确保了配置的可移植性。

#### url 和 httpUrl

对于通过网络传输的服务器，`url`字段用于指定SSE（Server-Sent
Events）传输的URL，而`httpUrl`字段则用于指定流式HTTP传输的URL。这两个字段是互斥的，通常只需要配置其中一个，具体取决于服务器的实现。

#### env 和 cwd

`env`字段允许为服务器进程设置环境变量，这对于传递配置或密钥非常有用。`cwd`字段定义了服务器进程的工作目录，通常也使用`${extensionPath}`来确保路径的正确性。

**Section sources**

- [extension.ts](file://packages/cli/src/config/extension.ts#L26)
- [settingsSchema.ts](file://packages/cli/src/config/settingsSchema.ts#L1371-L1417)

## 认证机制详解

MCP服务器通常需要认证才能访问。扩展清单通过`authentication`配置来处理不同的认证方案。根据`authProviderType`的值，系统会选择不同的认证提供者。

### OAuth2 认证

当`authProviderType`设置为`oauth2`时，系统使用`MCPOAuthProvider`类来处理OAuth
2.0授权码流程（带PKCE）。相关的配置在`oauth`对象中定义，包括：

- `clientId` 和 `clientSecret`：OAuth客户端的凭据。
- `authorizationUrl` 和 `tokenUrl`：授权和令牌端点的URL。
- `scopes`：请求的权限范围。
- `enabled`：一个布尔值，用于启用或禁用OAuth。

该流程会启动一个本地HTTP服务器来接收回调，引导用户完成浏览器中的认证，并安全地存储获取的访问令牌。

### Google Service Account 认证

当`authProviderType`设置为`google_service_account`时，系统使用`ServiceAccountImpersonationProvider`。这种认证方式允许一个服务账户代表另一个服务账户进行身份验证。它需要配置`targetAudience`和`targetServiceAccount`等字段。

### Google Credentials 认证

当`authProviderType`设置为`GOOGLE_CREDENTIALS`时，系统使用`GoogleCredentialProvider`。它依赖于Google
Application Default Credentials
(ADC) 来获取访问令牌。此方式要求配置有效的`scopes`，并且服务器URL的主机名必须在允许的列表中（如`*.googleapis.com`）。

**Section sources**

- [mcp-client.ts](file://packages/core/src/tools/mcp-client.ts#L1193-L1226)
- [oauth-provider.ts](file://packages/core/src/mcp/oauth-provider.ts#L25-L36)
- [google-auth-provider.ts](file://packages/core/src/mcp/google-auth-provider.ts#L21)
- [sa-impersonation-provider.ts](file://packages/core/src/mcp/sa-impersonation-provider.ts#L45)

## 完整示例清单

以下是一个注释详尽的`gemini-extension.json`文件示例，综合了上述所有配置：

```json
{
  "name": "my-mcp-extension",
  "version": "1.0.0",
  "description": "一个示例MCP扩展，用于演示配置。",
  "apiVersion": "2024-10-01",
  "mcpServers": {
    "localNodeServer": {
      "command": "node",
      "args": ["${extensionPath}/dist/server.js"],
      "cwd": "${extensionPath}",
      "env": {
        "NODE_ENV": "production"
      }
    },
    "cloudApiServer": {
      "url": "https://my-mcp-api.example.com/v1",
      "headers": {
        "X-Custom-Header": "value"
      },
      "authProviderType": "oauth2",
      "oauth": {
        "enabled": true,
        "clientId": "your-client-id",
        "clientSecret": "your-client-secret",
        "authorizationUrl": "https://auth.example.com/authorize",
        "tokenUrl": "https://auth.example.com/token",
        "scopes": ["read:data", "write:data"]
      }
    }
  }
}
```

开发者应根据其MCP服务器的具体情况，修改`name`、`version`、服务器的`url`/`command`以及认证凭据等字段。

## 验证规则与常见错误

为了确保扩展清单文件的有效性，系统提供了验证机制。可以通过`gemini extensions validate <path>`命令来验证一个扩展。

### 验证规则

- **必填字段**：`name`和`version`是必需的，缺少它们将导致验证失败。
- **名称格式**：`name`必须是有效的标识符，不能包含下划线等特殊字符。
- **版本格式**：虽然`version`不强制要求为SemVer格式，但非标准格式会触发警告。
- **配置结构**：JSON语法必须正确，否则文件将无法被加载。

### 常见错误

- **缺少name字段**：如果清单文件中没有`name`字段，系统会记录警告并跳过该扩展。
- **无效的JSON**：格式错误的JSON会导致扩展被跳过，并在日志中显示警告。
- **认证配置错误**：例如，为`GOOGLE_CREDENTIALS`类型配置了无效的主机名或缺少`scopes`，会导致运行时错误。
- **路径变量未解析**：如果`${extensionPath}`等变量在运行时无法正确解析，可能会导致服务器启动失败。

**Section sources**

- [extension.test.ts](file://packages/cli/src/config/extension.test.ts#L525-L557)
- [validate.ts](file://packages/cli/src/commands/extensions/validate.ts#L33-L73)
