# Gemini CLI 三种认证方式详解

## 概述

Gemini
CLI 支持三种主要的认证方式来访问 Google 的 AI 服务，每种方式适用于不同的使用场景和环境配置。

## 认证方式类型定义

```typescript
export enum AuthType {
  LOGIN_WITH_GOOGLE = 'oauth-personal', // 1. Login with Google
  USE_GEMINI = 'gemini-api-key', // 2. Use Gemini API Key
  USE_VERTEX_AI = 'vertex-ai', // 3. Vertex AI
  CLOUD_SHELL = 'cloud-shell', // 4. Cloud Shell (自动检测)
}
```

## 1. Login with Google (OAuth2 个人账户认证)

### 🎯 **适用场景**

- **个人开发者**：使用个人 Google 账户
- **快速上手**：无需额外配置，最简单的认证方式
- **交互式使用**：适合命令行交互式使用
- **开发测试**：适合开发和测试环境

### 🔧 **配置方式**

#### 通过 CLI 选择

```bash
gemini auth login
# 会出现认证选择菜单，选择 "1. Login with Google"
```

#### 通过配置文件

```json
{
  "security": {
    "auth": {
      "selectedType": "oauth-personal"
    }
  }
}
```

### 🔐 **认证流程**

1. **启动本地服务器**：CLI 在本地启动 HTTP 服务器监听回调
2. **打开浏览器**：自动打开 Google OAuth 授权页面
3. **用户授权**：用户在浏览器中登录并授权
4. **回调处理**：授权码通过回调 URL 返回到本地服务器
5. **令牌交换**：使用授权码换取访问令牌和刷新令牌
6. **安全存储**：令牌加密存储在本地（KeyChain/加密文件）

### 📊 **技术实现**

```typescript
// OAuth 配置
const OAUTH_CLIENT_ID =
  '681255809395-oo8ft2oprdrnp9e3aqf6av3hmdib135j.apps.googleusercontent.com';
const OAUTH_CLIENT_SECRET = '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';
const OAUTH_SCOPE = [
  'https://www.googleapis.com/auth/cloud-platform',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile',
];

// 自动令牌刷新
const client = new OAuth2Client({
  clientId: OAUTH_CLIENT_ID,
  clientSecret: OAUTH_CLIENT_SECRET,
  redirectUri: `http://localhost:${port}`,
});
```

### ✅ **优点**

- **用户友好**：无需手动管理 API 密钥
- **自动刷新**：令牌自动刷新，无需手动维护
- **安全性高**：使用标准 OAuth2 流程
- **快速开始**：几乎零配置

### ❌ **缺点**

- **需要浏览器**：无法在纯服务器环境使用
- **网络依赖**：需要能访问 Google 认证服务器
- **个人账户限制**：可能受到个人账户的配额限制

---

## 2. Use Gemini API Key (API 密钥认证)

### 🎯 **适用场景**

- **自动化脚本**：CI/CD 管道、自动化工具
- **服务器环境**：无法打开浏览器的环境
- **简单集成**：第三方应用集成
- **配额控制**：使用专门的 API 密钥管理配额

### 🔧 **配置方式**

#### 环境变量配置（推荐）

```bash
export GEMINI_API_KEY="AIzaSyBNR77_O5F6..."
# 或者
export GOOGLE_API_KEY="AIzaSyBNR77_O5F6..."
```

#### .env 文件配置

```bash
# 项目根目录或 ~/.gemini/.env
GEMINI_API_KEY=AIzaSyBNR77_O5F6...
```

#### 通过 CLI 设置

```bash
gemini auth set-api-key
# 会提示输入 API 密钥，并安全存储到本地
```

#### 配置文件

```json
{
  "security": {
    "auth": {
      "selectedType": "gemini-api-key"
    }
  }
}
```

### 🔐 **认证流程**

1. **密钥获取**：从环境变量、存储或配置文件加载 API 密钥
2. **HTTP Headers**：在每个 API 调用中添加 `Authorization: Bearer <api_key>`
3. **直接调用**：直接调用 Gemini API 端点

### 📊 **技术实现**

```typescript
// API 密钥加载优先级
const geminiApiKey =
  (await loadApiKey()) || // 1. 安全存储的密钥
  process.env['GEMINI_API_KEY'] || // 2. GEMINI_API_KEY 环境变量
  process.env['GOOGLE_API_KEY'] || // 3. GOOGLE_API_KEY 环境变量
  undefined;

