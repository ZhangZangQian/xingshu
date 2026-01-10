# VariableParser 日志复制功能

## 功能概述

VariableParser 新增了日志复制功能，可以在解析变量时自动将详细日志复制到剪贴板，便于开发和调试。

## 使用方法

### 基本用法

```typescript
import { VariableParser } from '../utils/VariableParser';

const result = await VariableParser.parse('Hello {name}', context, {
  enableLogging: true,  // 启用日志输出
  copyLog: true         // 自动复制到剪贴板
});

// 日志内容会自动复制到剪贴板
console.log('Result:', result);
```

### 输出示例

当 `copyLog: true` 时，以下内容会自动复制到剪贴板：

```
=== VariableParser Log ===
Timestamp: 2026-01-10T10:30:00.000Z
Duration: 5ms
Depth: 0

Input: "Hello {name}"
Tokens: 2
  [1] TEXT: "Hello "
  [2] VARIABLE: {name}
       → 张三

Result: "Hello 张三"
Result Type: string
========================
```

### 嵌套变量示例

```typescript
context.setVariable('outer', '{inner}');
context.setVariable('inner', 'final_value');

const result = await VariableParser.parse('{outer}', context, {
  enableLogging: true,
  copyLog: true,
  maxDepth: 5
});

// 输出：
// === VariableParser Log ===
// Timestamp: 2026-01-10T10:30:00.000Z
// Duration: 10ms
// Depth: 0
//
// Input: "{outer}"
// Tokens: 1
//   [1] VARIABLE: {outer}
//        → {inner}
//
// Result: "final_value"
// Result Type: string
// ========================
```

## 选项说明

### ParseOptions

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enableLogging` | boolean | false | 是否在控制台输出日志 |
| `copyLog` | boolean | false | 是否自动复制日志到剪贴板 |

### 注意事项

1. **性能影响**
   - `enableLogging: true` 会影响性能（仅用于开发/调试）
   - `copyLog: true` 会额外调用剪贴板 API（仅用于开发/调试）

2. **生产环境**
   - 默认情况下两个选项都是 `false`
   - 生产环境建议不要启用这些选项

3. **日志格式**
   - 时间戳：ISO 8601 格式
   - 时长：毫秒
   - 深度：嵌套解析深度
   - Tokens：所有 token 的详细信息
   - Result：最终结果（JSON 格式化）

## 高级用法

### 手动获取日志

```typescript
// 获取最近一次的日志
const lastLog = VariableParser.getLastLog();
console.log('Last log:', lastLog);

// 清空所有日志
VariableParser.clearLogs();
```

### 组合使用

```typescript
// 开发环境：启用日志和复制
const result = await VariableParser.parse(input, context, {
  enableLogging: true,
  copyLog: true,
  maxDepth: 5,
  format: 'string'
});

// 生产环境：关闭所有日志
const result = await VariableParser.parse(input, context, {
  enableLogging: false,
  copyLog: false
});
```

## 日志内容详解

### 日志结构

```
=== VariableParser Log ===
Timestamp: 2026-01-10T10:30:00.000Z    # 时间戳
Duration: 5ms                          # 执行时长
Depth: 0                                 # 解析深度（嵌套层级）

Input: "Hello {name}"                   # 输入字符串
Tokens: 2                                # token 总数
  [1] TEXT: "Hello "                    # token 1：普通文本
  [2] VARIABLE: {name}                   # token 2：变量
       → 张三                            # 变量解析结果

Result: "Hello 张三"                      # 最终结果
Result Type: string                       # 结果类型
========================
```

### Token 类型

| 类型 | 说明 | 示例 |
|------|------|------|
| TEXT | 普通文本 | `"Hello "` |
| VARIABLE | 变量占位符 | `{name}` |

### 变量解析结果

| 状态 | 显示 | 说明 |
|------|------|------|
| 找到 | `→ value` | 变量已解析 |
| 未找到 | `→ undefined (not found)` | 变量不存在 |

## 调试技巧

### 1. 快速复制日志

```typescript
// 在开发环境全局启用
const result = await VariableParser.parse(input, context, {
  copyLog: true
});

// 日志会自动复制到剪贴板，直接粘贴到文档中
```

### 2. 对比不同场景

```typescript
// 场景 1：简单变量
const result1 = await VariableParser.parse('{name}', context, { copyLog: true });

// 场景 2：嵌套变量
const result2 = await VariableParser.parse('{outer}', context, { copyLog: true });

// 对比两次日志，查看性能差异
```

### 3. 分析解析失败

```typescript
try {
  const result = await VariableParser.parse(input, context, {
    copyLog: true,
    maxDepth: 10
  });
} catch (error) {
  const lastLog = VariableParser.getLastLog();
  console.error('Parse failed. Last log:', lastLog);
  console.error('Error:', error);
}
```

## 性能监控

日志中包含 `Duration` 字段，可以用于性能监控：

```typescript
const result = await VariableParser.parse(input, context, { copyLog: true });

// 从日志中提取时长
const lastLog = VariableParser.getLastLog();
const durationMatch = lastLog.match(/Duration: (\d+)ms/);
const duration = durationMatch ? parseInt(durationMatch[1]) : 0;

if (duration > 100) {
  console.warn(`Slow parse: ${duration}ms for "${input}"`);
}
```

## 常见问题

### Q1: 日志没有复制到剪贴板？

A: 确保以下条件：
1. `copyLog: true` 已设置
2. 应用有剪贴板权限
3. 设备支持剪贴板操作

### Q2: 日志太长，如何只复制关键信息？

A: 目前不支持自定义日志格式，但可以手动处理：
```typescript
const log = VariableParser.getLastLog();
const lines = log.split('\n');
const keyLines = lines.filter(line =>
  line.includes('Input:') ||
  line.includes('Result:') ||
  line.includes('Duration:')
);
console.log(keyLines.join('\n'));
```

### Q3: 如何禁用日志？

A: 设置 `enableLogging: false` 和 `copyLog: false`：
```typescript
const result = await VariableParser.parse(input, context, {
  enableLogging: false,
  copyLog: false
});
```

## 示例场景

### 场景 1：调试嵌套变量

```typescript
context.setVariable('outer', '{inner}');
context.setVariable('inner', '{deep}');
context.setVariable('deep', 'final_value');

const result = await VariableParser.parse('{outer}', context, {
  enableLogging: true,
  copyLog: true,
  maxDepth: 5
});

// 日志会显示 3 层解析过程
// Depth: 0 → {outer} → {inner}
// Depth: 1 → {inner} → {deep}
// Depth: 2 → {deep} → final_value
```

### 场景 2：分析性能

```typescript
const iterations = 1000;
const start = Date.now();

for (let i = 0; i < iterations; i++) {
  await VariableParser.parse('{name} is {age}', context, {
    copyLog: true  // 记录每次解析的日志
  });
}

const elapsed = Date.now() - start;
console.log(`Average: ${elapsed / iterations}ms per iteration`);
```

### 场景 3：错误排查

```typescript
context.setVariable('broken', '{missing}');

try {
  const result = await VariableParser.parse('{broken}', context, {
    copyLog: true
  });
} catch (error) {
  const lastLog = VariableParser.getLastLog();
  console.error('Last parse log:', lastLog);
  console.error('Error:', error);
}

// 日志会显示 {missing} 未找到
// → undefined (not found)
```

---

**文档版本**：1.0
**最后更新**：2026-01-10
**作者**：Claude Code
