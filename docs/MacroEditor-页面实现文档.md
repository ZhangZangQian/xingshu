# MacroEditor 页面实现文档

## 概述

MacroEditor 是一个工作流编辑器页面，用于编辑和配置自动化工作流程。该页面展示了复杂的工作流结构，包括触发器（Trigger）、动作（Actions）和条件判断块（Condition Block）。

## 页面结构

### 主要组件

```
MacroEditor
├── Header（顶部导航栏）
│   ├── 返回按钮
│   ├── 标题（工作流名称 + 标签）
│   └── 完成按钮
├── Content（主内容区）
│   ├── TriggerSection（触发器区域）
│   │   ├── 标题 "TRIGGER"
│   │   └── TriggerCard（触发器卡片）
│   ├── ActionsSection（动作区域）
│   │   ├── 标题 "ACTIONS"
│   │   └── ActionItemCard（动作卡片列表）
│   │       ├── ActionCard（普通动作）
│   │       └── ConditionBlock（条件块）
│   │           ├── 嵌套动作
│   │           └── EndIfCard（结束条件）
│   └── AddActionButton（添加动作按钮）
├── GradientOverlay（底部渐变遮罩）
└── BottomPanel（底部操作面板）
    ├── 统计信息
    ├── 撤销/重做按钮
    └── 播放按钮
```

## 数据结构

### ActionItem

```typescript
interface ActionItem {
  id: number;                          // 动作 ID
  type: 'trigger' | 'action' | 'condition' | 'nested';  // 动作类型
  title: string;                       // 动作标题
  icon: string;                        // 图标（Unicode 字符）
  iconColor: string;                   // 图标颜色
  description?: string;                // 描述信息
  children?: ActionItem[];             // 子动作（用于条件块）
}
```

## 样式系统

### 颜色配置

| 用途 | 颜色值 | 说明 |
|------|--------|------|
| 背景色 | #F2F2F7 | iOS 系统浅灰 |
| 表面色 | #FFFFFF | 白色卡片 |
| 主色 | #007AFF | iOS 蓝色 |
| 触发器色 | #FF9500 | iOS 橙色/黄色 |
| 边框色 | #E5E5EA | 浅灰边框 |
| 文字主色 | #000000 | 黑色文字 |
| 文字次色 | #8E8E93 | 灰色文字 |

### 卡片样式

#### TriggerCard（触发器卡片）
- 背景：白色
- 边框：2px 橙色半透明
- 圆角：12px
- 阴影：柔和阴影
- 图标：橙色背景 + 白色图标

#### ActionCard（动作卡片）
- 背景：白色
- 边框：1px 浅灰
- 圆角：12px
- 阴影：柔和阴影
- 图标：白色边框 + 彩色图标

#### ConditionBlock（条件块）
- 包含条件判断和嵌套动作
- 支持多层嵌套
- 自动缩进显示层级关系

## 关键技术实现

### 1. 路由导航

```typescript
// 导入路由模块
import router from '@ohos.router';

// 页面跳转
router.pushUrl({
  url: 'pages/MacroEditor',
  params: {
    title: item.name
  }
});

// 接收参数
aboutToAppear() {
  const params = router.getParams() as Record<string, Object>;
  if (params && params['title']) {
    this.title = params['title'] as string;
  }
}

// 返回上一页
router.back();
```

### 2. 滚动容器

```typescript
Scroll() {
  // 内容
}
.scrollable(ScrollDirection.Vertical)
.scrollBar(BarState.Off)
.edgeEffect(EdgeEffect.Spring)
```

### 3. 渐变遮罩

```typescript
.linearGradient({
  direction: GradientDirection.Bottom,
  colors: [['#F2F2F7', 0.0], ['rgba(242, 242, 247, 0.8)', 0.5], ['rgba(242, 242, 247, 0.0)', 1.0]]
})
.position({ x: 0, y: '100%' })
.translate({ y: '-100%' })
```

### 4. 固定定位

