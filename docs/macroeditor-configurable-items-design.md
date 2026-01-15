# MacroEditor 可配置项设计技术方案

## 一、需求背景

### 1.1 当前问题

MacroEditor 页面中的 Trigger 和 Action 列表使用硬编码的描述文本，存在以下问题：

- **可配置项无法直观展示**：例如时间触发器的 "At 7:00 AM Daily" 是一个固定字符串，无法单独编辑每个部分
- **交互缺失**：用户无法点击配置项进行编辑（如时间触发器的时间、重复周期）
- **配置数据不完整**：configs 元数据在模型中存在，但未被传递和使用
- **UI 表现不一致**：与 HTML 原型设计存在差距，无法展示如 "at Current Location" 的组合配置

### 1.2 设计目标

参考 `html/macro_editor.html` 的 UI 效果，实现：

1. **结构化配置展示**：将配置分解为多个可交互的"芯片"（Chip）或标签
2. **灵活的配置编辑**：支持点击配置项直接编辑，或展开面板进行复杂配置
3. **预留数据接口**：配置数据结构支持未来持久化
4. **输入校验**：在需要时进行数据校验，防止无效输入
5. **可扩展架构**：未来新增 Trigger/Action 时，只需添加配置模板即可

---

## 二、技术选型

### 2.1 交互方案选择

**选择：卡片下方展开面板**

**优点：**
- 上下文完整，能清晰看到配置属于哪个节点
- 空间足够，可展示多个配置项
- 与现有卡片 UI 风格一致
- 支持直接点击芯片快速编辑，或展开面板批量编辑

---

## 三、数据模型设计

### 3.1 UI 层数据模型

MacroEditor 页面内部使用的数据结构（不直接持久化）：

```typescript
// UI 层工作流项（避免与 WorkflowModels.ActionItem 命名冲突）
interface UIWorkflowItem {
  id: string;
  type: 'trigger' | 'action' | 'condition' | 'nested';
  title: string;
  icon: string;
  iconColor: string;
  description?: string;
  avatar?: string;
  message?: string;

  // 配置展示（UI 渲染用）
  configDisplay?: ConfigDisplayItem[];

  // 配置值（运行时存储，预留持久化接口）
  config?: Record<string, string | number | boolean>;

  children?: UIWorkflowItem[];
}

// 配置展示项
interface ConfigDisplayItem {
  // 展示类型
  displayType: 'text' | 'button' | 'tag' | 'icon-tag' | 'avatar-tag';

  // 显示内容（动态更新）
  label: string;

  // 配置键（对应 config 中的键名）
  configKey?: string;

  // 可选样式
  style?: {
    backgroundColor?: string;  // 如 '#EFF6FF'
    textColor?: string;       // 如 '#2563EB'
    borderColor?: string;     // 如 '#BFDBFE'
    icon?: string;          // Unicode 图标，如 '\uF56E'
    avatar?: {             // 圆形头像标签
      letter: string;       // 首字母
      bgColor: string;      // 头像背景色
      textColor: string;    // 头像文字颜色
    };
  };

  // 校验规则（可选）
  validation?: {
    type: 'string' | 'number' | 'boolean';
    required?: boolean;
    pattern?: string;  // 正则表达式
    min?: number;
    max?: number;
  };
}
```

### 3.2 配置模板注册表

在 `data/ConfigTemplates.ets` 中定义各 Trigger/Action 的配置展示模板：

