# Gemini CLI 多模型支持改造计划

## 🎯 **改造目标**

将 Gemini CLI 从单一 Google Gemini 模型支持改造为支持多个 AI 模型提供商的通用 AI
CLI 工具，包括：

- **OpenAI**: GPT-4o, GPT-4o-mini, GPT-3.5-turbo
- **Anthropic**: Claude-3.5-sonnet, Claude-3-haiku, Claude-3-opus
- **DeepSeek**: deepseek-chat, deepseek-coder
- **阿里云**: qwen-turbo, qwen-plus, qwen-max
- **百度**: ernie-bot-turbo, ernie-bot-4.0
- **字节跳动**: doubao-lite, doubao-pro
- **月之暗面**: moonshot-v1-8k, moonshot-v1-32k
- **智谱AI**: glm-4, glm-4-flash

## 🏗️ **现有架构分析**

### 当前核心组件

1. **ContentGenerator 接口** (`packages/core/src/core/contentGenerator.ts`)
   - 定义了 AI 模型交互的标准接口
   - 包含 `generateContent`, `generateContentStream`, `countTokens`,
     `embedContent` 方法
   - 当前只支持 Google GenAI 格式

2. **认证系统** (`packages/cli/src/config/auth.ts`)
   - 支持 OAuth、API Key、Vertex AI 三种认证方式
   - 专为 Google 服务设计

3. **配置系统** (`packages/cli/src/config/settingsSchema.ts`)
   - 硬编码了 Gemini 模型名称
   - 单一模型配置结构

4. **客户端实现** (`packages/core/src/core/client.ts`)
   - `GeminiClient` 直接依赖 Google GenAI SDK
   - 模型逻辑与业务逻辑耦合

## 🏛️ **新架构设计**

### 1. **提供商抽象层**

```typescript
// packages/core/src/providers/types.ts
export enum ProviderType {
  GOOGLE = 'google',
  OPENAI = 'openai',
  ANTHROPIC = 'anthropic',
  DEEPSEEK = 'deepseek',
  ALIBABA = 'alibaba',
  BAIDU = 'baidu',
  BYTEDANCE = 'bytedance',
  MOONSHOT = 'moonshot',
  ZHIPU = 'zhipu',
}

export interface ModelProvider {
  readonly type: ProviderType;
  readonly name: string;
  getSupportedModels(): ModelInfo[];
  createClient(config: ProviderConfig): ProviderClient;
  validateConfig(config: ProviderConfig): ValidationResult;
}

export interface ProviderClient extends ContentGenerator {
  provider: ProviderType;
  disconnect(): Promise<void>;
}

export interface ModelInfo {
  id: string;
  name: string;
  provider: ProviderType;
  capabilities: ModelCapabilities;
  pricing?: ModelPricing;
  limits: ModelLimits;
}
```

### 2. **统一配置系统**

```typescript
// packages/cli/src/config/modelConfig.ts
export interface MultiModelConfig {
  providers: Record<ProviderType, ProviderConfig>;
  defaultProvider: ProviderType;
  defaultModel: string;
  modelAliases: Record<string, ModelReference>;
  fallbackChain: ModelReference[];
}

export interface ProviderConfig {
  enabled: boolean;
  authType: string;
  apiKey?: string;
  apiUrl?: string;
  timeout?: number;
  retryConfig?: RetryConfig;
  customHeaders?: Record<string, string>;
}

export interface ModelReference {
  provider: ProviderType;
  modelId: string;
}
```

### 3. **消息格式统一**

```typescript
// packages/core/src/types/messages.ts
export interface UniversalMessage {
  role: 'system' | 'user' | 'assistant' | 'tool';
  content: string | MessageContent[];
  name?: string;
  toolCalls?: ToolCall[];
  toolCallId?: string;
}

export interface MessageAdapter {
  fromUniversal(message: UniversalMessage): any;
  toUniversal(message: any): UniversalMessage;
  adaptToolCall(toolCall: any): ToolCall;
  adaptToolResponse(response: any): ToolResponse;
}
```

## 📋 **详细实施计划**

### 阶段一：基础抽象层建设 (2-3周)

#### 1.1 创建提供商抽象接口 (3-4天)

**新建文件:**

```
packages/core/src/providers/
├── types.ts                    # 核心类型定义
├── base/
│   ├── BaseProvider.ts         # 提供商基类
│   └── BaseClient.ts           # 客户端基类
├── registry/
│   ├── ProviderRegistry.ts     # 提供商注册表
│   └── ModelRegistry.ts        # 模型注册表
└── adapters/
    ├── MessageAdapter.ts       # 消息格式适配器
    └── ResponseAdapter.ts      # 响应格式适配器
```

