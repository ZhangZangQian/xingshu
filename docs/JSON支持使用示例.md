# JSON 支持使用示例

## 示例 1：从 API 获取用户信息并提取字段

```json
{
  "name": "获取飞书用户信息",
  "description": "从飞书 API 获取用户信息并通知",
  "enabled": true,
  "triggers": [
    {
      "type": "manual",
      "config": "{\"methods\":[\"button\",\"shortcut\"]}",
      "enabled": true
    }
  ],
  "actions": [
    {
      "type": "http_request",
      "orderIndex": 0,
      "config": {
        "method": "GET",
        "url": "https://open.feishu.cn/open-apis/user/v4/me",
        "headers": {
          "Authorization": "Bearer {access_token}",
          "Content-Type": "application/json"
        },
        "parseResponse": true,
        "saveParsedResponse": "api_response",
        "saveStatusCodeTo": "status_code"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 1,
      "config": {
        "operation": "json_query",
        "input": "{api_response}",
        "queryPath": "data.user.name",
        "saveToVariable": "user_name"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 2,
      "config": {
        "operation": "json_query",
        "input": "{api_response}",
        "queryPath": "data.user.avatar_url",
        "saveToVariable": "avatar_url"
      }
    },
    {
      "type": "notification",
      "orderIndex": 3,
      "config": {
        "title": "获取用户信息成功",
        "content": "用户名: {user_name}, 状态码: {status_code}",
        "enableSound": true,
        "enableVibration": false
      }
    }
  ]
}
```

---

## 示例 2：筛选成年用户

```json
{
  "name": "筛选成年用户",
  "description": "从 API 获取用户列表，筛选出成年用户",
  "enabled": true,
  "triggers": [
    {
      "type": "manual",
      "config": "{\"methods\":[\"button\"]}",
      "enabled": true
    }
  ],
  "actions": [
    {
      "type": "http_request",
      "orderIndex": 0,
      "config": {
        "method": "GET",
        "url": "https://api.example.com/users",
        "parseResponse": true,
        "saveParsedResponse": "users"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 1,
      "config": {
        "operation": "json_query",
        "input": "{users}",
        "queryPath": "data.items",
        "saveToVariable": "user_list"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 2,
      "config": {
        "operation": "json_filter",
        "input": "{user_list}",
        "filterCondition": "age>=18",
        "saveToVariable": "adults"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 3,
      "config": {
        "operation": "json_map",
        "input": "{adults}",
        "mapField": "name",
        "saveToVariable": "adult_names"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 4,
      "config": {
        "operation": "array_length",
        "input": "{adults}",
        "saveToVariable": "adult_count"
      }
    },
    {
      "type": "notification",
      "orderIndex": 5,
      "config": {
        "title": "成年用户统计",
        "content": "共 {adult_count} 位成年用户: {adult_names}"
      }
    }
  ]
}
```

---

## 示例 3：构建 JSON 请求体并发送

```json
{
  "name": "创建飞书多维表格记录",
  "description": "构建 JSON 请求体并调用 API",
  "enabled": true,
  "triggers": [
    {
      "type": "manual",
      "config": "{\"methods\":[\"button\"]}",
      "enabled": true
    }
  ],
  "actions": [
    {
      "type": "set_variable",
      "orderIndex": 0,
      "config": {
        "variableName": "title",
        "value": "记录标题",
        "scope": "runtime"
      }
    },
    {
      "type": "set_variable",
      "orderIndex": 1,
      "config": {
        "variableName": "content",
        "value": "记录内容",
        "scope": "runtime"
      }
    },
    {
      "type": "set_variable",
      "orderIndex": 2,
      "config": {
        "variableName": "request_body",
        "value": "{\"fields\":[{\"field_name\":\"标题\",\"field_value\":\"{title}\"},{\"field_name\":\"内容\",\"field_value\":\"{content}\"}]}",
        "scope": "runtime",
        "parseAsJSON": true
      }
    },
    {
      "type": "http_request",
      "orderIndex": 3,
      "config": {
        "method": "POST",
        "url": "https://open.feishu.cn/open-apis/bitable/v1/apps/{app_token}/tables/{table_id}/records",
        "headers": {
          "Authorization": "Bearer {access_token}",
          "Content-Type": "application/json"
        },
        "body": "{request_body}",
        "parseResponse": true,
        "saveParsedResponse": "response"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 4,
      "config": {
        "operation": "json_query",
        "input": "{response}",
        "queryPath": "data.record.record_id",
        "saveToVariable": "record_id"
      }
    },
    {
      "type": "notification",
      "orderIndex": 5,
      "config": {
        "title": "记录创建成功",
        "content": "记录 ID: {record_id}"
      }
    }
  ]
}
```