```typescript
export const CONFIG_DISPLAY_TEMPLATES: Record<string, ConfigDisplayItem[]> = {
  'time_date': [
    {
      displayType: 'button',
      label: 'At',
      configKey: 'timeType',
      style: { backgroundColor: '#FFF0D6', textColor: '#FF9500' }
    },
    {
      displayType: 'button',
      label: '7:00 AM',
      configKey: 'timeValue',
      style: { backgroundColor: '#FFF0D6', textColor: '#FF9500' },
      validation: { type: 'string', required: true, pattern: '^[0-9]{1,2}:[0-9]{2}\\s*(AM|PM)?$' }
    },
    {
      displayType: 'button',
      label: 'Daily',
      configKey: 'repeat',
      style: { backgroundColor: '#FFF0D6', textColor: '#FF9500' }
    }
  ],

  'weather': [
    {
      displayType: 'text',
      label: 'at'
    },
    {
      displayType: 'icon-tag',
      label: 'Current Location',
      configKey: 'location',
      style: {
        backgroundColor: '#EFF6FF',
        textColor: '#2563EB',
        borderColor: '#BFDBFE',
        icon: '\uF56E'  // my_location
      }
    }
  ],

  'scripting': [
    {
      displayType: 'text',
      label: 'If'
    },
    {
      displayType: 'icon-tag',
      label: 'Temperature',
      configKey: 'variable',
      style: {
        backgroundColor: '#FEF3C7',
        textColor: '#D97706',
        borderColor: '#FDE68A',
        icon: '\uF595'  // sunny
      }
    },
    {
      displayType: 'text',
      label: 'is greater than'
    },
    {
      displayType: 'tag',
      label: '30°C',
      configKey: 'threshold',
      style: {
        backgroundColor: '#F3F4F6',
        textColor: '#000000',
        borderColor: '#E5E7EB'
      },
      validation: { type: 'number', min: -100, max: 100 }
    }
  ]
};
```

---

## 四、UI 设计

### 4.1 卡片结构

```
┌─────────────────────────────────┐
│ ⏰  When                ▼    │  ← 右上角展开按钮
├─────────────────────────────────┤
│ [At] [7:00 AM] [Daily]       │  ← 固定配置项展示
│  🟠    🟠        🟠          │
│                                 │
│ ┌─ Configuration ─────── ✕ ───┐│  ← 展开面板
│ │ timeType   [At ▼]          ││
│ │ timeValue  [7:00 AM]        ││
│ │ repeat    [Daily ▼]         ││
│ └───────────────────────────────┘│
└─────────────────────────────────┘
```

### 4.2 配置项展示样式

| 类型 | 样式 | 示例 |
|------|------|------|
| **text** | 灰色小字，无边框 | `at`、`If`、`is greater than` |
| **button** | 圆角按钮，带背景色 | `[At]`、`[7:00 AM]`、`[Daily]` |
| **icon-tag** | 圆角标签，带图标 | `[📍 Current Location]`、`[☀️ Temperature]` |
| **avatar-tag** | 圆角标签，带头像 | `[🟢 Mom]` |

### 4.3 展开面板布局

```
Configuration                                   ✕
──────────────────────────────────────────────────
timeType              [At ▼]
timeValue             [7:00 AM]
repeat                [Daily ▼]
```

---

## 五、UI 组件设计

### 5.1 状态管理

```typescript
// MacroEditor.ets
@State expandedConfigIds: Set<string> = new Set();  // 展开的卡片 ID 集合
```

### 5.2 配置芯片组件

```typescript
@Builder
ConfigDisplayChip(item: ConfigDisplayItem, configValue?: any, onEdit?: () => void) {
  if (item.displayType === 'text') {
    Text(item.label)
      .fontSize(12)
      .fontColor('#6B7280')
      .fontWeight(FontWeight.Medium)

  } else if (item.displayType === 'button') {
    Button(item.label) {
      Row({ space: 4 }) {
        if (item.style?.icon) {
          Text(item.style.icon)
            .fontSize(14)
            .fontColor(item.style.textColor)
        }
        Text(item.placeholder || item.label)
          .fontSize(12)
          .fontColor(item.style?.textColor || '#2563EB')
      }
    }
    .type(ButtonType.Normal)
    .backgroundColor(item.style?.backgroundColor || '#EFF6FF')
    .borderRadius(6)
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .border({
      width: 1,
      color: item.style?.borderColor || '#BFDBFE'
    })
    .onClick(() => {
      onEdit?.();
    })

  } else if (item.displayType === 'icon-tag') {
    Row({ space: 4 }) {
      if (item.style?.icon) {
        Text(item.style?.icon || '')
          .fontSize(12)
          .fontColor(item.style?.textColor)
      }
      Text(item.label)
        .fontSize(12)
        .fontColor(item.style?.textColor)
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(item.style?.backgroundColor)
    .borderRadius(6)
    .border({ width: 1, color: item.style?.borderColor })
    .onClick(() => {
      if (item.configKey && onEdit) {
        onEdit();
      }
    })

  } else if (item.displayType === 'avatar-tag') {
    Row({ space: 4 }) {
      Row() {
        Text(item.style?.avatar?.letter || '')
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor(item.style?.avatar?.textColor)
      }
      .width(16)
      .height(16)
      .borderRadius(999)
      .backgroundColor(item.style?.avatar?.bgColor)
      .justifyContent(FlexAlign.Center)

      Text(item.label)
        .fontSize(12)
        .fontColor(item.style?.textColor)
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(item.style?.backgroundColor)
    .borderRadius(6)
    .border({ width: 1, color: item.style?.borderColor })
    .onClick(() => {
      if (item.configKey && onEdit) {
        onEdit();
      }
    })
  }
}
```

