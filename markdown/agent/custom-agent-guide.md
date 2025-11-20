# 自定义Agent开发指南

## 现状分析

目前系统中确实**只有一个内置agent**：`CodebaseInvestigatorAgent`。从代码分析可以看出，这是一个经过精心设计的专门用于代码库分析的agent。

### 当前Agent概览

```typescript
// packages/core/src/agents/codebase-investigator.ts
export const CodebaseInvestigatorAgent: AgentDefinition<
  typeof CodebaseInvestigationReportSchema
> = {
  name: 'codebase_investigator',
  displayName: 'Codebase Investigator Agent',
  description: '专门用于代码库分析、架构映射和理解系统级依赖的工具',
  // ... 其他配置
};
```

## 系统设计哲学

### 为什么只有一个Agent？

1. **专门化优于通用化**: 每个agent都针对特定任务高度优化
2. **质量优于数量**: 一个精心打造的agent胜过多个平庸的agent
3. **扩展性设计**: 架构支持轻松添加新agent，但目前专注于核心功能

### 配置驱动的启用机制

```typescript
// packages/core/src/config/config.ts
export interface CodebaseInvestigatorSettings {
  enabled?: boolean; // 是否启用该agent
  maxNumTurns?: number; // 最大轮次
  maxTimeMinutes?: number; // 最大执行时间
  thinkingBudget?: number; // 思考预算
  model?: string; // 使用的模型
}
```

## 如何自定义Agent

### 方法一：创建新的Agent定义

#### 1. 定义输出Schema

```typescript
// my-custom-agent.ts
import { z } from 'zod';

const MyCustomReportSchema = z.object({
  summary: z.string().describe('任务总结'),
  results: z.array(z.string()).describe('执行结果列表'),
  recommendations: z.array(z.string()).describe('建议列表'),
});
```

#### 2. 创建Agent定义

```typescript
import type { AgentDefinition } from './types.js';
import { DEFAULT_GEMINI_MODEL } from '../config/models.js';
import {
  READ_FILE_TOOL_NAME,
  WRITE_FILE_TOOL_NAME,
  BASH_TOOL_NAME,
} from '../tools/tool-names.js';

export const MyCustomAgent: AgentDefinition<typeof MyCustomReportSchema> = {
  name: 'my_custom_agent',
  displayName: 'My Custom Agent',
  description: '自定义agent的描述，说明它的功能和用途',

  inputConfig: {
    inputs: {
      task: {
        description: '要执行的任务描述',
        type: 'string',
        required: true,
      },
      target: {
        description: '目标文件或目录',
        type: 'string',
        required: false,
      },
    },
  },

  outputConfig: {
    outputName: 'report',
    description: '执行结果报告',
    schema: MyCustomReportSchema,
  },

  processOutput: (output) => {
    return `任务完成！\n总结: ${output.summary}\n结果: ${output.results.join(', ')}`;
  },

  modelConfig: {
    model: DEFAULT_GEMINI_MODEL,
    temp: 0.2,
    top_p: 0.95,
    thinkingBudget: -1,
  },

  runConfig: {
    max_time_minutes: 10,
    max_turns: 20,
  },

  toolConfig: {
    tools: [READ_FILE_TOOL_NAME, WRITE_FILE_TOOL_NAME, BASH_TOOL_NAME],
  },

  promptConfig: {
    systemPrompt: `你是一个自定义AI助手，专门处理以下任务：
- 分析和处理文件
- 执行指定的操作
- 生成详细的报告

你必须：
1. 仔细理解用户的任务需求
2. 使用可用的工具完成任务
3. 生成结构化的报告
4. 在完成时调用 complete_task 工具`,

    query: `请执行以下任务：
<task>
\${task}
</task>

目标：\${target}`,
  },
};
```

#### 3. 添加配置支持

```typescript
// config/config.ts 中添加
export interface MyCustomAgentSettings {
  enabled?: boolean;
  maxNumTurns?: number;
  maxTimeMinutes?: number;
  model?: string;
}

// 在 GeminiCLIConfig 接口中添加
export interface GeminiCLIConfig {
  // ... 其他配置
  myCustomAgentSettings?: MyCustomAgentSettings;
}
```

#### 4. 在Registry中注册

```typescript
// registry.ts 中修改 loadBuiltInAgents 方法
private loadBuiltInAgents(): void {
  // 现有的 CodebaseInvestigator 注册逻辑
  const investigatorSettings = this.config.getCodebaseInvestigatorSettings();
  if (investigatorSettings?.enabled) {
    // ... 现有代码
  }

  // 添加新的agent注册
  const myCustomSettings = this.config.getMyCustomAgentSettings();
  if (myCustomSettings?.enabled) {
    const agentDef = {
      ...MyCustomAgent,
      modelConfig: {
        ...MyCustomAgent.modelConfig,
        model: myCustomSettings.model ?? MyCustomAgent.modelConfig.model,
      },
      runConfig: {
        ...MyCustomAgent.runConfig,
        max_time_minutes:
          myCustomSettings.maxTimeMinutes ??
          MyCustomAgent.runConfig.max_time_minutes,
        max_turns:
          myCustomSettings.maxNumTurns ??
          MyCustomAgent.runConfig.max_turns,
      },
    };
    this.registerAgent(agentDef);
  }
}
```