---

## 示例 4：JSONPath 查询嵌套数组

```json
{
  "name": "查询嵌套数组",
  "description": "从复杂 JSON 中提取嵌套数据",
  "enabled": true,
  "triggers": [
    {
      "type": "manual",
      "config": "{\"methods\":[\"button\"]}",
      "enabled": true
    }
  ],
  "actions": [
    {
      "type": "set_variable",
      "orderIndex": 0,
      "config": {
        "variableName": "complex_data",
        "value": "{\"users\":[{\"name\":\"张三\",\"contacts\":[{\"type\":\"phone\",\"value\":\"13800138000\"},{\"type\":\"email\",\"value\":\"zhangsan@example.com\"}]}]}",
        "scope": "runtime",
        "parseAsJSON": true
      }
    },
    {
      "type": "json_process",
      "orderIndex": 1,
      "config": {
        "operation": "json_query",
        "input": "{complex_data}",
        "queryPath": "users.0.contacts.0.value",
        "saveToVariable": "phone_number"
      }
    },
    {
      "type": "notification",
      "orderIndex": 2,
      "config": {
        "title": "提取结果",
        "content": "电话号码: {phone_number}"
      }
    }
  ]
}
```

---

## 示例 5：数组元素修改

```json
{
  "name": "修改数组元素",
  "description": "获取数组并修改指定元素",
  "enabled": true,
  "triggers": [
    {
      "type": "manual",
      "config": "{\"methods\":[\"button\"]}",
      "enabled": true
    }
  ],
  "actions": [
    {
      "type": "set_variable",
      "orderIndex": 0,
      "config": {
        "variableName": "items",
        "value": "[{\"id\":1,\"status\":\"pending\"},{\"id\":2,\"status\":\"pending\"}]",
        "scope": "runtime",
        "parseAsJSON": true
      }
    },
    {
      "type": "json_process",
      "orderIndex": 1,
      "config": {
        "operation": "array_set",
        "input": "{items}",
        "arrayIndex": 0,
        "newValue": "completed",
        "saveToVariable": "updated_items"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 2,
      "config": {
        "operation": "json_encode",
        "input": "{updated_items}",
        "saveToVariable": "items_json"
      }
    },
    {
      "type": "notification",
      "orderIndex": 3,
      "config": {
        "title": "数组修改结果",
        "content": "{items_json}"
      }
    }
  ]
}
```

---

## 示例 6：条件分支 + JSON 操作

```json
{
  "name": "根据用户状态发送不同通知",
  "description": "检查用户状态，发送不同通知",
  "enabled": true,
  "triggers": [
    {
      "type": "manual",
      "config": "{\"methods\":[\"button\"]}",
      "enabled": true
    }
  ],
  "actions": [
    {
      "type": "http_request",
      "orderIndex": 0,
      "config": {
        "method": "GET",
        "url": "https://api.example.com/user/123",
        "parseResponse": true,
        "saveParsedResponse": "user_data"
      }
    },
    {
      "type": "json_process",
      "orderIndex": 1,
      "config": {
        "operation": "json_query",
        "input": "{user_data}",
        "queryPath": "data.status",
        "saveToVariable": "user_status"
      }
    },
    {
      "type": "if_else",
      "orderIndex": 2,
      "config": {
        "branches": [
          {
            "name": "活跃用户",
            "conditions": [
              {
                "field": "user_status",
                "operator": "==",
                "value": "active"
              }
            ],
            "actions": [
              {
                "type": "notification",
                "config": {
                  "title": "欢迎回来",
                  "content": "您是活跃用户，可以继续使用所有功能"
                }
              }
            ]
          },
          {
            "name": "其他情况",
            "conditions": [],
            "actions": [
              {
                "type": "notification",
                "config": {
                  "title": "状态通知",
                  "content": "当前状态: {user_status}"
                }
              }
            ]
          }
        ]
      }
    }
  ]
}
```