**关键代码:**

```typescript
// packages/core/src/providers/base/BaseProvider.ts
export abstract class BaseProvider implements ModelProvider {
  abstract readonly type: ProviderType;
  abstract readonly name: string;

  constructor(protected config: ProviderConfig) {}

  abstract getSupportedModels(): ModelInfo[];
  abstract createClient(config: ProviderConfig): ProviderClient;
  abstract validateConfig(config: ProviderConfig): ValidationResult;

  protected createHttpClient(baseURL: string): AxiosInstance {
    return axios.create({
      baseURL,
      timeout: this.config.timeout || 30000,
      headers: this.config.customHeaders || {},
    });
  }
}
```

#### 1.2 实现 Google Provider (2-3天)

**文件:**

```
packages/core/src/providers/google/
├── GoogleProvider.ts           # Google 提供商实现
├── GoogleClient.ts             # Google 客户端实现
├── GoogleMessageAdapter.ts     # Google 消息适配器
└── models.ts                   # Google 模型定义
```

**迁移现有逻辑:**

- 将现有的 `ContentGenerator` 实现迁移到 `GoogleClient`
- 保持现有认证逻辑不变
- 确保向后兼容

#### 1.3 创建统一的 ContentGenerator (1-2天)

```typescript
// packages/core/src/core/UniversalContentGenerator.ts
export class UniversalContentGenerator implements ContentGenerator {
  private providers = new Map<ProviderType, ProviderClient>();
  private currentProvider: ProviderType;

  constructor(private config: MultiModelConfig) {
    this.initializeProviders();
  }

  async generateContent(
    request: GenerateContentParameters,
    userPromptId: string,
  ): Promise<GenerateContentResponse> {
    const { provider, modelId } = this.resolveModel(request.model);
    const client = this.getClient(provider);

    // 转换请求格式
    const adaptedRequest = this.adaptRequest(request, provider);
    const response = await client.generateContent(adaptedRequest, userPromptId);

    // 转换响应格式
    return this.adaptResponse(response, provider);
  }
}
```

### 阶段二：主要提供商实现 (3-4周)

#### 2.1 OpenAI Provider (1周)

**文件结构:**

```
packages/core/src/providers/openai/
├── OpenAIProvider.ts
├── OpenAIClient.ts
├── OpenAIMessageAdapter.ts
├── models.ts
└── auth.ts
```

**核心功能:**

- 支持 GPT-4o, GPT-4o-mini, GPT-3.5-turbo
- API Key 认证
- 流式响应支持
- Function calling 支持
- 错误处理和重试机制

#### 2.2 Anthropic Provider (1周)

**文件结构:**

```
packages/core/src/providers/anthropic/
├── AnthropicProvider.ts
├── AnthropicClient.ts
├── AnthropicMessageAdapter.ts
├── models.ts
└── auth.ts
```

**核心功能:**

- 支持 Claude-3.5-sonnet, Claude-3-haiku, Claude-3-opus
- API Key 认证
- 消息格式转换 (Anthropic 使用不同的消息结构)
- 工具调用适配

#### 2.3 国产模型提供商 (2周)

**DeepSeek Provider:**

```typescript
// packages/core/src/providers/deepseek/DeepSeekProvider.ts
export class DeepSeekProvider extends BaseProvider {
  readonly type = ProviderType.DEEPSEEK;
  readonly name = 'DeepSeek';

  getSupportedModels(): ModelInfo[] {
    return [
      {
        id: 'deepseek-chat',
        name: 'DeepSeek Chat',
        provider: ProviderType.DEEPSEEK,
        capabilities: {
          maxTokens: 8192,
          supportsStreaming: true,
          supportsTools: true,
        },
        limits: { requestPerMinute: 60, tokensPerMinute: 10000 },
      },
      // ... 更多模型
    ];
  }
}
```

**类似实现:**

- 阿里云通义千问 Provider
- 百度文心一言 Provider
- 字节跳动豆包 Provider
- 月之暗面 Provider
- 智谱AI Provider

### 阶段三：配置系统改造 (1-2周)

#### 3.1 扩展设置模式 (3-4天)

**修改文件:** `packages/cli/src/config/settingsSchema.ts`

