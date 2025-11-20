# Agent智能选择与任务路由系统设计

## 当前系统分析

### 现状：静态注册机制

```typescript
// packages/core/src/config/config.ts:1351
if (this.getCodebaseInvestigatorSettings().enabled) {
  const definition = this.agentRegistry.getDefinition('codebase_investigator');
  if (definition) {
    const wrapper = new SubagentToolWrapper(definition, this);
    registry.registerTool(wrapper); // ← 硬编码注册单个agent
  }
}
```

**问题**：

- 硬编码agent名称
- 无智能选择机制
- 手动决策依赖用户

## 解决方案：智能Agent选择系统

### 方案一：基于任务描述的智能路由器

#### 1. Agent元数据扩展

```typescript
// agents/types.ts - 扩展AgentDefinition
export interface AgentDefinition<TOutput extends z.ZodTypeAny = z.ZodUnknown> {
  // ... 现有字段

  // 新增智能选择字段
  capabilities: AgentCapabilities;
  priority: number; // 优先级 (1-10)
  confidence?: (task: string) => number; // 置信度计算函数
}

export interface AgentCapabilities {
  domains: string[]; // 领域：['codebase', 'documentation', 'testing']
  skills: string[]; // 技能：['analysis', 'generation', 'refactoring']
  keywords: string[]; // 关键词：['debug', 'architecture', 'performance']
  taskTypes: TaskType[]; // 任务类型
  fileTypes?: string[]; // 支持的文件类型：['.ts', '.js', '.py']
  complexity: ComplexityLevel; // 复杂度等级
}

export enum TaskType {
  ANALYSIS = 'analysis',
  GENERATION = 'generation',
  DEBUGGING = 'debugging',
  REFACTORING = 'refactoring',
  DOCUMENTATION = 'documentation',
  TESTING = 'testing',
}

export enum ComplexityLevel {
  SIMPLE = 'simple',
  MEDIUM = 'medium',
  COMPLEX = 'complex',
}
```

#### 2. 智能任务路由器

```typescript
// agents/task-router.ts
export class TaskRouter {
  constructor(
    private agentRegistry: AgentRegistry,
    private config: Config,
  ) {}

  /**
   * 根据任务描述智能选择最合适的Agent
   */
  async selectAgent(
    taskDescription: string,
    context?: TaskContext,
  ): Promise<AgentSelectionResult> {
    const availableAgents = this.getEnabledAgents();

    if (availableAgents.length === 0) {
      throw new Error('No enabled agents available');
    }

    if (availableAgents.length === 1) {
      return {
        agent: availableAgents[0],
        confidence: 1.0,
        reason: 'Only available agent',
      };
    }

    // 多Agent智能选择
    const candidates = await this.scoreAgents(
      taskDescription,
      availableAgents,
      context,
    );
    const bestMatch = this.selectBestMatch(candidates);

    return bestMatch;
  }

  /**
   * 为每个Agent计算匹配分数
   */
  private async scoreAgents(
    task: string,
    agents: AgentDefinition[],
    context?: TaskContext,
  ): Promise<AgentCandidate[]> {
    const results: AgentCandidate[] = [];

    for (const agent of agents) {
      const score = await this.calculateScore(task, agent, context);
      results.push({
        agent,
        score,
        breakdown: score.breakdown,
      });
    }

    return results.sort((a, b) => b.score.total - a.score.total);
  }

  /**
   * 多维度评分算法
   */
  private async calculateScore(
    task: string,
    agent: AgentDefinition,
    context?: TaskContext,
  ): Promise<AgentScore> {
    const weights = this.config.getAgentSelectionWeights();

    // 1. 关键词匹配分数
    const keywordScore = this.calculateKeywordScore(
      task,
      agent.capabilities.keywords,
    );

    // 2. 领域匹配分数
    const domainScore = this.calculateDomainScore(
      task,
      agent.capabilities.domains,
    );

    // 3. 任务类型匹配分数
    const taskTypeScore = this.calculateTaskTypeScore(
      task,
      agent.capabilities.taskTypes,
    );

    // 4. 文件类型匹配分数
    const fileTypeScore = context?.files
      ? this.calculateFileTypeScore(context.files, agent.capabilities.fileTypes)
      : 0;

    // 5. 复杂度匹配分数
    const complexityScore = this.calculateComplexityScore(
      task,
      agent.capabilities.complexity,
    );

    // 6. 自定义置信度函数
    const customScore = agent.confidence ? agent.confidence(task) : 0;

    // 7. 优先级分数
    const priorityScore = agent.priority / 10;

    const total =
      (keywordScore * weights.keyword +
        domainScore * weights.domain +
        taskTypeScore * weights.taskType +
        fileTypeScore * weights.fileType +
        complexityScore * weights.complexity +
        customScore * weights.custom +
        priorityScore * weights.priority) /
      Object.values(weights).reduce((a, b) => a + b, 0);

    return {
      total,
      breakdown: {
        keyword: keywordScore,
        domain: domainScore,
        taskType: taskTypeScore,
        fileType: fileTypeScore,
        complexity: complexityScore,
        custom: customScore,
        priority: priorityScore,
      },
    };
  }

  /**
   * 选择最佳匹配Agent
   */
  private selectBestMatch(candidates: AgentCandidate[]): AgentSelectionResult {
    const best = candidates[0];
    const threshold = this.config.getAgentSelectionThreshold();

    if (best.score.total < threshold) {
      // 分数太低，提供建议
      return {
        agent: best.agent,
        confidence: best.score.total,
        reason: `Best match but low confidence (${best.score.total.toFixed(2)})`,
        alternatives: candidates.slice(1, 3),
        suggestion: 'Consider being more specific about your task requirements',
      };
    }

    // 检查是否有多个高分Agent（分数接近）
    const closeMatches = candidates.filter(
      (c) => Math.abs(c.score.total - best.score.total) < 0.1,
    );

    if (closeMatches.length > 1) {
      return {
        agent: best.agent,
        confidence: best.score.total,
        reason: 'Best match among close alternatives',
        alternatives: closeMatches.slice(1),
        suggestion: 'Multiple agents could handle this task effectively',
      };
    }

    return {
      agent: best.agent,
      confidence: best.score.total,
      reason: 'Clear best match',
    };
  }
}

// 类型定义
interface TaskContext {
  files?: string[];
  workingDirectory?: string;
  previousResults?: any[];
  userPreferences?: UserPreferences;
}

interface AgentSelectionResult {
  agent: AgentDefinition;
  confidence: number;
  reason: string;
  alternatives?: AgentCandidate[];
  suggestion?: string;
}

interface AgentCandidate {
  agent: AgentDefinition;
  score: AgentScore;
  breakdown: ScoreBreakdown;
}

interface AgentScore {
  total: number;
  breakdown: ScoreBreakdown;
}

interface ScoreBreakdown {
  keyword: number;
  domain: number;
  taskType: number;
  fileType: number;
  complexity: number;
  custom: number;
  priority: number;
}
```

