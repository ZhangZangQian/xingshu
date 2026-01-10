# VariableParser 递归检测改进说明

## 改进日期

2026-01-10

## 改进概述

在原优化基础上，进一步实现了**递归检测优化**，解决了 JSON 字符串和正则表达式被误判为包含变量的问题。

## 核心改进

### 1. 删除 `containsVariables` 方法

**旧实现**（使用正则检查）：
```typescript
private static containsVariables(value: any): boolean {
  if (typeof value !== 'string') return false;
  return /\{[^{}]+\}/.test(value);  // 会误判 JSON 和正则
}
```

**问题**：
- JSON 字符串 `{"key":"value"}` 包含 `{"key":...}`，会被误判
- 正则表达式 `\d{3}` 包含 `{3}`，会被误判

### 2. 新增 `shouldRecurse` 方法

**新实现**（使用 Tokenizer 判断）：
```typescript
private static shouldRecurse(
  originalTokens: Token[],
  resolvedTokens: Array<{ token: Token; value: any }>
): boolean {
  const variableTokens = originalTokens.filter(t => t.type === TokenType.VARIABLE);

  if (variableTokens.length === 0) {
    return false;
  }

  for (const resolvedToken of resolvedTokens) {
    if (resolvedToken.token.type === TokenType.VARIABLE) {
      const value = resolvedToken.value;

      if (typeof value === 'string') {
        // 使用 Tokenizer 检查是否包含变量（而不是正则）
        const nestedTokens = VariableTokenizer.tokenize(value);
        const hasVariables = nestedTokens.some(t => t.type === TokenType.VARIABLE);

        if (hasVariables) {
          return true;
        }
      }
    }
  }

  return false;
}
```

**优势**：
- 复用 Tokenizer 结果，避免重复正则扫描
- 准确判断是否包含变量占位符
- JSON 字符串和正则表达式不会被误判

## 性能提升

| 场景 | 改进前 | 改进后 | 提升 |
|------|--------|--------|------|
| JSON 字符串 | 2 次解析 + 2 次正则扫描 | 1 次解析 + 0 次正则扫描 | 50% |
| 正则表达式 | 2 次解析 + 2 次正则扫描 | 1 次解析 + 0 次正则扫描 | 50% |
| 嵌套变量 | 2 次解析 + 2 次正则扫描 | 2 次解析 + 0 次正则扫描 | 减少正则扫描 |

## 测试覆盖

新增 4 个测试用例：

1. JSON 字符串不应触发递归
2. 正则表达式不应触发递归
3. JSON 字符串中的花括号不应误判
4. 嵌套变量仍然正常工作

## 文档更新

- 新增文档：`docs/VariableParser递归检测改进.md`
- 更新文档：`docs/VariableParser优化完成总结.md`
- 更新文档：`docs/VariableParser优化实施计划.md`

## 兼容性

- API 完全兼容
- 不影响现有功能
- 性能透明提升（用户无感知）
