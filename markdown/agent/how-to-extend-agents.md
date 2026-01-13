# 如何扩展 Gemini CLI Agent

基于对 `DelegateToAgentTool` 和 `AgentRegistry`
的分析，扩展自定义 Agent 是完全可行的，并且系统提供了两种层级的扩展方式：**配置级扩展（TOML）**
和 **代码级扩展（TypeScript）**。

## 1. 方式一：使用 TOML 配置扩展（推荐）

这是最简单、最快捷的扩展方式，无需修改任何核心代码，只需在特定目录下添加配置文件即可。适用于通过 Prompt
Engineering 和组合现有工具来解决特定任务的场景。

### 步骤

1.  **创建目录**:
    - **项目级 Agent**: 在当前项目的根目录下创建 `.gemini/agents/` 文件夹。
    - **用户级 Agent**: 在你的用户主目录下创建 `~/.gemini/agents/`
      文件夹（适用于所有项目）。

2.  **创建 TOML 文件**: 在该目录下创建一个以 `.toml` 结尾的文件，例如
    `bug-fixer.toml`。

### 示例：创建一个“Bug 修复专家” Agent

创建文件 `.gemini/agents/bug-fixer.toml`：

```toml
# Agent 的唯一标识符，调用时使用
name = "bug_fixer"
# 对人类友好的显示名称
display_name = "Bug Fixer Specialist"
# 描述 Agent 的功能，这对于主 Agent 决定是否调用它至关重要
description = "A specialized agent for analyzing and fixing bugs based on error logs and user descriptions."

[prompts]
# 系统提示词，定义 Agent 的角色和行为
system_prompt = """
You are an expert software debugger. Your goal is to analyze bug reports, locate the issue in the code, and propose a fix.
Follow these steps:
1. Understand the user's bug report.
2. Use available tools to explore the codebase and reproduce the issue mentally.
3. Propose a solution.
"""

# 可选：定义任务启动时的默认查询模板
# query = "Fix the bug described as: ${query}"

[model]
# 可选：指定使用的模型，默认继承主配置
model = "gemini-2.0-flash-exp"
temperature = 0.2

[run]
# 限制运行轮数，防止死循环
max_turns = 10
timeout_mins = 5

# 指定 Agent 可使用的工具列表
# 注意：子 Agent 目前不能使用 delegate_to_agent (防止递归)
tools = [
  "read_file",
  "search_file_content",
  "ls",
  "run_shell_command"
]
```

### 限制

- 输入参数默认为单一的 `query` 字符串。
- 输出结果通常是文本对话，无法像代码级扩展那样强制返回严格的 JSON 结构。

---

## 2. 方式二：使用 TypeScript 代码扩展（高级）

如果你需要更强的类型控制、自定义的输入/输出 Schema（如 `CodebaseInvestigator`
返回的 JSON 报告），或者需要集成复杂的逻辑，则需要直接修改源码。

### 步骤

1.  **定义输出 Schema (Zod)** 在 `packages/core/src/agents/`
    下创建你的 Agent 文件，例如 `my-custom-agent.ts`。

2.  **实现 Agent 定义** 实现 `LocalAgentDefinition` 接口。

3.  **注册 Agent** 在 `packages/core/src/agents/registry.ts`
    中注册你的新 Agent。

### 代码示例

**`packages/core/src/agents/security-auditor.ts`**:

```typescript
import { z } from 'zod';
import { LocalAgentDefinition } from './types.js';
import { READ_FILE_TOOL_NAME, GLOB_TOOL_NAME } from '../tools/tool-names.js';
import { DEFAULT_GEMINI_MODEL } from '../config/models.js';

// 1. 定义输出 Schema
const SecurityReportSchema = z.object({
  vulnerabilities: z.array(
    z.object({
      severity: z.enum(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']),
      filePath: z.string(),
      description: z.string(),
      suggestedFix: z.string(),
    }),
  ),
  summary: z.string(),
});

// 2. 定义 Agent
export const SecurityAuditorAgent: LocalAgentDefinition<
  typeof SecurityReportSchema
> = {
  name: 'security_auditor',
  kind: 'local',
  description: 'Scans the codebase for common security vulnerabilities.',

  // 定义输入参数，主 Agent 调用时必须提供这些
  inputConfig: {
    inputs: {
      targetDir: {
        description: 'The directory to audit',
        type: 'string',
        required: true,
      },
    },
  },

  // 定义输出配置
  outputConfig: {
    outputName: 'security_report',
    description: 'A structured security audit report.',
    schema: SecurityReportSchema,
  },

  // 将结构化输出转换为字符串的逻辑
  processOutput: (output) => JSON.stringify(output, null, 2),

  modelConfig: {
    model: DEFAULT_GEMINI_MODEL,
    temp: 0.1,
    top_p: 0.95,
  },

  runConfig: {
    max_time_minutes: 10,
    max_turns: 20,
  },

  toolConfig: {
    tools: [READ_FILE_TOOL_NAME, GLOB_TOOL_NAME],
  },

  promptConfig: {
    // ${targetDir} 会被自动替换为输入参数的值
    query: 'Audit the directory: ${targetDir}',
    systemPrompt: `You are a security auditing agent. 
    Analyze the code for SQL injection, XSS, and hardcoded secrets.
    Return your findings in the specified JSON format.`,
  },
};
```

**`packages/core/src/agents/registry.ts`**:

```typescript
// ... imports
import { SecurityAuditorAgent } from './security-auditor.js';

// ... inside loadBuiltInAgents() method
private loadBuiltInAgents(): void {
  // ... existing agents

  // 3. 注册新 Agent
  this.registerLocalAgent(SecurityAuditorAgent);
}
```

## 总结

- **对于 90% 的场景**：请使用 **TOML**
  方式。它灵活、无需重新编译 CLI，且易于分享。
- **对于核心功能开发**：如果需要 Agent 返回机器可读的结构化数据供其他 Agent 消费，请使用
  **TypeScript** 方式。