#### 3. 增强的Agent定义示例

```typescript
// agents/codebase-investigator.ts - 增强版
export const CodebaseInvestigatorAgent: AgentDefinition<
  typeof CodebaseInvestigationReportSchema
> = {
  // ... 现有配置

  // 新增智能选择配置
  capabilities: {
    domains: ['codebase', 'architecture', 'analysis'],
    skills: ['investigation', 'mapping', 'dependency-analysis'],
    keywords: [
      'analyze',
      'investigate',
      'architecture',
      'dependencies',
      'structure',
      'codebase',
      'files',
      'modules',
      'understand',
      'explore',
      'find',
      'search',
      'examine',
    ],
    taskTypes: [TaskType.ANALYSIS],
    fileTypes: ['.ts', '.js', '.py', '.java', '.go', '.rs'],
    complexity: ComplexityLevel.COMPLEX,
  },

  priority: 8, // 高优先级

  confidence: (task: string) => {
    // 自定义置信度计算
    const codebaseKeywords = ['code', 'file', 'function', 'class', 'module'];
    const analysisKeywords = [
      'analyze',
      'understand',
      'investigate',
      'explore',
    ];

    let score = 0;
    const taskLower = task.toLowerCase();

    codebaseKeywords.forEach((keyword) => {
      if (taskLower.includes(keyword)) score += 0.2;
    });

    analysisKeywords.forEach((keyword) => {
      if (taskLower.includes(keyword)) score += 0.15;
    });

    return Math.min(score, 1.0);
  },
};

// agents/documentation-agent.ts - 新的文档Agent示例
export const DocumentationAgent: AgentDefinition<
  typeof DocumentationReportSchema
> = {
  name: 'documentation_agent',
  displayName: 'Documentation Agent',
  description: '专门用于生成和维护项目文档',

  capabilities: {
    domains: ['documentation', 'writing', 'markdown'],
    skills: ['generation', 'formatting', 'structuring'],
    keywords: [
      'document',
      'readme',
      'docs',
      'markdown',
      'write',
      'guide',
      'tutorial',
      'explanation',
      'manual',
    ],
    taskTypes: [TaskType.GENERATION, TaskType.DOCUMENTATION],
    fileTypes: ['.md', '.rst', '.txt'],
    complexity: ComplexityLevel.MEDIUM,
  },

  priority: 6,

  confidence: (task: string) => {
    const docKeywords = ['document', 'readme', 'markdown', 'guide', 'manual'];
    return docKeywords.some((keyword) => task.toLowerCase().includes(keyword))
      ? 0.9
      : 0.1;
  },

  // ... 其他配置
};
```

