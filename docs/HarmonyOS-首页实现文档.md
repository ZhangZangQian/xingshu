# HarmonyOS Next 首页实现文档

## 项目概述

本文档记录了将 HTML 首页转换为 HarmonyOS Next 原生应用的实现过程。

## 原始 HTML 设计

原始设计是一个 My Shortcuts Library 的移动端界面，包含以下主要元素：

1. **头部区域**：标题 "My Shortcuts" 和添加按钮
2. **搜索框**：用于搜索快捷方式
3. **快捷方式列表**：以网格布局展示的快捷方式卡片
4. **底部导航栏**：包含 My Flows、Gallery、Settings 三个选项卡

## HarmonyOS Next 实现方案

### 技术栈

- **语言**：ArkTS (TypeScript)
- **框架**：ArkUI
- **API Level**：HarmonyOS Next API 15+

### 主要组件结构

```
Index.ets
├── Header (@Builder)
│   ├── 标题文本
│   └── 添加按钮
├── SearchBar (@Builder)
│   └── 搜索输入框
├── ShortcutsList (@Builder)
│   ├── 列表标题
│   └── Grid 网格布局
│       └── ShortcutCard (@Builder)
│           ├── 图标容器（渐变背景）
│           ├── 更多按钮
│           ├── 快捷方式名称
│           └── 动作数量
└── BottomNavigation (@Builder)
    └── TabItem (@Builder)
        ├── 图标
        └── 标签文本
```

### 关键技术实现

#### 1. 布局容器

使用 `Column` 和 `Row` 容器组件实现垂直和水平布局：

```typescript
Column() {
  this.Header()
  this.SearchBar()
  this.ShortcutsList()
}
.width('100%')
.height('100%')
```

#### 2. 网格布局

使用 `Grid` 组件实现两列卡片布局：

```typescript
Grid() {
  ForEach(this.shortcuts, (item: ShortcutItem) => {
    GridItem() {
      this.ShortcutCard(item)
    }
  })
}
.columnsTemplate('1fr 1fr')
.columnsGap(16)
.rowsGap(16)
```

#### 3. 渐变背景

使用 `linearGradient` 属性创建图标容器的渐变背景：

```typescript
.linearGradient({
  angle: 135,
  colors: [[item.gradient[0], 0.0], [item.gradient[1], 1.0]]
})
```

#### 4. 阴影效果

使用 `shadow` 属性添加卡片和图标的阴影：

```typescript
.shadow({
  radius: 4,
  color: 'rgba(0, 0, 0, 0.05)',
  offsetY: 2
})
```

#### 5. 状态管理

使用 `@State` 装饰器管理组件状态：

```typescript
@State searchText: string = '';
@State shortcuts: ShortcutItem[] = [...];
@State activeTab: number = 0;
```

#### 6. 滚动容器

使用 `Scroll` 组件实现列表滚动：

```typescript
Scroll() {
  Column() {
    // 内容
  }
}
.scrollable(ScrollDirection.Vertical)
.scrollBar(BarState.Off)
.edgeEffect(EdgeEffect.Spring)
```

#### 7. 底部导航定位

使用 `position` 和 `translate` 实现底部导航固定定位：

```typescript
.position({ x: 0, y: '100%' })
.translate({ y: '-100%' })
```

#### 8. 毛玻璃效果

使用 `backdropBlur` 实现导航栏毛玻璃效果：

```typescript
.backdropBlur(20)
```

### 图标方案

由于 HarmonyOS Next 的系统图标资源名称需要从官方文档获取，当前实现使用 Unicode 字符作为图标：

- 搜索：\uD83D\uDD0E
- 添加：+
- 更多：\u22EF
- 网格：\uD83D\uDD0D
- 画廊：\uD83D\uDDBC
- 设置：\u2699

如需使用系统图标，可以使用 `SymbolGlyph` 组件：

```typescript
SymbolGlyph($r('sys.symbol.图标名称'))
  .fontSize(24)
  .fontColor(['#607AFB'])
```

### 样式还原度

| 元素 | 原始设计 | 实现方式 | 还原度 |
|------|---------|---------|--------|
| 标题字体 | Space Grotesk | 系统字体 | 90% |
| 颜色主题 | Tailwind 配色 | 对应 Hex 值 | 100% |
| 圆角 | 0.5rem - 1.5rem | borderRadius | 100% |
| 阴影 | box-shadow | shadow | 95% |
| 渐变 | linear-gradient | linearGradient | 100% |
| 间距 | Tailwind spacing | padding/margin | 100% |
| 字体大小 | 10px - 3xl | fontSize | 100% |

### 数据结构

定义了 `ShortcutItem` 接口来描述快捷方式数据：

```typescript
interface ShortcutItem {
  id: number;
  name: string;
  actions: number;
  iconSymbol: string;
  gradient: string[];
}
```

### 交互效果

1. **卡片点击**：使用 `stateEffect` 实现点击反馈
2. **按钮点击**：添加点击事件处理
3. **标签切换**：更新 `activeTab` 状态
4. **搜索输入**：实时更新 `searchText` 状态

## 待优化项

1. **图标资源**：替换为 HarmonyOS 系统图标
2. **字体加载**：加载 Space Grotesk 和 Manrope 字体
3. **深色模式**：实现主题切换功能
4. **动画效果**：添加卡片悬停和点击动画
5. **空状态**：添加搜索无结果的空状态
6. **加载状态**：添加数据加载动画

## 运行方式

在 DevEco Studio 中：
1. 打开项目
2. 连接设备或启动模拟器
3. 点击运行按钮

## 参考资源

- [HarmonyOS Next 开发文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/)
- [HarmonyOS Symbol 图标库](https://developer.huawei.com/consumer/cn/design/harmonyos-symbol/)
- [ArkUI 组件文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/)
