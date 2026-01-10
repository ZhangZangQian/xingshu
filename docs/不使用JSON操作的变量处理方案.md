# 不使用 JSON 操作的变量处理方案

## 方案说明

### 核心思路

由于变量替换问题，使用 **TEXT_PROCESS** 动作配合 **JSON 字符串拼接** 方式来构建请求体。

### 工作流程

```
1. TEXT_PROCESS - 从 JSON 对象提取字段
2. SET_VARIABLE - 拼接 JSON 字符串（使用变量）
3. HTTP_REQUEST - 发送拼接后的 JSON 字符串
```

---

## 示例 1：构建嵌套 JSON 对象

### 方案 A：TEXT_PROCESS 提取字段并拼接（推荐）

```json
{
  "actions": [
    {
      "type": "http_request",
      "orderIndex": 1,
      "config": {
        "method": "POST",
        "url": "https://api.coze.cn/v1/workflow/run",
        "headers": {
          "Content-Type": "application/json"
        },
        "body": "{\"workflow_id\":\"7550495126771449906\",\"parameters\":{\"url\":\"{extracted_url}\",\"quality\":\"{quality_score}\"}}",
        "parseResponse": true,
        "saveParsedResponseTo": "api_response_json"
      }
    }
  ]
}
```

---

## 示例 2：快小红流程改造

### 方案 A：完全使用 TEXT_PROCESS（不依赖 JSON 操作）

```json
{
  "actions": [
    {
      "id": 1,
      "type": "text_process",
      "orderIndex": 4,
      "config": {
        "operation": "regex_extract",
        "input": "{clipboard_content}",
        "pattern": "https?://[^\\s]+",
        "groupIndex": 0,
        "saveToVariable": "extracted_url"
      }
    },
    {
      "id": 2,
      "type": "set_variable",
      "orderIndex": 5,
      "config": {
        "variableName": "request_body",
        "value": "{\"workflow_id\":\"7550495126771449906\",\"parameters\":{\"url\":\"{extracted_url}\",\"quality\":\"{quality_score}\",\"read\":\"{quality}\",\"notes\":\"{notes}\",\"label\":[\"{label}\"],\"xhscookie\":\"{飞书多维表格授权码}\",\"order_id\":\"{订单号}\"}}",
        "scope": "runtime"
      }
    },
    {
      "id": 3,
      "type": "http_request",
      "orderIndex": 6,
      "config": {
        "method": "POST",
        "url": "https://api.coze.cn/v1/workflow/run",
        "headers": {
          "Content-Type": "application/json"
        },
        "body": "{request_body}",
        "timeout": 30000,
        "parseResponse": true,
        "saveParsedResponseTo": "api_response_json",
        "saveResponseTo": "api_response"
      }
    },
    {
      "id": 4,
      "type": "text_process",
      "orderIndex": 7,
      "config": {
        "operation": "regex_extract",
        "input": "{api_response_json}",
        "pattern": "\"message\":\"([^\"]+)\"",
        "groupIndex": 1,
        "saveToVariable": "result_message"
      }
    }
  ]
}
```

### 方案 B：使用多个 TEXT_PROCESS 动作（字段级提取）

```json
{
  "actions": [
    // 提取 workflow_id
    {
      "id": 1,
      "type": "text_process",
      "orderIndex": 11,
      "config": {
        "operation": "regex_extract",
        "input": "{api_response_json}",
        "pattern": "\"workflow_id\":\"([^\"]+)\"",
        "groupIndex": 1,
        "saveToVariable": "workflow_id"
      }
    },
    // 提取 data.url
    {
      "id": 2,
      "type": "text_process",
      "orderIndex": 12,
      "config": {
        "operation": "regex_extract",
        "input": "{api_response_json}",
        "pattern": "\"url\":\"([^\"]+)\"",
        "groupIndex": 1,
        "saveToVariable": "data_url"
      }
    },
    // 提取 data.message
    {
      "id": 3,
      "type": "text_process",
      "orderIndex": 13,
      "config": {
        "operation": "regex_extract",
        "input": "{api_response_json}",
        "pattern": "\"message\":\"([^\"]+)\"",
        "groupIndex": 1,
        "saveToVariable": "result_message"
      }
    },
    // 构建新的请求体
    {
      "id": 4,
      "type": "set_variable",
      "orderIndex": 14,
      "config": {
        "variableName": "new_body",
        "value": "{\"workflow_id\":\"{workflow_id}\",\"url\":\"{data_url}\"}",
        "scope": "runtime"
      }
    },
    // 使用新请求体再次调用
    {
      "id": 5,
      "type": "http_request",
      "orderIndex": 15,
      "config": {
        "method": "POST",
        "url": "https://api.example.com/api",
        "headers": {
          "Content-Type": "application/json"
        },
        "body": "{new_body}",
        "timeout": 30000
      }
    }
  ]
}
```