#### 4. Task工具增强

```typescript
// tools/task-tool.ts
export class TaskTool extends BaseDeclarativeTool<TaskInput, ToolResult> {
  constructor(
    private taskRouter: TaskRouter,
    private config: Config,
  ) {
    super(
      'task',
      'Task',
      'Execute tasks using the most appropriate AI agent',
      Kind.Think,
      {
        type: 'object',
        properties: {
          description: {
            type: 'string',
            description: 'Detailed description of the task to be performed',
          },
          agent: {
            type: 'string',
            description: 'Optional: Specify a particular agent to use',
          },
          context: {
            type: 'object',
            description: 'Optional: Additional context for agent selection',
            properties: {
              files: {
                type: 'array',
                items: { type: 'string' },
                description: 'Relevant files for the task',
              },
              workingDirectory: {
                type: 'string',
                description: 'Working directory for the task',
              },
            },
          },
        },
        required: ['description'],
      },
    );
  }

  protected createInvocation(
    params: TaskInput,
  ): ToolInvocation<TaskInput, ToolResult> {
    return new TaskInvocation(params, this.taskRouter, this.config);
  }
}

export class TaskInvocation extends BaseToolInvocation<TaskInput, ToolResult> {
  constructor(
    params: TaskInput,
    private taskRouter: TaskRouter,
    private config: Config,
  ) {
    super(params);
  }

  async execute(
    signal: AbortSignal,
    updateOutput?: (output: string) => void,
  ): Promise<ToolResult> {
    try {
      updateOutput?.('🔍 Selecting the best agent for your task...\n');

      // 智能选择Agent
      const selection = await this.taskRouter.selectAgent(
        this.params.description,
        this.params.context,
      );

      updateOutput?.(
        `🤖 Selected: ${selection.agent.displayName}\n` +
          `📊 Confidence: ${(selection.confidence * 100).toFixed(1)}%\n` +
          `💭 Reason: ${selection.reason}\n\n`,
      );

      // 如果有建议，显示给用户
      if (selection.suggestion) {
        updateOutput?.(`💡 Tip: ${selection.suggestion}\n\n`);
      }

      // 如果有替代选择，显示给用户
      if (selection.alternatives && selection.alternatives.length > 0) {
        updateOutput?.('🔄 Other capable agents:\n');
        selection.alternatives.forEach((alt) => {
          updateOutput?.(
            `   • ${alt.agent.displayName} (${(alt.score.total * 100).toFixed(1)}%)\n`,
          );
        });
        updateOutput?.('\n');
      }

      // 执行选定的Agent
      const agentWrapper = new SubagentInvocation(
        { objective: this.params.description },
        selection.agent,
        this.config,
      );

      const result = await agentWrapper.execute(signal, updateOutput);

      return {
        llmContent: [
          {
            text: `Task completed by ${selection.agent.displayName}:\n${result.llmContent}`,
          },
        ],
        returnDisplay: result.returnDisplay,
      };
    } catch (error) {
      return {
        llmContent: `Task execution failed: ${error}`,
        returnDisplay: `❌ Task failed: ${error}`,
        error: {
          message: String(error),
          type: ToolErrorType.EXECUTION_FAILED,
        },
      };
    }
  }
}
```

### 方案二：配置驱动的Agent选择器

#### 1. 配置文件定义

```json
// .gemini/agents.json
{
  "selectionStrategy": "auto", // "auto" | "manual" | "prompt"
  "defaultAgent": "codebase_investigator",
  "selectionWeights": {
    "keyword": 0.3,
    "domain": 0.25,
    "taskType": 0.2,
    "fileType": 0.1,
    "complexity": 0.1,
    "priority": 0.05
  },
  "confidenceThreshold": 0.6,
  "agents": {
    "codebase_investigator": {
      "enabled": true,
      "priority": 8,
      "domains": ["codebase", "analysis"],
      "triggers": ["analyze", "investigate", "understand", "explore"]
    },
    "documentation_agent": {
      "enabled": true,
      "priority": 6,
      "domains": ["documentation", "writing"],
      "triggers": ["document", "readme", "guide", "manual"]
    },
    "testing_agent": {
      "enabled": true,
      "priority": 7,
      "domains": ["testing", "quality"],
      "triggers": ["test", "spec", "verify", "validate"]
    }
  }
}
```