```typescript
// 新增多模型配置
export interface Settings {
  model: {
    // 兼容旧配置
    name?: string;

    // 新增多提供商配置
    providers?: {
      [key in ProviderType]?: {
        enabled: boolean;
        apiKey?: string;
        apiUrl?: string;
        timeout?: number;
        models?: {
          [modelId: string]: {
            enabled: boolean;
            displayName?: string;
            customConfig?: any;
          };
        };
      };
    };

    defaultProvider?: ProviderType;
    defaultModel?: string;

    // 模型别名系统
    aliases?: {
      [alias: string]: {
        provider: ProviderType;
        model: string;
      };
    };

    // 后备模型链
    fallbackChain?: Array<{
      provider: ProviderType;
      model: string;
      condition?: 'rate_limit' | 'error' | 'timeout';
    }>;
  };
}
```

#### 3.2 配置迁移系统 (2-3天)

```typescript
// packages/cli/src/config/migration/multiModelMigration.ts
export function migrateToMultiModel(oldSettings: any): Settings {
  const newSettings = { ...oldSettings };

  // 迁移旧的模型配置
  if (oldSettings.model?.name) {
    newSettings.model = {
      ...oldSettings.model,
      providers: {
        google: {
          enabled: true,
          models: {
            [oldSettings.model.name]: { enabled: true },
          },
        },
      },
      defaultProvider: ProviderType.GOOGLE,
      defaultModel: oldSettings.model.name,
    };
  }

  return newSettings;
}
```

### 阶段四：认证系统扩展 (1周)

#### 4.1 扩展认证类型 (2-3天)

**修改文件:** `packages/core/src/core/contentGenerator.ts`

```typescript
export enum AuthType {
  // 现有的
  LOGIN_WITH_GOOGLE = 'oauth-personal',
  USE_GEMINI = 'gemini-api-key',
  USE_VERTEX_AI = 'vertex-ai',
  CLOUD_SHELL = 'cloud-shell',

  // 新增的
  OPENAI_API_KEY = 'openai-api-key',
  ANTHROPIC_API_KEY = 'anthropic-api-key',
  DEEPSEEK_API_KEY = 'deepseek-api-key',
  ALIBABA_API_KEY = 'alibaba-api-key',
  BAIDU_API_KEY = 'baidu-api-key',
  BYTEDANCE_API_KEY = 'bytedance-api-key',
  MOONSHOT_API_KEY = 'moonshot-api-key',
  ZHIPU_API_KEY = 'zhipu-api-key',
}
```

#### 4.2 多提供商认证管理 (2-3天)

```typescript
// packages/core/src/auth/MultiProviderAuthManager.ts
export class MultiProviderAuthManager {
  private authStrategies = new Map<ProviderType, AuthStrategy>();

  async authenticate(provider: ProviderType): Promise<AuthResult> {
    const strategy = this.authStrategies.get(provider);
    if (!strategy) {
      throw new Error(`No auth strategy for provider: ${provider}`);
    }

    return await strategy.authenticate();
  }

  async validateCredentials(provider: ProviderType): Promise<boolean> {
    const strategy = this.authStrategies.get(provider);
    return strategy ? await strategy.validate() : false;
  }
}
```

### 阶段五：UI 系统改造 (1-2周)

#### 5.1 模型选择器组件 (3-4天)

**新建文件:** `packages/cli/src/ui/components/ModelSelector.tsx`

```typescript
export interface ModelSelectorProps {
  availableModels: ModelInfo[];
  currentModel?: ModelReference;
  onModelChange: (model: ModelReference) => void;
  groupByProvider?: boolean;
}

export function ModelSelector({
  availableModels,
  currentModel,
  onModelChange,
  groupByProvider = true
}: ModelSelectorProps) {
  const groupedModels = groupByProvider
    ? groupModelsByProvider(availableModels)
    : { all: availableModels };

  return (
    <Box flexDirection="column">
      <Text bold>Select Model:</Text>
      {Object.entries(groupedModels).map(([provider, models]) => (
        <Box key={provider} flexDirection="column" marginTop={1}>
          {groupByProvider && <Text color="cyan">{provider.toUpperCase()}</Text>}
          <RadioButtonSelect
            items={models.map(model => ({
              label: `${model.name} (${model.id})`,
              value: { provider: model.provider, modelId: model.id },
              key: model.id
            }))}
            onSelect={onModelChange}
          />
        </Box>
      ))}
    </Box>
  );
}
```

#### 5.2 认证对话框扩展 (2-3天)

**修改文件:** `packages/cli/src/ui/auth/AuthDialog.tsx`

