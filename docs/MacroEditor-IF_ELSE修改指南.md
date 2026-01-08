# MacroEditor.ets - 添加 IF_ELSE UI 支持

**文件**: `entry/src/main/ets/pages/MacroEditor.ets`

**状态**: 需要手动修改（3处）

---

## 修改 1: 在按钮列表中添加 IF_ELSE 选项

**位置**: 第 764-771 行的 `handleAddAction()` 方法

**原代码**:
```typescript
buttons: [
  { text: '发送通知', color: '#000000' },
  { text: '读取剪贴板', color: '#000000' },
  { text: 'HTTP 请求', color: '#000000' },
  { text: '打开 URL', color: '#000000' },
  { text: '文本处理', color: '#000000' },
  { text: '设置变量', color: '#000000' }
]
```

**修改为**:
```typescript
buttons: [
  { text: '发送通知', color: '#000000' },
  { text: '读取剪贴板', color: '#000000' },
  { text: 'HTTP 请求', color: '#000000' },
  { text: '打开 URL', color: '#000000' },
  { text: '文本处理', color: '#000000' },
  { text: '设置变量', color: '#000000' },
  { text: '条件分支', color: '#000000' }  // 🆕 新增
]
```

---

## 修改 2: 在 switch 语句中添加处理逻辑

**位置**: 第 773-793 行的 `handleAddAction()` 方法内的 switch 语句

**原代码**:
```typescript
}).then((result) => {
  switch (result.index) {
    case 0:
      this.addNotificationAction();
      break;
    case 1:
      this.addClipboardReadAction();
      break;
    case 2:
      this.addHttpRequestAction();
      break;
    case 3:
      this.addOpenUrlAction();
      break;
    case 4:
      this.addTextProcessAction();
      break;
    case 5:
      this.addSetVariableAction();
      break;
  }
});
```

**修改为**:
```typescript
}).then((result) => {
  switch (result.index) {
    case 0:
      this.addNotificationAction();
      break;
    case 1:
      this.addClipboardReadAction();
      break;
    case 2:
      this.addHttpRequestAction();
      break;
    case 3:
      this.addOpenUrlAction();
      break;
    case 4:
      this.addTextProcessAction();
      break;
    case 5:
      this.addSetVariableAction();
      break;
    case 6:  // 🆕 新增
      this.addIfElseAction();
      break;
  }
});
```

---

## 修改 3: 添加 addIfElseAction() 方法

**位置**: 第 961 行后（在 `addSetVariableAction()` 方法之后）

**插入以下代码**:

```typescript
  /**
   * 添加条件分支动作
   */
  private addIfElseAction() {
    // 创建一个简单的 IF_ELSE 模板
    const action: Action = {
      id: Date.now(),
      macroId: this.macroId,
      type: ActionType.IF_ELSE,
      config: JSON.stringify({
        branches: [
          {
            name: '分支1',
            conditions: [
              {
                field: '{variable_name}',
                operator: '==',
                value: 'value1'
              }
            ],
            actions: [
              {
                type: 'notification',
                config: {
                  title: '分支1执行',
                  content: '条件满足时执行此分支',
                  enableSound: false,
                  enableVibration: false
                }
              }
            ]
          },
          {
            name: 'else分支',
            conditions: [],  // 空条件表示 else
            actions: [
              {
                type: 'notification',
                config: {
                  title: 'else分支执行',
                  content: '所有条件都不满足时执行此分支',
                  enableSound: false,
                  enableVibration: false
                }
              }
            ]
          }
        ]
      }),
      orderIndex: this.actions.length
    };
    this.actions.push(action);
    this.updateActionViewModels(); // 更新视图模型
    promptAction.showToast({ message: '条件分支动作已添加，请在配置面板编辑' });
  }
```

---

## 完整修改示例

为了方便理解，这里是 `handleAddAction()` 方法的完整修改版本：