### 5.3 配置面板组件

```typescript
@Builder
ExpandedConfigPanel(item: UIWorkflowItem) {
  Column() {
    Row() {
      Text('Configuration')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#6B7280')

      Blank()

      Button() {
        Text('✕')
          .fontSize(16)
          .fontColor('#9CA3AF')
      }
      .type(ButtonType.Normal)
      .backgroundColor('transparent')
      .onClick(() => {
        this.toggleConfigPanel(item.id, false);
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#E5E5EA' })

    ForEach(item.configDisplay || [], (configItem: ConfigDisplayItem) => {
      this.ConfigItemEditor(configItem, item)
    })
  }
  .width('100%')
  .backgroundColor('#F9FAFB')
  .borderRadius(12)
  .margin({ top: 8 })
}

@Builder
ConfigItemEditor(configItem: ConfigDisplayItem, item: UIWorkflowItem) {
  Row() {
    Text(configItem.configKey || '')
      .fontSize(14)
      .fontColor('#374151')
      .width(100)

    Blank()

    // 根据配置项类型显示不同的输入控件
    if (configItem.configKey && item.config) {
      this.ConfigValueInput(configItem, item.config[configItem.configKey] || '', (newValue) => {
        // 更新配置值（预留保存接口）
        item.config[configItem.configKey!] = newValue;
        // 更新显示文本
        configItem.label = this.formatDisplayValue(newValue);
      })
    }
  }
  .width('100%')
  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
}
```

### 5.4 配置值输入组件

```typescript
@Builder
ConfigValueInput(configItem: ConfigDisplayItem, currentValue: any, onChange: (value: any) => void) {
  // 预留：根据配置类型显示不同输入控件
  // 当前实现简单文本输入，后续可扩展为 Select、TimePicker 等

  TextInput({ text: String(currentValue) })
    .onChange((value: string) => {
      // 实时校验（仅手动输入时）
      if (this.validateConfigValue(configItem, value)) {
        onChange(value);
      }
    })
}
```

---

## 六、交互逻辑

### 6.1 卡片展开/收起

```typescript
toggleConfigPanel(itemId: string, forceState?: boolean) {
  const newState = forceState !== undefined ? forceState : !this.expandedConfigIds.has(itemId);

  if (newState) {
    this.expandedConfigIds.add(itemId);
  } else {
    this.expandedConfigIds.delete(itemId);
  }
}

isConfigExpanded(itemId: string): boolean {
  return this.expandedConfigIds.has(itemId);
}
```

### 6.2 配置编辑触发方式

#### 方式一：点击芯片直接编辑
- **适用场景**：select、time、location 等无需复杂输入的类型
- **交互流程**：
  1. 点击芯片（如 `[At]`）
  2. 弹出对应的选择器（Select、TimePicker、LocationPicker）
  3. 用户选择后，直接更新 `config` 和 `label`
  4. 可选展开面板验证结果

#### 方式二：展开面板编辑
- **适用场景**：需要输入文本、多步骤配置的项
- **交互流程**：
  1. 点击卡片右上角展开按钮（▼）
  2. 展开显示所有配置项
  3. 直接在面板中编辑（Select、TextInput、TimePicker 等）
  4. 实时校验并更新

### 6.3 配置更新流程