---

## 示例 3：动态构建 JSON 数组

### 场景：构建包含多个元素的数组

```json
{
  "actions": [
    // TEXT_PROCESS 1 - 提取第一个用户 ID
    {
      "id": 1,
      "type": "text_process",
      "orderIndex": 1,
      "config": {
        "operation": "regex_extract",
        "input": "{api_response_json}",
        "pattern": "\"users\":\\[\\{\"id\":\"([^\"]+)\"",
        "groupIndex": 1,
        "saveToVariable": "user1_id"
      }
    },
    // TEXT_PROCESS 2 - 提取第二个用户 ID
    {
      "id": 2,
      "type": "text_process",
      "orderIndex": 2,
      "config": {
        "operation": "regex_extract",
        "input": "{api_response_json}",
        "pattern": "\"users\":\\[\\{\"id\":\"([^\"]+)\"",
        "groupIndex": 2,
        "saveToVariable": "user2_id"
      }
    },
    // SET_VARIABLE - 构建数组字符串
    {
      "id": 3,
      "type": "set_variable",
      "orderIndex": 3,
      "config": {
        "variableName": "user_ids_array",
        "value": "[\"{user1_id}\",\"{user2_id}\"]",
        "scope": "runtime"
      }
    },
    // HTTP_REQUEST - 使用数组
    {
      "id": 4,
      "type": "http_request",
      "orderIndex": 4,
      "config": {
        "method": "POST",
        "url": "https://api.example.com/users",
        "headers": {
          "Content-Type": "application/json"
        },
        "body": "{\"user_ids\":{user_ids_array}}",
        "timeout": 30000
      }
    }
  ]
}
```

---

## 示例 4：使用 SET_VARIABLE 的 auto 类型推断

### 自动推断 string/number/boolean 类型

```json
{
  "actions": [
    // 字符串类型（显式）
    {
      "id": 1,
      "type": "set_variable",
      "config": {
        "variableName": "message_text",
        "value": "Hello {user_name}",
        "scope": "runtime",
        "type": "string"
      }
    },
    // 数字类型（显式）
    {
      "id": 2,
      "type": "set_variable",
      "config": {
        "variableName": "timeout",
        "value": "30",
        "scope": "runtime",
        "type": "number"
      }
    },
    // 布尔值（显式）
    {
      "id": 3,
      "type": "set_variable",
      "config": {
        "variableName": "is_enabled",
        "value": "true",
        "scope": "runtime",
        "type": "boolean"
      }
    },
    // JSON 对象（parseAsJSON + type: object）
    {
      "id": 4,
      "type": "set_variable",
      "config": {
        "variableName": "user_profile",
        "value": "{\"name\":\"{user_name}\",\"age\":25,\"active\":true}",
        "scope": "runtime",
        "parseAsJSON": true,
        "type": "object"
      }
    },
    // JSON 数组（parseAsJSON + type: array）
    {
      "id": 5,
      "type": "set_variable",
      "config": {
        "variableName": "tags",
        "value": "[\"tech\",\"news\",\"lifestyle\"]",
        "scope": "runtime",
        "parseAsJSON": true,
        "type": "array"
      }
    },
    // auto 类型自动推断
    {
      "id": 6,
      "type": "set_variable",
      "config": {
        "variableName": "auto_value",
        "value": "{user_age}",
        "scope": "runtime",
        "type": "auto"
      }
    }
  ]
}
```

---

## 方案对比

| 特性 | JSON_PROCESS | TEXT_PROCESS |
|------|-----------|---------------|
| **JSONPath 查询** | 支持 | ❌ 不支持 |
| **数组过滤/映射** | 支持 | ❌ 不支持 |
| **JSON 合并** | 支持 | ❌ 不支持 |
| **字段提取** | 支持直接 | ❌ 需要正则表达式 |
| **类型保持** | 保持 object/array | 转为字符串 |
| **复杂度** | 简单 | 需要多个动作配合 |
| **学习曲线** | 需要学习 JSONPath 语法 | 已熟悉正则表达式 |

---

## 推荐方案

对于快小红流程，**推荐使用方案 A：先 TEXT_PROCESS 提取，后 SET_VARIABLE 拼接**，原因：

1. ✅ **变量替换更可靠**：TEXT_PROCESS 使用简单的字符串替换，已验证可行
2. ✅ **调试更容易**：每个 TEXT_PROCESS 动作都有独立的 saveToVariable，可以查看中间结果
3. ✅ **兼容性好**：不依赖新的 JSON 操作类型

如果后续需要访问嵌套 JSON 结构，可以：
- 使用方案 A：多次 TEXT_PROCESS 提取不同字段
- 或者等待 JSON 操作功能稳定后再迁移到 JSON_PROCESS
