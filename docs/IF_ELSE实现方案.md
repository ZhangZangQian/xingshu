# IF_ELSE 分支功能 - 实现方案

**目标**: 为鸿蒙宏App增加条件分支能力，支持 if-else 逻辑

**创建时间**: 2026-01-08
**状态**: 实施中

---

## 一、数据模型设计

### 1.1 ActionType 枚举扩展

在 `entry/src/main/ets/models/Macro.ts` 第 111 行后增加：

```typescript
export enum ActionType {
  // ... 现有类型 ...
  SET_VARIABLE = 'set_variable',
  IF_ELSE = 'if_else'  // 🆕 新增
}
```

### 1.2 新增接口定义

在 `Macro.ts` 文件末尾（第 304 行后）增加：

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
  conditions?: BranchCondition[];  // 分支条件（为空表示 else 分支）
  actions: ActionConfig[];         // 分支内的动作列表
}

/**
 * 分支条件（简化版）
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
  type: ActionType;
  config: LaunchAppConfig | NotificationConfig | HttpRequestConfig |
          ClipboardConfig | OpenUrlConfig | TextProcessConfig | UserDialogConfig |
          SetVariableConfig | IfElseConfig;  // 支持嵌套
}
```

### 1.3 更新 Action.parsedConfig 类型

在 `Macro.ts` 第 125-127 行修改：

```typescript
export interface Action {
  // ... 现有字段 ...

  // 运行时解析的配置对象
  parsedConfig?: LaunchAppConfig | NotificationConfig | HttpRequestConfig |
                 ClipboardConfig | OpenUrlConfig | TextProcessConfig | UserDialogConfig |
                 SetVariableConfig | IfElseConfig;  // 🆕 增加 IfElseConfig
}
```

---

## 二、IfElseAction 执行器实现

### 2.1 创建执行器文件

文件路径: `entry/src/main/ets/services/actions/IfElseAction.ts`

```typescript
import { Action, ActionType } from '../../models/Macro';
import { ExecutionContext } from '../../models/ExecutionContext';
import { IActionExecutor } from '../ActionExecutor';
import { IfElseConfig, Branch, BranchCondition } from '../../models/Macro';
import { ConditionEvaluator } from '../ConditionEvaluator';
import { ActionExecutor } from '../ActionExecutor';
import Logger from '../../utils/Logger';

const TAG = 'IfElseAction';

/**
 * IF_ELSE 条件分支动作执行器
 *
 * 执行逻辑：
 * 1. 遍历 branches 列表
 * 2. 对每个分支评估 conditions
 * 3. 执行第一个条件满足的分支
 * 4. 如果所有分支都不满足，执行 else 分支（conditions 为空的分支）
 */
export class IfElseAction implements IActionExecutor {
  private conditionEvaluator: ConditionEvaluator;
  private actionExecutor: ActionExecutor;

  constructor() {
    this.conditionEvaluator = ConditionEvaluator.getInstance();
    this.actionExecutor = ActionExecutor.getInstance();
  }

  async execute(action: Action, context: ExecutionContext): Promise<void> {
    const config = JSON.parse(action.config) as IfElseConfig;

    if (!config.branches || config.branches.length === 0) {
      Logger.warn(TAG, 'No branches defined in IF_ELSE action');
      return;
    }

    Logger.info(TAG, `Evaluating ${config.branches.length} branches`);

    // 遍历所有分支
    for (let i = 0; i < config.branches.length; i++) {
      const branch = config.branches[i];
      const branchName = branch.name || `Branch ${i + 1}`;

      // 检查是否为 else 分支（没有条件）
      const isElseBranch = !branch.conditions || branch.conditions.length === 0;

      if (isElseBranch) {
        Logger.info(TAG, `Executing else branch: ${branchName}`);
        await this.executeBranch(branch, context);
        return;  // else 分支执行后退出
      }

      // 评估分支条件
      const conditionsPassed = await this.evaluateBranchConditions(branch.conditions!, context);

      if (conditionsPassed) {
        Logger.info(TAG, `Branch conditions met: ${branchName}`);
        await this.executeBranch(branch, context);
        return;  // 找到匹配分支后退出
      } else {
        Logger.info(TAG, `Branch conditions not met: ${branchName}`);
      }
    }

    // 所有分支都不匹配
    Logger.info(TAG, 'No branch conditions matched');
  }