使用 `position` 和 `translate` 实现底部面板固定定位：

```typescript
.position({ x: 0, y: '100%' })
.translate({ y: '-100%' })
```

### 5. 毛玻璃效果

```typescript
.backdropBlur(20)
.backgroundColor('rgba(255, 255, 255, 0.8)')
```

### 6. 条件渲染

```typescript
if (item.type === 'condition') {
  this.ConditionBlock(item, index)
} else {
  this.ActionCard(item, index)
}
```

### 7. 列表渲染

```typescript
ForEach(this.actions.slice(1), (item: ActionItem, index: number) => {
  this.ActionItemCard(item, index)
})
```

## 页面交互

### 按钮交互

1. **返回按钮**：点击返回上一页
2. **完成按钮**：点击返回上一页
3. **添加动作按钮**：预留交互接口
4. **撤销/重做按钮**：预留交互接口
5. **播放按钮**：预留交互接口

### 卡片交互

- 所有卡片支持点击交互（预留）
- 拖拽手柄显示（仅视觉）

## 布局特点

### 1. 嵌套结构

支持条件块的嵌套动作，通过 `children` 属性实现：

```typescript
{
  type: 'condition',
  title: 'Scripting',
  children: [
    { type: 'nested', title: 'Send Message' }
  ]
}
```

### 2. 固定面板

- 顶部导航栏固定
- 底部操作面板固定
- 中间内容可滚动

### 3. 圆角设计

- 顶部导航栏：无圆角
- 底部面板：大圆角（32px）
- 卡片：中等圆角（12px）

## 图标方案

当前使用 Unicode 字符作为图标：

| 图标 | Unicode | 用途 |
|------|---------|------|
| ‹ | \u2039 | 返回箭头 |
| ⋮ | \u22EE | 更多选项 |
| ⋯ | \u22EF | 更多选项（水平） |
| ☰ | \u2630 | 拖拽手柄 |
| ⏰ | \u23F0 | 闹钟 |
| ☀️ | \u2600 | 天气/太阳 |
| ↺ | \u21A9 | 撤销 |
| ↻ | \u21AA | 重做 |
| ▶ | \u25B6 | 播放 |

建议在生产环境中替换为 HarmonyOS 系统图标。

## 待优化项

### 功能优化

- [ ] 连接线的实现（卡片之间的连接线）
- [ ] 添加动作功能
- [ ] 编辑动作功能
- [ ] 删除动作功能
- [ ] 拖拽排序功能
- [ ] 撤销/重做功能
- [ ] 播放/测试工作流

### UI 优化

- [ ] 卡片连接线绘制
- [ ] 动画效果（展开/折叠）
- [ ] 长按拖拽反馈
- [ ] 空状态展示
- [ ] 加载状态
- [ ] 错误状态

### 性能优化

- [ ] 虚拟列表（大量动作时）
- [ ] 图片资源懒加载
- [ ] 状态管理优化

## 注意事项

1. **路由配置**：需要在 `main_pages.json` 中注册页面
2. **参数传递**：使用 `router.pushUrl` 传递参数
3. **页面生命周期**：使用 `aboutToAppear` 接收参数
4. **返回导航**：使用 `router.back()` 返回
5. **滚动区域**：注意底部面板的遮挡，增加底部内边距

## 与首页的集成

首页的快捷方式卡片点击后跳转到 MacroEditor 页面：

```typescript
// Index.ets
.onClick(() => {
  router.pushUrl({
    url: 'pages/MacroEditor',
    params: {
      title: item.name  // 传递快捷方式名称作为标题
    }
  });
})
```

## 参考资源

- [HarmonyOS Next 路由文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/router-0000001538082129-V5)
- [ArkUI 滚动组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/ts-container-scroll-V5)
- [ArkUI 样式文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-apply-style-to-page-V5)

## 文件位置

- 页面文件：`entry/src/main/ets/pages/MacroEditor.ets` (579 行)
- 路由配置：`entry/src/main/resources/base/profile/main_pages.json`
