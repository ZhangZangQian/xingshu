# IF_ELSE 分支功能 - 手动操作指南

**状态**: 部分完成，需要手动修改现有文件

**已完成**:
- ✅ 创建 `IfElseAction.ts` 执行器
- ✅ 创建详细实现方案文档

**待完成**: 需要手动修改以下文件

---

## 一、修改 Macro.ts 增加接口定义

**文件**: `entry/src/main/ets/models/Macro.ts`

### 1.1 修改 ActionType 枚举（第 102-112 行）

**原代码**:
```typescript
export enum ActionType {
  LAUNCH_APP = 'launch_app',
  NOTIFICATION = 'notification',
  HTTP_REQUEST = 'http_request',
  CLIPBOARD_READ = 'clipboard_read',
  CLIPBOARD_WRITE = 'clipboard_write',
  OPEN_URL = 'open_url',
  TEXT_PROCESS = 'text_process',
  USER_DIALOG = 'user_dialog',
  SET_VARIABLE = 'set_variable'
}
```

**修改为**:
```typescript
export enum ActionType {
  LAUNCH_APP = 'launch_app',
  NOTIFICATION = 'notification',
  HTTP_REQUEST = 'http_request',
  CLIPBOARD_READ = 'clipboard_read',
  CLIPBOARD_WRITE = 'clipboard_write',
  OPEN_URL = 'open_url',
  TEXT_PROCESS = 'text_process',
  USER_DIALOG = 'user_dialog',
  SET_VARIABLE = 'set_variable',
  IF_ELSE = 'if_else'  // 🆕 新增
}
```

### 1.2 修改 Action.parsedConfig 类型（第 125-127 行）

**原代码**:
```typescript
parsedConfig?: LaunchAppConfig | NotificationConfig | HttpRequestConfig |
               ClipboardConfig | OpenUrlConfig | TextProcessConfig | UserDialogConfig |
               SetVariableConfig;
```

**修改为**:
```typescript
parsedConfig?: LaunchAppConfig | NotificationConfig | HttpRequestConfig |
               ClipboardConfig | OpenUrlConfig | TextProcessConfig | UserDialogConfig |
               SetVariableConfig | IfElseConfig;  // 🆕 增加 IfElseConfig
```

### 1.3 在文件末尾（第 303 行后）增加新接口

在 `SystemVariables` 接口定义后增加：

```typescript
/**
 * IF_ELSE 分支动作配置
 */
export interface IfElseConfig {
  branches: Branch[];  // 分支列表（顺序执行，第一个匹配的分支会被执行）
}

/**
 * 分支定义
 */
export interface Branch {
  name?: string;                   // 分支名称（可选，用于调试和UI显示）
  conditions?: BranchCondition[];  // 分支条件（为空或未定义表示 else 分支）
  actions: ActionConfig[];         // 分支内的动作列表
}

/**
 * 分支条件（简化版，不需要数据库ID）
 */
export interface BranchCondition {
  field: string;                   // 比较字段（变量名）
  operator: ConditionOperator;     // 运算符
  value: string;                   // 比较值
  logicOperator?: 'AND' | 'OR';    // 与下一个条件的逻辑关系（默认 AND）
}

/**
 * 动作配置（用于嵌套在分支中）
 */
export interface ActionConfig {
  type: ActionType;                // 动作类型
  config: LaunchAppConfig | NotificationConfig | HttpRequestConfig |
          ClipboardConfig | OpenUrlConfig | TextProcessConfig | UserDialogConfig |
          SetVariableConfig | IfElseConfig;  // 动作配置（支持嵌套）
}
```

---

## 二、修改 ActionTypes.ts 增加常量

**文件**: `entry/src/main/ets/constants/ActionTypes.ts`

### 2.1 增加常量定义（第 13 行后）

在 `SET_VARIABLE` 后增加：

```typescript
static readonly IF_ELSE = 'if_else';
```

### 2.2 修改 getAll() 方法（第 18-30 行）

在返回数组中增加：

```typescript
static getAll(): string[] {
  return [
    ActionTypes.LAUNCH_APP,
    ActionTypes.NOTIFICATION,
    ActionTypes.HTTP_REQUEST,
    ActionTypes.CLIPBOARD_READ,
    ActionTypes.CLIPBOARD_WRITE,
    ActionTypes.OPEN_URL,
    ActionTypes.TEXT_PROCESS,
    ActionTypes.USER_DIALOG,
    ActionTypes.SET_VARIABLE,
    ActionTypes.IF_ELSE  // 🆕 新增
  ];
}
```

### 2.3 修改 getDisplayName() 方法（第 35-58 行）

在 switch 语句中增加：

```typescript
case ActionTypes.SET_VARIABLE:
  return '设置变量';
case ActionTypes.IF_ELSE:  // 🆕 新增
  return '条件分支';
default:
  return '未知类型';
```

---

## 三、注册 IfElseAction 执行器