```typescript
/**
 * 添加动作
 */
private handleAddAction() {
  // 显示动作类型选择对话框
  promptAction.showDialog({
    title: '选择动作类型',
    message: '请选择要添加的动作',
    buttons: [
      { text: '发送通知', color: '#000000' },
      { text: '读取剪贴板', color: '#000000' },
      { text: 'HTTP 请求', color: '#000000' },
      { text: '打开 URL', color: '#000000' },
      { text: '文本处理', color: '#000000' },
      { text: '设置变量', color: '#000000' },
      { text: '条件分支', color: '#000000' }  // 🆕 新增
    ]
  }).then((result) => {
    switch (result.index) {
      case 0:
        this.addNotificationAction();
        break;
      case 1:
        this.addClipboardReadAction();
        break;
      case 2:
        this.addHttpRequestAction();
        break;
      case 3:
        this.addOpenUrlAction();
        break;
      case 4:
        this.addTextProcessAction();
        break;
      case 5:
        this.addSetVariableAction();
        break;
      case 6:  // 🆕 新增
        this.addIfElseAction();
        break;
    }
  });
}
```

---

## 测试步骤

完成修改后，请按以下步骤测试：

### 1. 构建项目

```bash
hvigor assembleHap --mode module -p module=entry@default -p product=default
```

### 2. 运行应用

在 DevEco Studio 中点击 Run 按钮

### 3. 创建测试宏

1. 点击 "+" 创建新宏
2. 填写宏名称：`IF_ELSE 测试`
3. 添加触发器：手动触发
4. 点击"+ 添加动作"按钮
5. **预期结果**: 应该看到"条件分支"选项

### 4. 添加条件分支动作

1. 选择"条件分支"
2. **预期结果**:
   - 动作列表中出现新的"条件分支"动作卡片
   - 显示 Toast："条件分支动作已添加，请在配置面板编辑"

### 5. 配置条件分支

1. 点击条件分支动作卡片
2. 在配置面板中编辑 JSON 配置（目前是文本编辑模式）
3. 可以参考模板修改条件和动作

### 6. 保存并执行测试

1. 保存宏
2. 手动触发执行
3. **预期结果**: 根据条件执行对应分支

---

## 故障排查

### 问题1: 点击"条件分支"后应用崩溃

**原因**: ActionType.IF_ELSE 未在 Macro.ts 中定义

**解决**: 确认已在 `entry/src/main/ets/models/Macro.ts` 第 111 行添加：
```typescript
IF_ELSE = 'if_else'
```

### 问题2: 编译错误 "Cannot find name 'ActionType.IF_ELSE'"

**原因**: 枚举值未导出或拼写错误

**解决**: 检查 import 语句，确认：
```typescript
import { Action, ActionType } from '../models/Macro';
```

### 问题3: 动作添加后无法配置

**原因**: ActionConfigEditor 尚未支持 IF_ELSE 类型的可视化编辑

**解决**:
- 当前版本：使用 JSON 文本直接编辑
- 未来版本：可开发可视化分支编辑器（建议使用树形组件）

---

## 下一步优化（可选）

如果想要更好的用户体验，可以实现可视化的分支编辑器：

### ActionConfigEditor.ets 增强

在 `ActionConfigEditor.ets` 中增加 IF_ELSE 专用配置 UI：

```typescript
@Component
struct IfElseBranchEditor {
  @Link branches: Branch[];

  build() {
    Column() {
      // 分支列表
      ForEach(this.branches, (branch: Branch, index: number) => {
        Column() {
          Text(branch.name || `分支 ${index + 1}`)
          // 条件编辑器
          // 动作列表编辑器
          // 添加/删除分支按钮
        }
      })

      // 添加分支按钮
      Button('+ 添加分支')
    }
  }
}
```

**工作量估算**: 1-2天

---

## 快速验证脚本

如果想快速测试 IF_ELSE 功能，可以通过数据库直接插入测试宏：

```typescript
// 在 DatabaseService 中添加测试方法
async createTestIfElseMacro(): Promise<void> {
  const macroId = await this.insertMacro({
    name: 'IF_ELSE 快速测试',
    description: '自动创建的测试宏',
    enabled: true,
    createdAt: Date.now(),
    updatedAt: Date.now()
  });

  await this.insertAction({
    macroId: macroId,
    type: ActionType.IF_ELSE,
    config: JSON.stringify({
      branches: [
        {
          name: '测试分支',
          conditions: [{ field: 'test', operator: '==', value: 'hello' }],
          actions: [
            { type: 'notification', config: { title: '成功', content: 'IF_ELSE 工作正常' } }
          ]
        }
      ]
    }),
    orderIndex: 0
  });
}
```

---

**文档版本**: v1.0
**最后更新**: 2026-01-08
**完成后请验证**: 能够在动作列表中看到"条件分支"选项