  /**
   * 评估分支条件（支持 AND/OR 逻辑）
   */
  private async evaluateBranchConditions(
    conditions: BranchCondition[],
    context: ExecutionContext
  ): Promise<boolean> {
    if (conditions.length === 0) return true;

    let result = true;
    let currentLogic: 'AND' | 'OR' = 'AND';

    for (let i = 0; i < conditions.length; i++) {
      const condition = conditions[i];

      // 转换为 Condition 格式供 ConditionEvaluator 使用
      const singleResult = await this.conditionEvaluator.evaluate(
        [{
          id: 0,
          macroId: context.getMacroId(),
          field: condition.field,
          operator: condition.operator,
          value: condition.value
        }],
        context
      );

      // 根据逻辑运算符合并结果
      if (i === 0) {
        result = singleResult;
      } else {
        if (currentLogic === 'AND') {
          result = result && singleResult;
        } else {
          result = result || singleResult;
        }
      }

      // 设置下一个条件的逻辑运算符
      currentLogic = condition.logicOperator || 'AND';

      Logger.info(TAG,
        `Condition [${condition.field} ${condition.operator} ${condition.value}] = ${singleResult}, combined = ${result}`
      );
    }

    return result;
  }

  /**
   * 执行分支内的动作列表
   */
  private async executeBranch(branch: Branch, context: ExecutionContext): Promise<void> {
    if (!branch.actions || branch.actions.length === 0) {
      Logger.warn(TAG, 'Branch has no actions');
      return;
    }

    Logger.info(TAG, `Executing ${branch.actions.length} actions in branch`);

    for (let i = 0; i < branch.actions.length; i++) {
      const actionConfig = branch.actions[i];

      // 构造 Action 对象（临时的，不存入数据库）
      const action: Action = {
        id: -1,  // 临时ID
        macroId: context.getMacroId(),
        type: actionConfig.type,
        config: JSON.stringify(actionConfig.config),
        orderIndex: i
      };

      try {
        await this.actionExecutor.execute(action, context);
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        Logger.error(TAG, `Branch action ${actionConfig.type} failed: ${errorMessage}`);
        throw error;  // 向上传播错误
      }
    }

    Logger.info(TAG, 'Branch execution completed');
  }
}
```

---

## 三、ActionTypes 常量更新

文件路径: `entry/src/main/ets/constants/ActionTypes.ts`

在第 13 行后增加：

```typescript
export class ActionTypes {
  // ... 现有常量 ...
  static readonly SET_VARIABLE = 'set_variable';
  static readonly IF_ELSE = 'if_else';  // 🆕 新增

  static getAll(): string[] {
    return [
      // ... 现有类型 ...
      ActionTypes.SET_VARIABLE,
      ActionTypes.IF_ELSE  // 🆕 新增
    ];
  }

  static getDisplayName(type: string): string {
    switch (type) {
      // ... 现有 case ...
      case ActionTypes.SET_VARIABLE:
        return '设置变量';
      case ActionTypes.IF_ELSE:  // 🆕 新增
        return '条件分支';
      default:
        return '未知类型';
    }
  }
}
```

---

## 四、注册执行器

文件路径: `entry/src/main/ets/entryability/EntryAbility.ts`

在第 97 行后增加：

```typescript
// 导入
import { IfElseAction } from '../services/actions/IfElseAction';

