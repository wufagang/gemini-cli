基于对代码的分析，logger.emit(logRecord) 执行后的日志去向取决于项目的遥测配置。日志会写到以下位置之一：

🎯 日志输出目标（按优先级）

1. 直接 GCP 导出 (useDirectGcpExport = true)

当配置了 GCP 项目 ID 且目标是 GCP 时：

- 去向: Google Cloud Logging
- 配置: GOOGLE_CLOUD_PROJECT 环境变量
- 实现: GcpLogExporter (sdk.ts:124)

2. OTLP 协议导出 (有配置 endpoint)

通过 OpenTelemetry Protocol 发送到远程服务器：

- HTTP 模式: 发送到 config.getTelemetryOtlpEndpoint() 指定的 HTTP 端点
- gRPC 模式: 发送到 gRPC 端点（默认，支持 GZIP 压缩）
- 实现: OTLPLogExporter 或 OTLPLogExporterHttp (sdk.ts:134/149)

3. 文件输出 (配置了 outfile)

当设置了 telemetryOutfile 配置时：

- 去向: 指定的本地文件
- 格式: JSON 格式，每条日志记录一行
- 实现: FileLogExporter (file-exporters.ts:54)
- 文件操作: fs.createWriteStream(filePath, { flags: 'a' }) - 追加模式

4. 控制台输出 (默认/fallback)

如果没有其他配置：

- 去向: 标准输出 (console)
- 实现: ConsoleLogRecordExporter (sdk.ts:170)

📋 配置方法

可以通过以下配置选项控制日志去向：

// config.ts 中的配置方法 getTelemetryEnabled()
// 是否启用遥测 getTelemetryOtlpEndpoint() //
OTLP 端点地址 getTelemetryOtlpProtocol() // 协议 ('grpc' | 'http')
getTelemetryTarget() // 目标 (GCP | 其他) getTelemetryOutfile()
// 输出文件路径 getTelemetryUseCollector() // 是否使用收集器

🔍 处理流程

1. 日志记录创建: LogRecord 对象包含 body 和 attributes
2. 批处理: 通过 BatchLogRecordProcessor 批量处理 (sdk.ts:180)
3. 导出: 根据配置选择对应的导出器
4. 持久化: 写入目标存储（文件/远程服务/控制台）

总结：logger.emit(logRecord) 的输出位置完全由项目的遥测配置决定，可能是 GCP 云日志、远程 OTLP 服务器、本地文件或控制台输出。