```typescript
updateConfigValue(item: UIWorkflowItem, configKey: string, newValue: any) {
  // 1. 校验（仅手动输入时）
  const configItem = item.configDisplay?.find(d => d.configKey === configKey);
  if (configItem && this.needsValidation(configItem)) {
    if (!this.validateConfigValue(configItem, newValue)) {
      showToast('输入无效');
      return;
    }
  }

  // 2. 更新配置值（预留持久化接口）
  item.config![configKey] = newValue;

  // 3. 更新显示文本
  if (configItem) {
    configItem.label = this.formatDisplayValue(newValue, configKey);
  }
}
```

### 6.4 校验策略

**何时校验：**

- ✅ 手动输入文本（TextInput）：需要校验格式、必填、数值范围
- ❌ 选择器生成值（Select、TimePicker、LocationPicker）：无需校验（控件保证有效值）
- ❌ 预设选项（radio、checkbox）：无需校验

**校验类型：**

```typescript
validateConfigValue(configItem: ConfigDisplayItem, value: string): boolean {
  if (!configItem.validation) return true;

  const rules = configItem.validation;

  // 必填校验
  if (rules.required && !value.trim()) {
    showToast('此配置项不能为空');
    return false;
  }

  // 类型校验
  if (rules.type === 'number') {
    const num = Number(value);
    if (isNaN(num)) {
      showToast('请输入有效的数字');
      return false;
    }
    if (rules.min !== undefined && num < rules.min) {
      showToast(`最小值为 ${rules.min}`);
      return false;
    }
    if (rules.max !== undefined && num > rules.max) {
      showToast(`最大值为 ${rules.max}`);
      return false;
    }
  }

  // 正则校验
  if (rules.pattern) {
    const regex = new RegExp(rules.pattern);
    if (!regex.test(value)) {
      showToast('格式不正确');
      return false;
    }
  }

  return true;
}
```

### 6.5 数据格式化

```typescript
formatDisplayValue(value: any, configKey?: string): string {
  // 根据配置键和值格式化显示文本
  // 预留扩展：支持时间格式化、数值单位等
  return String(value);
}
```

---

## 七、数据流转（UI 层）

### 7.1 Library → MacroEditor

```typescript
// TriggerLibrary.ets / ActionLibrary.ets
onClick(() => {
  router.back({
    url: 'pages/MacroEditor',
    params: {
      trigger: {
        id: item.id,
        type: 'trigger',
        title: item.name,
        icon: item.icon,
        iconColor: item.iconColor,
        description: 'When',

        // 传递配置模板
        configDisplay: CONFIG_DISPLAY_TEMPLATES[item.id],

        // 传递默认值
        config: this.getDefaultConfigValues(item)
      }
    }
  });
})

// 生成默认配置值
getDefaultConfigValues(item: TriggerItem): Record<string, Object> {
  const config: Record<string, Object> = {};
  item.configs?.forEach(c => {
    if (c.defaultValue !== undefined) {
      config[c.key] = c.defaultValue;
    }
  });
  return config;
}
```

### 7.2 预留保存接口

```typescript
// MacroEditor.ets

// 预留：将 UIWorkflowItem 转换为 WorkflowNode（持久化用）
convertUIItemToWorkflowNode(item: UIWorkflowItem): WorkflowNode {
  return {
    id: item.id,
    type: item.type,
    itemId: item.id,
    itemType: TriggerType.TIME_DATE, // 根据 item 映射
    title: item.title,
    icon: item.icon,
    iconColor: item.iconColor,
    description: item.description,
    config: item.config,  // 使用 Record
    configDisplay: item.configDisplay,  // UI 层用，持久化时忽略
    children: item.children?.map(c => this.convertUIItemToWorkflowNode(c))
  };
}

// 预留：保存工作流（调用 WorkflowDataManager）
async saveWorkflow() {
  // TODO: 实现 WorkflowNode 转换和保存
  console.info('[MacroEditor] Save workflow - 待实现持久化逻辑');
}
```

---

## 八、UI 组件修改

### 8.1 TriggerCard 改造