// 安全存储实现
export async function saveApiKey(apiKey: string): Promise<void> {
  const credentials: OAuthCredentials = {
    serverName: 'default-api-key',
    token: { accessToken: apiKey, tokenType: 'ApiKey' },
    updatedAt: Date.now(),
  };
  await storage.setCredentials(credentials); // 加密存储
}
```

### 🔑 **获取 API 密钥**

1. 访问 [Google AI Studio](https://makersuite.google.com/app/apikey)
2. 点击 "Create API Key"
3. 选择项目或创建新项目
4. 复制生成的 API 密钥
5. 妥善保存密钥（不要提交到代码仓库）

### ✅ **优点**

- **无浏览器依赖**：适合服务器和 CI/CD 环境
- **简单配置**：只需要一个 API 密钥
- **快速认证**：无需 OAuth 流程
- **灵活性高**：可以程序化管理

### ❌ **缺点**

- **手动管理**：需要手动管理密钥的生命周期
- **安全风险**：密钥泄露风险需要谨慎管理
- **无自动刷新**：密钥过期需要手动更新

---

## 3. Vertex AI (Google Cloud 企业认证)

### 🎯 **适用场景**

- **企业环境**：大型组织和企业用户
- **生产系统**：生产级应用和服务
- **Google Cloud 集成**：与 GCP 其他服务集成
- **高级功能**：需要 Vertex AI 的高级特性
- **配额管理**：需要企业级配额和计费管理

### 🔧 **配置方式**

#### 方式 1：Google Cloud 项目 + 位置（推荐）

```bash
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_LOCATION="us-central1"
```

#### 方式 2：Vertex AI API 密钥（Express 模式）

```bash
export GOOGLE_API_KEY="AIzaSyBNR77_O5F6..."
```

#### .env 文件配置

```bash
# ~/.gemini/.env 或项目根目录/.env
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=us-central1

# 或者使用 API 密钥模式
GOOGLE_API_KEY=AIzaSyBNR77_O5F6...
```

#### 配置文件

```json
{
  "security": {
    "auth": {
      "selectedType": "vertex-ai"
    }
  }
}
```

### 🔐 **认证方式**

#### ADC (Application Default Credentials)

```bash
# 使用 gcloud 认证
gcloud auth application-default login

# 或设置服务账户密钥
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

#### 服务账户认证

```bash
# 创建服务账户
gcloud iam service-accounts create gemini-cli-sa

# 分配权限
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:gemini-cli-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/aiplatform.user"

# 创建密钥
gcloud iam service-accounts keys create ~/gemini-cli-key.json \
  --iam-account=gemini-cli-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### 📊 **技术实现**

```typescript
// 配置验证
if (authType === AuthType.USE_VERTEX_AI) {
  const hasVertexProjectLocationConfig =
    !!process.env['GOOGLE_CLOUD_PROJECT'] &&
    !!process.env['GOOGLE_CLOUD_LOCATION'];
  const hasGoogleApiKey = !!process.env['GOOGLE_API_KEY'];

  if (!hasVertexProjectLocationConfig && !hasGoogleApiKey) {
    throw new Error(
      'Vertex AI requires project/location or API key configuration',
    );
  }
}

// 内容生成器配置
contentGeneratorConfig.apiKey = googleApiKey;
contentGeneratorConfig.vertexai = true; // 标记为 Vertex AI 模式
```

### 🏢 **企业配置示例**

#### 开发环境

```bash
# ~/.gemini/.env
GOOGLE_CLOUD_PROJECT=my-company-dev
GOOGLE_CLOUD_LOCATION=us-central1
```

#### 生产环境（Kubernetes）

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gemini-cli-config
type: Opaque
data:
  GOOGLE_CLOUD_PROJECT: <base64-encoded-project-id>
  GOOGLE_CLOUD_LOCATION: <base64-encoded-location>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-gemini
spec:
  template:
    spec:
      containers:
        - name: app
          envFrom:
            - secretRef:
                name: gemini-cli-config
```