---

## 示例 7：JSON 合并操作

```json
{
  "name": "合并 JSON 对象",
  "description": "将多个 JSON 对象合并",
  "enabled": true,
  "triggers": [
    {
      "type": "manual",
      "config": "{\"methods\":[\"button\"]}",
      "enabled": true
    }
  ],
  "actions": [
    {
      "type": "set_variable",
      "orderIndex": 0,
      "config": {
        "variableName": "user_base",
        "value": "{\"name\":\"张三\",\"age\":25}",
        "scope": "runtime",
        "parseAsJSON": true
      }
    },
    {
      "type": "set_variable",
      "orderIndex": 1,
      "config": {
        "variableName": "user_extra",
        "value": "{\"city\":\"北京\",\"job\":\"工程师\"}",
        "scope": "runtime",
        "parseAsJSON": true
      }
    },
    {
      "type": "json_process",
      "orderIndex": 2,
      "config": {
        "operation": "json_merge",
        "input": "{user_base}",
        "mergeSource": "{user_extra}",
        "saveToVariable": "user_full"
      }
    },
    {
      "type": "notification",
      "orderIndex": 3,
      "config": {
        "title": "合并后的用户信息",
        "content": "{user_full}"
      }
    }
  ]
}
```

---

## JSONPath 语法参考

### 基本语法

| 语法 | 说明 | 示例 |
|------|------|------|
| `field` | 字段访问 | `users` |
| `.` | 嵌套字段 | `user.name` |
| `[0]` | 数组索引 | `users[0]` |
| `[*]` | 所有元素（未实现高级过滤） | `items[*]` |
| `[?condition]` | 过滤器 | `items[?age>18]` |

### 查询示例

```typescript
// 对象字段查询
{user.name}           // 获取 user 对象的 name 字段
{user.profile.age}    // 获取嵌套对象的 age 字段

// 数组索引查询
{items[0]}           // 获取数组第一个元素
{items[2].name}      // 获取数组第三个元素的 name 字段

// 混合查询
{data.users[0].contacts[0].type}  // 深度嵌套查询
```

### 过滤条件语法

支持的运算符：`==`, `!=`, `>`, `<`, `>=`, `<=`

```typescript
// 数字比较
age>18
price<=100

// 字符串比较（用单引号）
name=='John'
status!='deleted'

// 布尔值
active==true
deleted==false
```

---

## 设置变量时的类型选项

### auto（默认 - 自动推断）
```json
{
  "variableName": "data",
  "value": "{\"name\":\"张三\"}",
  "scope": "runtime"
  // 自动推断为 object 类型
}
```

### string
```json
{
  "variableName": "text",
  "value": "Hello World",
  "scope": "runtime",
  "type": "string"
}
```

### number
```json
{
  "variableName": "count",
  "value": "42",
  "scope": "runtime",
  "type": "number"
}
```

### boolean
```json
{
  "variableName": "flag",
  "value": "true",
  "scope": "runtime",
  "type": "boolean"
}
```

### object（显式 JSON 解析）
```json
{
  "variableName": "config",
  "value": "{\"key\":\"value\"}",
  "scope": "runtime",
  "type": "object",
  "parseAsJSON": true
}
```

### array（显式 JSON 解析）
```json
{
  "variableName": "items",
  "value": "[1,2,3]",
  "scope": "runtime",
  "type": "array",
  "parseAsJSON": true
}
```