```typescript
@Builder
TriggerCard(item: UIWorkflowItem) {
  Column() {
    Row() {
      Row() {
        Text(item.icon)
          .fontSize(24)
          .fontColor('#FF9500')
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .backgroundColor('#FFF0D6')
      .justifyContent(FlexAlign.Center)

      Column() {
        Row() {
          Text(item.description || '')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9500')
            .letterSpacing(0.5)

          Blank()

          // 展开/收起按钮
          Button() {
            Text(this.isConfigExpanded(item.id) ? '▲' : '▼')
              .fontSize(12)
              .fontColor('#9CA3AF')
          }
          .type(ButtonType.Normal)
          .backgroundColor('#F3F4F6')
          .width(28)
          .height(28)
          .borderRadius(6)
          .onClick(() => {
            this.toggleConfigPanel(item.id);
          })
        }
        .width('100%')

        Text(item.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .border({ width: 2, color: 'rgba(255, 149, 0, 0.3)' })

    // 配置项展示区域
    if (item.configDisplay && item.configDisplay.length > 0) {
      Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
        ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
          this.ConfigDisplayChip(
            configItem,
            item.config?.[configItem.configKey || ''],
            () => {
              // 点击芯片编辑配置
              this.openConfigEditor(item, configItem);
            }
          )
        })
      }
      .margin({ top: 8 })
    }

    // 展开的详细配置面板
    if (this.isConfigExpanded(item.id)) {
      this.ExpandedConfigPanel(item)
    }
  }
  .width('100%')
  .borderRadius(12)
}
```

### 8.2 ActionCard 改造

```typescript
@Builder
ActionCard(item: UIWorkflowItem, index: number) {
  Stack() {
    Row() {
      // 图标部分（保持原有代码）
      // ...

      Column() {
        Row() {
          Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')

          Blank()

          // 配置项芯片
          if (item.configDisplay && item.configDisplay.length > 0) {
            Button() {
              Text('⚙️')
                .fontSize(14)
                .fontColor('#9CA3AF')
            }
            .type(ButtonType.Normal)
            .backgroundColor('transparent')
            .width(28)
            .height(28)
            .borderRadius(6)
            .onClick(() => {
              this.toggleConfigPanel(item.id);
            })
          }
        }
        .width('100%')

        // 配置项展示
        if (item.configDisplay) {
          Column() {
            if (item.configDisplay.some(d => d.displayType === 'text')) {
              // 混合展示：text + chip
              ForEach(item.configDisplay, (configItem: ConfigDisplayItem) => {
                this.ConfigDisplayChip(
                  configItem,
                  item.config?.[configItem.configKey || ''],
                  () => {
                    this.openConfigEditor(item, configItem);
                  }
                )
              })
            } else {
              // 消息展示（如果有）
              if (item.message) {
                // 保持原有 message 渲染
                // ...
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .border({ width: 1, color: '#E5E5EA' })

    // 展开的详细配置面板
    if (this.isConfigExpanded(item.id)) {
      this.ExpandedConfigPanel(item)
    }
  }
  .width('100%')
}
```

---

## 九、实现步骤

### 阶段一：模型和数据层

- [x] 在 `WorkflowModels.ets` 中新增 `ConfigDisplayItem` 接口
- [x] 创建 `MacroEditor.ets` 内部 `UIWorkflowItem` 接口
- [x] 创建 `data/ConfigTemplates.ets` 定义各触发器/动作的配置展示模板
- [x] 在 `TriggerItem`、`ActionItem` 的元数据中确保 `configs` 字段完整

### 阶段二：Library 层改造

- [x] 修改 `TriggerLibrary.ets` 返回时传递 `configDisplay` 和 `config`
- [x] 修改 `ActionLibrary.ets` 同样传递配置数据
- [x] 实现配置模板查找函数 `getConfigDisplayTemplate(itemId)`
- [x] 实现默认值生成函数 `getDefaultConfigValues(item)`

### 阶段三：MacroEditor UI 改造

- [x] 添加 `@State expandedConfigIds: string[]` 管理展开状态（使用数组替代 Set）
- [x] 实现 `ConfigDisplayChip` Builder
- [x] 实现 `ExpandedConfigPanel` Builder
- [x] 实现 `ConfigItemEditor` Builder
- [x] 实现 `ConfigValueInput` Builder
- [x] 在 `TriggerCard` 中集成配置展示和展开面板
- [x] 在 `ActionCard` 中集成配置展示和展开面板
- [x] 在 `ConditionBlock` 中集成配置展示和展开面板