### ✅ **优点**

- **企业级**：适合大型组织和生产环境
- **高级功能**：访问 Vertex AI 的所有高级特性
- **安全性最高**：使用 Google Cloud IAM 和服务账户
- **配额管理**：企业级配额和计费控制
- **合规性**：符合企业安全和合规要求

### ❌ **缺点**

- **配置复杂**：需要 Google Cloud 项目和权限配置
- **成本较高**：企业级定价
- **学习曲线**：需要了解 Google Cloud 概念

---

## 配置优先级和最佳实践

### 🔄 **配置加载优先级**

1. **API 密钥加载顺序**：

   ```
   安全存储 → GEMINI_API_KEY → GOOGLE_API_KEY → 配置文件
   ```

2. **环境变量优先级**：
   ```
   命令行参数 → 环境变量 → .env文件 → 配置文件 → 默认值
   ```

### 🛡️ **安全最佳实践**

#### 1. API 密钥安全

```bash
# ✅ 好的做法
export GEMINI_API_KEY="$(cat ~/.secret/gemini-key)"  # 从安全文件读取
export GEMINI_API_KEY="$(vault kv get -field=key secret/gemini)"  # 从密钥管理服务

# ❌ 避免的做法
export GEMINI_API_KEY="AIza..."  # 直接在命令行暴露
echo "GEMINI_API_KEY=AIza..." >> ~/.bashrc  # 在 shell 配置文件中明文存储
```

#### 2. 配置文件安全

```bash
# 设置适当的文件权限
chmod 600 ~/.gemini/.env
chmod 600 ~/.gemini/settings.json

# Git 忽略敏感文件
echo "*.env" >> .gitignore
echo ".gemini/settings.json" >> .gitignore
```

#### 3. 环境隔离

```bash
# 开发环境
cat > ~/.gemini/.env.dev << EOF
GEMINI_API_KEY=dev_key_here
GOOGLE_CLOUD_PROJECT=mycompany-dev
EOF

# 生产环境
cat > ~/.gemini/.env.prod << EOF
GOOGLE_CLOUD_PROJECT=mycompany-prod
GOOGLE_CLOUD_LOCATION=us-central1
EOF

# 使用不同配置
export GEMINI_ENV=dev && gemini chat
export GEMINI_ENV=prod && gemini chat
```

### 🔄 **认证切换**

#### 命令行切换

```bash
# 查看当前认证状态
gemini auth status

# 切换认证方式
gemini auth login  # 选择新的认证方式

# 登出当前认证
gemini auth logout
```

#### 程序化切换

```typescript
// 设置认证类型
loadedSettings.setValue(
  SettingScope.User,
  'security.auth.selectedType',
  'vertex-ai',
);

// 验证认证配置
const error = validateAuthMethod('vertex-ai');
if (error) {
  console.error('认证配置错误:', error);
}
```

## 选择建议

### 🎯 **认证方式选择指南**

| 使用场景   | 推荐方式          | 理由                   |
| ---------- | ----------------- | ---------------------- |
| 个人开发   | Login with Google | 简单易用，无需管理密钥 |
| 自动化脚本 | Gemini API Key    | 无浏览器依赖，配置简单 |
| CI/CD 管道 | Gemini API Key    | 适合无人值守环境       |
| 企业开发   | Vertex AI         | 企业级功能和安全性     |
| 生产系统   | Vertex AI         | 高可用性和企业支持     |
| 学习测试   | Login with Google | 快速上手，无需额外配置 |

### 🏢 **团队协作建议**

1. **统一认证方式**：团队内使用一致的认证方式
2. **环境隔离**：开发、测试、生产使用不同的密钥/项目
3. **密钥轮换**：定期轮换 API 密钥
4. **权限最小化**：只授予必要的权限
5. **监控和审计**：监控 API 使用情况和异常

通过合理选择和配置认证方式，可以确保 Gemini CLI 在不同环境下安全、高效地运行。