#### 2. 简化的选择器实现

```typescript
// agents/simple-selector.ts
export class SimpleAgentSelector {
  constructor(private config: Config) {}

  selectAgent(taskDescription: string): string | null {
    const strategy = this.config.getAgentSelectionStrategy();

    switch (strategy) {
      case 'manual':
        return null; // 让用户手动选择

      case 'prompt':
        return this.promptUserForSelection(taskDescription);

      case 'auto':
      default:
        return this.autoSelectAgent(taskDescription);
    }
  }

  private autoSelectAgent(task: string): string {
    const agents = this.config.getEnabledAgents();
    const taskLower = task.toLowerCase();

    // 简单的关键词匹配
    for (const [agentName, config] of Object.entries(agents)) {
      if (config.triggers.some((trigger) => taskLower.includes(trigger))) {
        return agentName;
      }
    }

    // 回退到默认Agent
    return this.config.getDefaultAgent();
  }

  private promptUserForSelection(task: string): string {
    // 实现用户交互式选择
    // 可以通过CLI提示或配置界面
    return this.config.getDefaultAgent();
  }
}
```

### 方案三：LLM驱动的Agent选择

```typescript
// agents/llm-selector.ts
export class LLMAgentSelector {
  constructor(
    private config: Config,
    private geminiChat: GeminiChat,
  ) {}

  async selectAgent(taskDescription: string): Promise<string> {
    const availableAgents = this.getAgentDescriptions();

    const prompt = `
Given the following task and available agents, select the most appropriate agent:

Task: "${taskDescription}"

Available agents:
${availableAgents
  .map((agent) => `- ${agent.name}: ${agent.description}`)
  .join('\n')}

Respond with only the agent name that best matches the task requirements.
    `;

    const response = await this.geminiChat.sendMessage(prompt);
    const selectedAgent = response.trim().toLowerCase();

    // 验证选择的Agent是否有效
    if (availableAgents.some((agent) => agent.name === selectedAgent)) {
      return selectedAgent;
    }

    // 回退到默认选择
    return this.config.getDefaultAgent();
  }
}
```

## 使用示例

### 场景1：智能自动选择

```bash
# 用户输入
task "分析这个项目的架构并找出依赖关系"

# 系统输出
🔍 Selecting the best agent for your task...
🤖 Selected: Codebase Investigator Agent
📊 Confidence: 95.2%
💭 Reason: High keyword match for 'analyze', 'architecture', 'dependencies'

# Agent执行任务...
```

### 场景2：多Agent竞争

```bash
# 用户输入
task "为这个函数写文档"

# 系统输出
🔍 Selecting the best agent for your task...
🤖 Selected: Documentation Agent
📊 Confidence: 87.3%
💭 Reason: Best match for documentation tasks
🔄 Other capable agents:
   • Codebase Investigator Agent (65.1%)

# Agent执行任务...
```

### 场景3：手动指定Agent

```bash
# 用户输入
task "分析代码质量" --agent=codebase_investigator

# 系统输出
🤖 Using specified agent: Codebase Investigator Agent
# Agent执行任务...
```

## 配置选项

```typescript
// config/agent-selection.ts
export interface AgentSelectionConfig {
  strategy: 'auto' | 'manual' | 'prompt' | 'llm';
  weights: SelectionWeights;
  threshold: number;
  defaultAgent: string;
  fallbackBehavior: 'useDefault' | 'askUser' | 'fail';
  showAlternatives: boolean;
  confirmSelection: boolean;
}

export interface SelectionWeights {
  keyword: number;
  domain: number;
  taskType: number;
  fileType: number;
  complexity: number;
  custom: number;
  priority: number;
}
```

## 总结

通过以上设计，我们可以实现：

1. **智能Agent选择** - 基于任务内容自动选择最合适的Agent
2. **多维度评分** - 考虑关键词、领域、任务类型等多个维度
3. **配置灵活性** - 支持自动、手动、提示等多种选择策略
4. **用户体验** - 显示选择理由和置信度，提供替代选项
5. **扩展性** - 轻松添加新Agent和新的选择标准

这样，当你有多个Agent时，系统就能智能地为不同任务选择最合适的Agent，而不需要用户手动指定！
