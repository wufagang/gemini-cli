# 概述

分析这个框架我们一直带着这么一个问题： 为什么那么多的框架表现出来的效果差距这么大？即便同一个模型效果也是不一样？

一直带着这个问题分析各个框架，包括 openmanus，unas, oxygent, deepcode, kode,
geminni，包括自己写的一个java版的这类的agent框架，以及公司内部的joycode，这个效果很堪忧，经常编写的代码不能编译通过， 这些框架，使用的更多，总结下来：从大体上一看思路都差不多，但是表现出来的效果确天差地别。

why？

1. 模型不一致？ 这个我们可以自己替换看效果，有大部分效果变化不是很大， 除非模型的能力差距很大的除外
2. 提示词（尤其系统提示词）？ 这个我分析的比较少，但是这个影响非常厉害，在自己开发agent框架里面体现的非常明显。
3. 上下文？
4. memory？
5. 工具选择？还是内置工具效果不一样

。。。。。。。需要找到真正的原因，也许是多重原因重叠起来导致的，找到调试的最佳姿势带着这么目的去深入分析一下这类的开源代码， 不断是去尝试改造这些变量

# 项目架构分析

```mermaid
@startuml Gemini CLI 系统架构图
!theme spacelab
title Gemini CLI 系统架构图\n(基于源码分析的完整架构)

' 定义颜色
!define CLI_COLOR #E3F2FD
!define CORE_COLOR #F3E5F5
!define TOOLS_COLOR #E8F5E8
!define SERVICES_COLOR #FFF3E0
!define EXTERNAL_COLOR #FFEBEE
!define DATA_COLOR #F1F8E9

' ===============================
' 用户界面层 (CLI Package)
' ===============================
package "CLI Package (packages/cli)" as cli_pkg CLI_COLOR {

  package "UI Components" as ui_components {
    component [AppContainer] as app_container
    component [ChatInterface] as chat_interface
    component [StreamingContent] as streaming_content
    component [InputBar] as input_bar
    component [StatusBar] as status_bar
  }

  package "React + Ink Framework" as react_ink {
    component [ThemeProvider] as theme_provider
    component [KeypressProvider] as keypress_provider
    component [VimModeProvider] as vim_mode_provider
    component [SessionStatsProvider] as session_stats_provider
  }

  package "Command Processing" as cmd_processing {
    component [CommandParser] as cmd_parser
    component [ArgumentValidator] as arg_validator
    component [OutputFormatter] as output_formatter
  }

  package "Configuration" as cli_config {
    component [CLIConfigLoader] as cli_config_loader
    component [SettingsContext] as settings_context
  }
}

' ===============================
' 核心业务逻辑层 (Core Package)
' ===============================
package "Core Package (packages/core)" as core_pkg CORE_COLOR {

  package "AI Client" as ai_client {
    component [GeminiClient] as gemini_client
    component [ChatCompressionService] as chat_compression
    component [LoopDetectionService] as loop_detection
    component [ModelRouterService] as model_router
  }

  package "Configuration System" as config_system {
    component [ConfigManager] as config_manager
    component [MultiLayerConfig] as multi_layer_config
    component [PolicyEngine] as policy_engine
    component [ExtensionManager] as extension_manager
  }

  package "Tool Registry" as tool_registry {
    component [ToolRegistry] as tool_registry_comp
    component [McpClientManager] as mcp_client_manager
    component [ToolDiscovery] as tool_discovery
    component [ToolValidator] as tool_validator
  }

  package "Authentication" as auth_system {
    component [AuthProvider] as auth_provider
    component [OAuthHandler] as oauth_handler
    component [APIKeyManager] as api_key_manager
    component [CredentialStorage] as credential_storage
  }

  package "Security & Sandbox" as security {
    component [SandboxManager] as sandbox_manager
    component [TrustService] as trust_service
    component [CommandParser] as security_parser
    component [PermissionController] as permission_controller
  }
}

' ===============================
' 工具执行层 (Tools)
' ===============================
package "Tools Layer (packages/core/src/tools)" as tools_pkg TOOLS_COLOR {

  package "Built-in Tools" as builtin_tools {
    component [ReadFileTool] as read_file_tool
    component [WriteFileTool] as write_file_tool
    component [EditTool] as edit_tool
    component [ShellTool] as shell_tool
    component [GrepTool] as grep_tool
    component [WebFetchTool] as web_fetch_tool
    component [WebSearchTool] as web_search_tool
    component [LSTool] as ls_tool
    component [GlobTool] as glob_tool
  }

  package "MCP Tools" as mcp_tools {
    component [MCPProxyTool] as mcp_proxy_tool
    component [MCPOAuthProvider] as mcp_oauth_provider
    component [MCPToolAdapter] as mcp_tool_adapter
  }

  package "Custom Tools" as custom_tools {
    component [CustomToolLoader] as custom_tool_loader
    component [ToolAPI] as tool_api
  }
}

' ===============================
' 基础服务层 (Services)
' ===============================
package "Services Layer (packages/core/src/services)" as services_pkg SERVICES_COLOR {
  component [FileDiscoveryService] as file_discovery
  component [GitService] as git_service
  component [ShellExecutionService] as shell_execution
  component [ChatRecordingService] as chat_recording
  component [TelemetryService] as telemetry_service
  component [MessageBus] as message_bus
}

' ===============================
' A2A Server Package
' ===============================
package "A2A Server (packages/a2a-server)" as a2a_pkg SERVICES_COLOR {
  component [HTTPServer] as http_server
  component [AgentExecutor] as agent_executor
  component [FileStorageService] as file_storage
}

' ===============================
' VSCode Integration
' ===============================
package "VSCode Extension (packages/vscode-ide-companion)" as vscode_pkg SERVICES_COLOR {
  component [IDEContextProvider] as ide_context
  component [VSCodeExtension] as vscode_extension
}

' ===============================
' 外部系统
' ===============================
cloud "External Systems" as external_systems EXTERNAL_COLOR {

  package "Google Services" as google_services {
    component [Gemini API] as gemini_api
    component [Google Search API] as google_search_api
    component [Google OAuth] as google_oauth
    component [Vertex AI] as vertex_ai
    component [Google Cloud Storage] as gcs
  }

  package "MCP Ecosystem" as mcp_ecosystem {
    component [MCP Servers] as mcp_servers
    component [Third-party Tools] as third_party_tools
  }

  package "Container Runtime" as container_runtime {
    component [Docker] as docker
    component [Podman] as podman
    component [macOS Seatbelt] as seatbelt
  }

  package "Development Tools" as dev_tools {
    component [VS Code] as vscode
    component [Git Repository] as git_repo
    component [File System] as file_system
    component [Terminal] as terminal
  }
}

' ===============================
' 数据存储
' ===============================
database "Local Storage" as local_storage DATA_COLOR {
  component [Configuration Files] as config_files
  component [Cache Storage] as cache_storage
  component [Credentials Store] as credentials_store
  component [Chat History] as chat_history
  component [Extension Storage] as extension_storage
}

' ===============================
' 连接关系 - CLI到Core
' ===============================
cli_pkg --> core_pkg : "调用核心功能"
app_container --> gemini_client : "发送用户请求"
chat_interface --> tool_registry_comp : "获取工具列表"
streaming_content --> gemini_client : "接收流式响应"
cmd_parser --> config_manager : "获取配置"
cli_config_loader --> multi_layer_config : "加载配置"

' ===============================
' 连接关系 - Core内部
' ===============================
gemini_client --> chat_compression
gemini_client --> loop_detection
gemini_client --> model_router
tool_registry_comp --> mcp_client_manager
tool_registry_comp --> tool_discovery
config_manager --> multi_layer_config
config_manager --> policy_engine
auth_provider --> oauth_handler
auth_provider --> api_key_manager
sandbox_manager --> trust_service
sandbox_manager --> permission_controller

' ===============================
' 连接关系 - Core到Tools
' ===============================
tool_registry_comp --> builtin_tools : "注册内置工具"
tool_registry_comp --> mcp_tools : "注册MCP工具"
mcp_client_manager --> mcp_proxy_tool : "管理MCP工具"
shell_tool --> shell_execution : "执行Shell命令"

' ===============================
' 连接关系 - Core到Services
' ===============================
core_pkg --> services_pkg : "使用基础服务"
tool_discovery --> file_discovery
edit_tool --> git_service
gemini_client --> chat_recording
config_manager --> telemetry_service
core_pkg --> message_bus : "事件通信"

' ===============================
' 连接关系 - 外部系统
' ===============================
gemini_client --> gemini_api : "AI API调用"
web_search_tool --> google_search_api : "搜索请求"
oauth_handler --> google_oauth : "OAuth认证"
auth_provider --> vertex_ai : "Vertex AI认证"
mcp_client_manager --> mcp_servers : "MCP协议通信"
sandbox_manager --> docker : "容器执行"
sandbox_manager --> podman : "容器执行"
sandbox_manager --> seatbelt : "macOS沙箱"
vscode_extension --> vscode : "IDE集成"
git_service --> git_repo : "Git操作"
builtin_tools --> file_system : "文件操作"
a2a_pkg --> gcs : "文件存储"

' ===============================
' 连接关系 - 数据存储
' ===============================
config_manager --> config_files : "读写配置"
credential_storage --> credentials_store : "存储凭据"
chat_recording --> chat_history : "保存对话"
extension_manager --> extension_storage : "管理扩展"
builtin_tools --> cache_storage : "缓存数据"

' ===============================
' 用户交互流程标注
' ===============================
note top of cli_pkg
  **用户界面层**
  • React + Ink 终端UI
  • 主题系统和键盘快捷键
  • 实时流式内容渲染
  • Vim模式支持
end note

note top of core_pkg
  **核心业务逻辑层**
  • Gemini AI客户端
  • 工具系统管理
  • 多层配置系统
  • 认证和安全管理
end note

note top of tools_pkg
  **工具执行层**
  • 20+ 内置工具
  • MCP协议支持
  • 自定义工具API
  • 沙箱安全执行
end note

note top of services_pkg
  **基础服务层**
  • 文件发现和Git集成
  • Shell执行服务
  • 遥测和日志记录
  • 事件总线通信
end note

note bottom of external_systems
  **外部系统集成**
  • Google AI和云服务
  • MCP生态系统
  • 容器运行时
  • 开发工具集成
end note

' ===============================
' 数据流标注
' ===============================
note right of gemini_client
  **核心数据流**
  1. 用户输入 → CLI处理
  2. 构造AI请求 → Gemini API
  3. 工具调用 → 沙箱执行
  4. 结果聚合 → 流式响应
  5. UI渲染 → 用户展示
end note

@enduml
```

# 启动准备和资源加载

## 项目结构

### 顶层目录结构

```
gemini-cli/
├── packages/                 # 核心包目录 (Monorepo架构)
│   ├── cli/                 # 用户界面包 - 终端交互和命令处理
│   ├── core/                # 核心逻辑包 - AI客户端和工具系统
│   ├── a2a-server/          # Agent-to-Agent服务器
│   ├── test-utils/          # 共享测试工具包
│   └── vscode-ide-companion/ # VSCode扩展
├── integration-tests/        # 端到端集成测试
├── docs/                    # 项目文档
├── scripts/                 # 构建和部署脚本
├── .gemini/                 # Gemini CLI配置文件
├── hello/                   # 示例项目和演示代码
└── third_party/             # 第三方依赖和补丁
```

# 用户一次任务调用跟踪