```typescript
// 扩展认证选项
const getAuthItems = (enabledProviders: ProviderType[]) => {
  const items = [];

  // Google 认证选项
  if (enabledProviders.includes(ProviderType.GOOGLE)) {
    items.push(
      { label: 'Login with Google', value: AuthType.LOGIN_WITH_GOOGLE },
      { label: 'Use Gemini API Key', value: AuthType.USE_GEMINI },
      { label: 'Vertex AI', value: AuthType.USE_VERTEX_AI },
    );
  }

  // OpenAI 认证选项
  if (enabledProviders.includes(ProviderType.OPENAI)) {
    items.push({ label: 'OpenAI API Key', value: AuthType.OPENAI_API_KEY });
  }

  // 其他提供商...

  return items;
};
```

#### 5.3 多提供商状态显示 (1-2天)

```typescript
// packages/cli/src/ui/components/ProviderStatus.tsx
export function ProviderStatus({ providers, currentProvider }: ProviderStatusProps) {
  return (
    <Box flexDirection="row" gap={2}>
      {providers.map(provider => (
        <Box key={provider.type} flexDirection="row" alignItems="center">
          <Text color={provider.type === currentProvider ? 'green' : 'gray'}>
            ●
          </Text>
          <Text>{provider.name}</Text>
          {provider.hasValidAuth && <Text color="green">✓</Text>}
        </Box>
      ))}
    </Box>
  );
}
```

### 阶段六：命令行接口扩展 (3-4天)

#### 6.1 模型管理命令

```bash
# 列出所有可用模型
gemini models list

# 按提供商分组显示
gemini models list --group-by-provider

# 设置默认模型
gemini models set-default openai/gpt-4o

# 添加模型别名
gemini models alias add gpt4 openai/gpt-4o
gemini models alias add claude anthropic/claude-3.5-sonnet

# 测试模型连接
gemini models test openai/gpt-4o
```

#### 6.2 提供商管理命令

```bash
# 列出所有提供商
gemini providers list

# 启用/禁用提供商
gemini providers enable openai
gemini providers disable deepseek

# 配置提供商
gemini providers config openai --api-key sk-xxx
gemini providers config deepseek --api-url https://api.deepseek.com
```

### 阶段七：测试和文档 (1周)

#### 7.1 单元测试 (2-3天)

**测试覆盖:**

- 各个提供商的客户端实现
- 消息格式适配器
- 配置迁移逻辑
- 认证系统

#### 7.2 集成测试 (2-3天)

**测试场景:**

- 多提供商切换
- 后备模型链
- 认证流程
- 配置兼容性

#### 7.3 文档更新 (1-2天)

**文档内容:**

- 多模型配置指南
- 提供商认证设置
- 模型别名使用
- 故障排除指南

## 🔧 **配置示例**

### 完整配置文件示例

```json
{
  "model": {
    "defaultProvider": "openai",
    "defaultModel": "gpt-4o",

    "providers": {
      "google": {
        "enabled": true,
        "models": {
          "gemini-2.5-pro": { "enabled": true, "displayName": "Gemini Pro" },
          "gemini-2.5-flash": { "enabled": true, "displayName": "Gemini Flash" }
        }
      },
      "openai": {
        "enabled": true,
        "apiKey": "${OPENAI_API_KEY}",
        "models": {
          "gpt-4o": { "enabled": true, "displayName": "GPT-4o" },
          "gpt-4o-mini": { "enabled": true, "displayName": "GPT-4o Mini" }
        }
      },
      "anthropic": {
        "enabled": true,
        "apiKey": "${ANTHROPIC_API_KEY}",
        "models": {
          "claude-3.5-sonnet": {
            "enabled": true,
            "displayName": "Claude 3.5 Sonnet"
          }
        }
      },
      "deepseek": {
        "enabled": true,
        "apiKey": "${DEEPSEEK_API_KEY}",
        "apiUrl": "https://api.deepseek.com",
        "models": {
          "deepseek-chat": { "enabled": true, "displayName": "DeepSeek Chat" },
          "deepseek-coder": { "enabled": true, "displayName": "DeepSeek Coder" }
        }
      }
    },

    "aliases": {
      "gpt4": { "provider": "openai", "model": "gpt-4o" },
      "claude": { "provider": "anthropic", "model": "claude-3.5-sonnet" },
      "deepseek": { "provider": "deepseek", "model": "deepseek-chat" },
      "coder": { "provider": "deepseek", "model": "deepseek-coder" }
    },

    "fallbackChain": [
      { "provider": "openai", "model": "gpt-4o", "condition": "primary" },
      {
        "provider": "anthropic",
        "model": "claude-3.5-sonnet",
        "condition": "rate_limit"
      },
      {
        "provider": "google",
        "model": "gemini-2.5-flash",
        "condition": "error"
      }
    ]
  },

  "security": {
    "auth": {
      "providers": {
        "google": { "selectedType": "oauth-personal" },
        "openai": { "selectedType": "openai-api-key" },
        "anthropic": { "selectedType": "anthropic-api-key" },
        "deepseek": { "selectedType": "deepseek-api-key" }
      }
    }
  }
}
```