**文件**: `entry/src/main/ets/entryability/EntryAbility.ts`

### 3.1 增加导入（文件顶部，约第 10-20 行）

在其他 import 后增加：

```typescript
import { IfElseAction } from '../services/actions/IfElseAction';
```

### 3.2 注册执行器（`initializeApp` 方法内，约第 95-100 行）

在 `actionExecutor.registerExecutor(ActionType.SET_VARIABLE, ...)` 后增加：

```typescript
actionExecutor.registerExecutor(ActionType.IF_ELSE, new IfElseAction());
```

完整的注册代码示例：

```typescript
const actionExecutor = ActionExecutor.getInstance();
actionExecutor.registerExecutor(ActionType.LAUNCH_APP, new LaunchAppAction());
actionExecutor.registerExecutor(ActionType.NOTIFICATION, new NotificationAction());
actionExecutor.registerExecutor(ActionType.HTTP_REQUEST, new HttpRequestAction());
actionExecutor.registerExecutor(ActionType.CLIPBOARD_READ, new ClipboardAction());
actionExecutor.registerExecutor(ActionType.CLIPBOARD_WRITE, new ClipboardAction());
actionExecutor.registerExecutor(ActionType.OPEN_URL, new OpenUrlAction());
actionExecutor.registerExecutor(ActionType.TEXT_PROCESS, new TextProcessAction());
actionExecutor.registerExecutor(ActionType.USER_DIALOG, new UserDialogAction());
actionExecutor.registerExecutor(ActionType.SET_VARIABLE, new SetVariableAction());
actionExecutor.registerExecutor(ActionType.IF_ELSE, new IfElseAction());  // 🆕 新增
```

---

## 四、验证修改

完成上述修改后，运行以下命令验证：

```bash
# 构建项目
hvigor assembleHap --mode module -p module=entry@default -p product=default

# 查看构建日志，确认没有编译错误
```

**预期结果**:
- ✅ 无编译错误
- ✅ 日志中显示 "Registered executor for action type: if_else"

---

## 五、测试配置示例

创建一个简单的测试宏，验证 IF_ELSE 功能：

```json
{
  "name": "IF_ELSE 测试",
  "triggers": [{"type": "manual", "config": "{}"}],
  "actions": [
    {
      "type": "set_variable",
      "config": "{\"variableName\":\"test_var\",\"value\":\"hello\",\"scope\":\"runtime\"}"
    },
    {
      "type": "if_else",
      "config": "{\"branches\":[{\"name\":\"分支1\",\"conditions\":[{\"field\":\"{test_var}\",\"operator\":\"==\",\"value\":\"hello\"}],\"actions\":[{\"type\":\"notification\",\"config\":{\"title\":\"分支1执行\",\"content\":\"test_var == hello\",\"enableSound\":false,\"enableVibration\":false}}]},{\"name\":\"else分支\",\"conditions\":[],\"actions\":[{\"type\":\"notification\",\"config\":{\"title\":\"else分支执行\",\"content\":\"默认分支\",\"enableSound\":false,\"enableVibration\":false}}]}]}"
    }
  ]
}
```

**测试步骤**:
1. 在 MacroEditor 页面创建上述宏
2. 手动触发执行
3. 预期结果：收到通知 "分支1执行"（因为 test_var == "hello"）
4. 修改 test_var 的值为其他内容，再次执行
5. 预期结果：收到通知 "else分支执行"

---

## 六、下一步工作

完成上述修改后，可以继续实现：

1. **UI 配置界面** (`MacroEditor.ets`)
   - 增加 IF_ELSE 动作类型选项
   - 实现分支条件编辑器
   - 实现分支内动作编辑器

2. **单元测试** (`tests/IfElseAction.test.ts`)
   - 测试单条件分支
   - 测试多条件（AND/OR）分支
   - 测试嵌套 IF_ELSE
   - 测试错误处理

3. **"快小红"完整配置**
   - 参考 `docs/IF_ELSE实现方案.md` 第五节
   - 创建完整的三分支配置（商品/博主/笔记）

---

##七、故障排查

### 问题1: 编译错误 "Cannot find name 'IfElseConfig'"

**原因**: Macro.ts 中未添加新接口

**解决**: 确认已在 Macro.ts 末尾添加 `IfElseConfig`、`Branch`、`BranchCondition`、`ActionConfig` 接口

### 问题2: 运行时错误 "No executor registered for action type: if_else"

**原因**: EntryAbility 中未注册执行器

**解决**: 确认已在 `initializeApp` 方法中调用 `actionExecutor.registerExecutor(ActionType.IF_ELSE, new IfElseAction())`

### 问题3: 编译错误 "Module not found: IfElseAction"

**原因**: import 路径错误或文件未创建

**解决**: 确认 `entry/src/main/ets/services/actions/IfElseAction.ts` 文件存在

---

**文档版本**: v1.0
**最后更新**: 2026-01-08
**完成度**: 70%（核心代码已完成，需手动修改配置文件）