### 阶段四：交互逻辑实现

- [x] 实现展开/收起逻辑 `toggleConfigPanel`
- [x] 实现配置编辑触发（通过 `toggleConfigPanel` 集成，无需单独的 `openConfigEditor`）
- [x] 实现配置更新流程 `updateConfigValue`
- [x] 实现输入校验 `validateConfigValue`（基础实现）
- [x] 实现数据格式化 `formatDisplayValue`（基础实现）

### 阶段五：预留持久化接口

- [x] 实现 `convertUIItemToWorkflowNode` 转换函数（`convertActionItemsToWorkflowNodes`）
- [x] 在 `saveWorkflow` 中预留持久化调用
- [x] 在 `loadWorkflowFromManager` 中预留数据加载逻辑

---

## 十、风险与注意事项

### 10.1 命名冲突

**问题**：`ActionItem` 在 `WorkflowModels.ets` 和 `MacroEditor.ets` 中定义不同

**解决**：MacroEditor.ets 中的接口命名为 `UIWorkflowItem`

### 10.2 配置值类型安全

**问题**：Record 类型为 `string | number | boolean`，运行时可能类型不匹配

**解决**：
- 在设置值时进行类型检查
- 使用 TypeScript 的类型守卫
- 在 UI 层根据配置元数据类型进行转换

### 10.3 配置模板维护

**问题**：新增 Trigger/Action 时需要手动添加配置模板

**解决**：
- 提供配置模板生成工具函数
- 使用约定优于配置（如根据 itemType 推断配置项）
- 文档化配置模板定义规范

### 10.4 展开状态管理

**问题**：Set 状态在 ForEach 中可能导致渲染异常

**解决**：
- 使用 `@State` 包装的数组 `expandedConfigIds: string[]`
- 使用 `expandedConfigIds.includes(itemId)` 判断
- 或使用 `@Observed` 类

---

## 十一、参考资料

- [Record vs Map - TypeScript 最佳实践](https://dev.to/lea_abraham_7a0232a6cd616/typescript-record-vs-map-whats-the-difference-and-when-to-use-each-50oj)
- [HarmonyOS UI 组件开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V2)

---

## 十二、附录

### 12.1 示例效果

#### 时间触发器卡片（收起状态）
```
┌─────────────────────────────────┐
│ ⏰  When                ⋮    │
├─────────────────────────────────┤
│ [At] [7:00 AM] [Daily]       │
│  🟠    🟠        🟠          │
└─────────────────────────────────┘
```

#### 天气动作卡片（展开状态）
```
┌─────────────────────────────────┐
│ ☀️ Get Current Weather   ▲  │
├─────────────────────────────────┤
│ at                              │
│ [📍 Current Location]           │
│   🔵                            │
│                                 │
│ ┌─ Configuration ─────── ✕ ───┐│
│ │ location    Current Location     ││
│ └───────────────────────────────┘│
└─────────────────────────────────┘
```

#### 脚本条件卡片（完整配置）
```
┌─────────────────────────────────┐
│ 🔄 Scripting             ⋮    │
├─────────────────────────────────┤
│ If [☀️ Temperature] is greater   │
│    than [30°C]                  │
│     🟠     🎨                 │
│                                 │
│ ┌─ Configuration ─────── ✕ ───┐│
│ │ variable    Temperature         ││
│ │ operator    greater than        ││
│ │ threshold   30               ││
│ └───────────────────────────────┘│
└─────────────────────────────────┘
```

### 12.2 配置校验规则示例

```typescript
// 时间格式校验
validation: {
  type: 'string',
  required: true,
  pattern: '^[0-9]{1,2}:[0-9]{2}\\s*(AM|PM)?$'
}

// 温度数值校验
validation: {
  type: 'number',
  min: -273,  // 绝对零度
  max: 1000
}

// 必填字段校验
validation: {
  type: 'string',
  required: true
}
```