### 环境变量设置

```bash
# .env 文件
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
ALIBABA_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
BAIDU_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
MOONSHOT_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxx
ZHIPU_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
```

## 🚀 **使用示例**

### 基本使用

```bash
# 使用默认模型
gemini chat "Hello, world!"

# 指定模型
gemini chat --model openai/gpt-4o "Explain quantum computing"
gemini chat --model anthropic/claude-3.5-sonnet "Write a poem"
gemini chat --model deepseek/deepseek-coder "Review this Python code"

# 使用别名
gemini chat --model claude "What's the weather like?"
gemini chat --model coder "Optimize this algorithm"
```

### 高级功能

```bash
# 后备模型链（主模型失败时自动切换）
gemini chat --with-fallback "Complex reasoning task"

# 比较多个模型的响应
gemini compare --models "openai/gpt-4o,anthropic/claude-3.5-sonnet,google/gemini-2.5-pro" "Explain AI ethics"

# 批量处理
gemini batch --model deepseek/deepseek-coder --input tasks.txt --output results/
```

## ⚠️ **风险评估与缓解**

### 技术风险

1. **API 格式差异**
   - **风险**: 不同提供商的 API 格式差异巨大
   - **缓解**: 建立完善的适配器系统，逐步支持各种格式

2. **向后兼容性**
   - **风险**: 现有用户配置失效
   - **缓解**: 实现自动配置迁移，保持旧配置格式支持

3. **性能影响**
   - **风险**: 抽象层可能影响性能
   - **缓解**: 优化适配器实现，使用缓存和连接池

### 商业风险

1. **API 成本**
   - **风险**: 多提供商可能增加成本
   - **缓解**: 实现智能路由，优先使用成本效益最高的模型

2. **依赖风险**
   - **风险**: 对多个第三方服务的依赖
   - **缓解**: 实现健全的错误处理和后备机制

## 📊 **成功指标**

### 功能指标

- [ ] 支持至少 8 个主要 AI 模型提供商
- [ ] 实现无缝模型切换，响应时间增加不超过 100ms
- [ ] 向后兼容率达到 100%
- [ ] 新 API 覆盖率达到 95%

### 用户体验指标

- [ ] 新用户配置时间减少 50%
- [ ] 模型响应失败率降低 30%（通过后备机制）
- [ ] 用户满意度评分提升至 4.5+

### 技术指标

- [ ] 代码测试覆盖率达到 85%
- [ ] 单元测试通过率 100%
- [ ] 集成测试通过率 95%
- [ ] 文档完整性达到 90%

## 🗓️ **时间规划**

| 阶段 | 任务           | 估时  | 开始日期 | 结束日期 |
| ---- | -------------- | ----- | -------- | -------- |
| 1    | 基础抽象层建设 | 2-3周 | Week 1   | Week 3   |
| 2    | 主要提供商实现 | 3-4周 | Week 4   | Week 7   |
| 3    | 配置系统改造   | 1-2周 | Week 8   | Week 9   |
| 4    | 认证系统扩展   | 1周   | Week 10  | Week 10  |
| 5    | UI 系统改造    | 1-2周 | Week 11  | Week 12  |
| 6    | 命令行接口扩展 | 3-4天 | Week 13  | Week 13  |
| 7    | 测试和文档     | 1周   | Week 14  | Week 14  |

**总时间估算**: 12-14 周

## 💡 **实施建议**

### 优先级排序

1. **高优先级**: Google Provider 重构（保证现有功能）
2. **高优先级**: OpenAI Provider（最通用的模型）
3. **中优先级**: Anthropic Provider（Claude 模型）
4. **中优先级**: 国产模型 Providers
5. **低优先级**: 小众模型 Providers

### 渐进式部署

1. **第一版**: 支持 Google + OpenAI，确保基础功能稳定
2. **第二版**: 添加 Anthropic + DeepSeek 支持
3. **第三版**: 完整的多提供商支持和高级功能

### 团队配置建议

- **架构师 1人**: 负责整体架构设计和技术决策
- **核心开发 2-3人**: 负责提供商实现和核心逻辑
- **前端开发 1人**: 负责 UI 组件和用户体验
- **测试工程师 1人**: 负责测试策略和质量保证
- **技术写作 1人**: 负责文档和用户指南

这个改造计划将把 Gemini CLI 从单一模型工具升级为强大的多模型 AI
CLI 平台，大大提升其使用价值和市场竞争力。