// 注册执行器
private async initializeApp(context: Context): Promise<void> {
  // ... 现有代码 ...

  const actionExecutor = ActionExecutor.getInstance();
  // ... 现有注册 ...
  actionExecutor.registerExecutor(ActionType.SET_VARIABLE, new SetVariableAction());
  actionExecutor.registerExecutor(ActionType.IF_ELSE, new IfElseAction());  // 🆕 新增
}
```

---

## 五、"快小红"配置示例

```json
{
  "name": "快小红",
  "description": "从小红书采集内容到飞书",
  "triggers": [{"type": "manual"}],
  "actions": [
    {
      "type": "clipboard_read",
      "config": {"saveToVariable": "clipboard_content"}
    },
    {
      "type": "text_process",
      "config": {
        "operation": "regex_extract",
        "pattern": "https?://[^\\s]+",
        "input": "{clipboard_content}",
        "saveToVariable": "url"
      }
    },
    {
      "type": "if_else",
      "config": {
        "branches": [
          {
            "name": "商品采集",
            "conditions": [
              {"field": "{url}", "operator": "contains", "value": "goods-detail"}
            ],
            "actions": [
              {
                "type": "notification",
                "config": {"title": "开始采集商品", "content": "正在上传..."}
              },
              {
                "type": "http_request",
                "config": {
                  "method": "POST",
                  "url": "https://api.coze.cn/v1/workflow/run",
                  "headers": {"Authorization": "Bearer {token}"},
                  "body": "{\"workflow_id\":\"{flowgoods}\",\"parameters\":{...}}",
                  "saveToVariable": "response"
                }
              },
              {
                "type": "notification",
                "config": {"title": "✅ 商品采集成功", "content": "{response}"}
              }
            ]
          },
          {
            "name": "博主采集",
            "conditions": [
              {"field": "{url}", "operator": "contains", "value": "user"}
            ],
            "actions": [
              {
                "type": "http_request",
                "config": {
                  "method": "POST",
                  "url": "https://api.coze.cn/v1/workflow/run",
                  "body": "{\"workflow_id\":\"{flowbozhu}\",\"parameters\":{...}}"
                }
              }
            ]
          },
          {
            "name": "笔记采集（默认）",
            "conditions": [],
            "actions": [
              {
                "type": "user_dialog",
                "config": {
                  "type": "single_select",
                  "title": "请选择分类",
                  "options": ["💄时尚美妆", "🌍旅游出行"],
                  "saveToVariable": "category"
                }
              },
              {
                "type": "http_request",
                "config": {
                  "method": "POST",
                  "url": "https://api.coze.cn/v1/workflow/run",
                  "body": "{\"workflow_id\":\"{flownote}\",\"parameters\":{...}}"
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

## 六、实施步骤

| 步骤 | 文件 | 操作 | 状态 |
|-----|------|------|------|
| 1 | `models/Macro.ts` | 增加 IF_ELSE 枚举和接口 | ⏳ 待完成 |
| 2 | `services/actions/IfElseAction.ts` | 创建执行器 | ⏳ 待完成 |
| 3 | `constants/ActionTypes.ts` | 更新常量 | ⏳ 待完成 |
| 4 | `entryability/EntryAbility.ts` | 注册执行器 | ⏳ 待完成 |
| 5 | `models/ExecutionContext.ts` | 添加 getMacroId() 方法 | ⏳ 待完成 |
| 6 | 单元测试 | 编写测试用例 | ⏳ 待完成 |
| 7 | 集成测试 | "快小红"场景测试 | ⏳ 待完成 |

---

## 七、测试计划

### 7.1 单元测试

```typescript
// tests/IfElseAction.test.ts

describe('IfElseAction', () => {
  it('should execute first matching branch', async () => {
    const config = {
      branches: [
        {
          conditions: [{ field: '{var1}', operator: '==', value: '10' }],
          actions: [{ type: 'notification', config: { title: 'Branch 1' } }]
        },
        {
          conditions: [],  // else
          actions: [{ type: 'notification', config: { title: 'Else' } }]
        }
      ]
    };
    // ... 测试逻辑 ...
  });

  it('should execute else branch when no conditions match', async () => {
    // ... 测试逻辑 ...
  });

  it('should support nested IF_ELSE', async () => {
    // ... 测试逻辑 ...
  });
});
```

### 7.2 集成测试

使用"快小红"配置进行真实场景测试：
1. 复制商品链接 → 验证执行商品采集分支
2. 复制博主链接 → 验证执行博主采集分支
3. 复制笔记链接 → 验证执行笔记采集分支（弹出对话框）

---

## 八、风险与注意事项

### 8.1 性能风险

- **嵌套深度**: 限制嵌套层级 ≤ 5 层，避免无限递归
- **条件数量**: 单个分支条件数量 ≤ 10 个

### 8.2 数据存储

IF_ELSE 动作的配置全部存储在 `action.config` 字段（JSON字符串），不需要新增数据库表。

### 8.3 UI 复杂度

MacroEditor 需要支持：
- 树形展示分支结构
- 拖拽添加分支内动作
- 条件编辑器

建议分阶段实现：
- 第一阶段：JSON 文本编辑（快速实现）
- 第二阶段：可视化编辑器（体验优化）

---

**文档版本**: v1.0
**最后更新**: 2026-01-08
**作者**: Claude Code