### 方法二：扩展现有Agent

#### 1. 基于现有Agent创建变体

```typescript
export const CodeAnalysisAgent: AgentDefinition = {
  ...CodebaseInvestigatorAgent,
  name: 'code_analysis_agent',
  displayName: 'Code Analysis Agent',
  description: '专门用于代码质量分析和改进建议',

  // 覆盖特定配置
  promptConfig: {
    ...CodebaseInvestigatorAgent.promptConfig,
    systemPrompt: `你是代码质量分析师...`, // 自定义提示
  },

  runConfig: {
    ...CodebaseInvestigatorAgent.runConfig,
    max_time_minutes: 15, // 更长的执行时间
  },
};
```

### 方法三：动态Agent加载

#### 1. 通过扩展系统加载

```typescript
// 在扩展中定义agent
// extensions/my-extension/agents/custom-agent.ts
export const extension = {
  agents: [
    {
      definition: MyCustomAgent,
      settings: {
        enabled: true,
        maxTimeMinutes: 5,
      },
    },
  ],
};
```

#### 2. 运行时注册

```typescript
// 动态注册agent
const registry = await config.getAgentRegistry();
registry.registerAgent(MyCustomAgent);
```

## Agent开发最佳实践

### 1. 设计原则

- **单一职责**: 每个agent专注于一个特定领域
- **类型安全**: 使用Zod Schema确保输入输出类型安全
- **工具安全**: 只使用非交互式工具，确保子agent安全运行
- **错误处理**: 提供详细的错误信息和恢复机制

### 2. 性能优化

```typescript
// 合理设置执行限制
runConfig: {
  max_time_minutes: 5,    // 避免无限执行
  max_turns: 10,          // 限制对话轮次
},

// 选择合适的模型
modelConfig: {
  model: 'gemini-1.5-flash', // 快速任务使用flash
  temp: 0.1,                 // 低温度确保一致性
  thinkingBudget: 100,       // 限制思考预算
},
```

### 3. 提示工程

```typescript
promptConfig: {
  systemPrompt: `
角色定义: 明确agent的身份和职责
任务描述: 详细说明要完成的任务
工作流程: 提供清晰的执行步骤
输出要求: 明确指定输出格式和内容
约束条件: 设置安全和质量约束
`,

  query: `使用模板变量: \${variable_name}`,
},
```

### 4. 工具选择

```typescript
toolConfig: {
  tools: [
    // 只读工具（安全）
    'ls',
    'read_file',
    'grep',
    'glob',

    // 写入工具（谨慎使用）
    'write_file',
    'edit_file',

    // 执行工具（高风险，需要验证）
    'bash',
  ],
},
```

## 测试自定义Agent

### 1. 单元测试

```typescript
// my-custom-agent.test.ts
import { AgentExecutor } from './executor.js';
import { MyCustomAgent } from './my-custom-agent.js';

describe('MyCustomAgent', () => {
  it('should execute successfully', async () => {
    const executor = await AgentExecutor.create(MyCustomAgent, mockConfig);

    const result = await executor.run(
      { task: 'test task' },
      new AbortController().signal,
    );

    expect(result.terminate_reason).toBe('GOAL');
    expect(result.result).toContain('任务完成');
  });
});
```

### 2. 集成测试

```typescript
describe('Agent Integration', () => {
  it('should register and execute through registry', async () => {
    const registry = new AgentRegistry(config);
    await registry.initialize();

    const definition = registry.getDefinition('my_custom_agent');
    expect(definition).toBeDefined();
  });
});
```

## 部署和配置

### 1. 配置文件

```json
// .gemini/config.json
{
  "myCustomAgentSettings": {
    "enabled": true,
    "maxTimeMinutes": 10,
    "maxNumTurns": 15,
    "model": "gemini-1.5-pro"
  }
}
```

### 2. 环境变量

```bash
# 启用自定义agent
GEMINI_MY_CUSTOM_AGENT_ENABLED=true
GEMINI_MY_CUSTOM_AGENT_MAX_TIME=10
```

## 总结

虽然当前系统只有一个`CodebaseInvestigatorAgent`，但架构设计充分支持扩展：

1. **类型安全的定义系统**: 通过`AgentDefinition`接口确保一致性
2. **配置驱动的管理**: 通过配置控制agent的启用和参数
3. **插件化架构**: 支持动态加载和注册新agent
4. **完善的工具生态**: 丰富的工具支持各种任务需求

开发者可以根据具体需求，选择合适的方法来创建和部署自定义agent，从而扩展系统的能力边界。
