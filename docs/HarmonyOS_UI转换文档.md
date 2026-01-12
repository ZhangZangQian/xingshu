# HarmonyOS Next UI 转换文档

## 项目概述

将 HTML/Tailwind CSS 的快捷方式库界面转换为 HarmonyOS Next ArkUI 声明式 UI。

## 技术栈

- **框架**: ArkUI (HarmonyOS Next 声明式 UI 开发框架)
- **语言**: ArkTS (基于 TypeScript 扩展)
- **状态管理**: @State 装饰器
- **布局**: Column, Row, Grid, Stack, Flex

## 核心组件映射

### HTML → ArkUI 组件对应关系

| HTML 元素 | ArkUI 组件 | 说明 |
|----------|-----------|------|
| `<header>` | `Column` + `Row` | 顶部标题栏 |
| `<nav>` | `Row` + `Column` | 底部导航栏 |
| `<main>` | `Scroll` + `Column` | 主内容区域 |
| `<div class="grid">` | `Grid` + `GridItem` | 网格布局 |
| `<input>` | `TextInput` | 搜索输入框 |
| `<button>` | `Button` | 按钮 |
| `<img>` | `Image` | 图片资源 |
| CSS 类 | `@Styles` / `@Builder` | 样式复用 |

## 文件结构

```
harmony_shortcuts.ets  # 主页面组件
├── @Entry @Component struct ShortcutsLibrary  # 入口组件
├── @State shortcuts  # 快捷方式数据
├── @State searchValue  # 搜索状态
├── @State activeNavIndex  # 导航状态
└── @Builder methods  # UI 构建方法
```

## 关键实现细节

### 1. 主题颜色系统

```typescript
// 使用系统主题色
$r('sys.color.ohos_id_color_primary')        // 主色调 #607AFB
$r('sys.color.ohos_id_color_sub_background')  // 背景色 #f5f6f8 / #0f1323
$r('sys.color.ohos_id_color_card_bg')        // 卡片背景 #ffffff / #282c31
$r('sys.color.ohos_id_color_text_primary')   // 主文本色
$r('sys.color.ohos_id_color_text_secondary') // 次要文本色
```

### 2. 响应式布局

```typescript
// 2列网格布局
Grid() {
  ForEach(this.shortcuts, (item) => {
    GridItem() { this.ShortcutCard(item) }
  })
}
.columnsTemplate('1fr 1fr')
.columnsGap(16)
.rowsGap(16)
```

### 3. 渐变背景

```typescript
.linearGradient({
  direction: GradientDirection.BottomRight,
  colors: item.iconBgGradient  // ['#FF9F5E', '#FFB800']
})
```

### 4. 阴影效果

```typescript
.shadow({
  radius: 16,
  color: item.iconBgGradient[0].toString(),
  offsetX: 0,
  offsetY: 4
})
```

### 5. 状态管理

```typescript
@State searchValue: string = ''  // 搜索框状态
@State activeNavIndex: number = 0  // 导航选中状态
@State shortcuts: ShortcutItem[] = [...]  // 列表数据
```

## 样式还原对比

### 卡片样式

| 属性 | HTML/CSS | ArkUI |
|------|----------|-------|
| 圆角 | `rounded-2xl` | `borderRadius(20)` |
| 内边距 | `p-4` | `padding(16)` |
| 边框 | `border-gray-100` | `border({ width: 1, color: ... })` |
| 阴影 | `shadow-sm` | `shadow({ radius: 4, ... })` |
| 交互 | `active:scale-[0.98]` | `stateEffect: true` |
| 悬停效果 | `group-hover:text-primary` | `onClick` + 状态变化 |

### 搜索框样式

| 属性 | HTML/CSS | ArkUI |
|------|----------|-------|
| 圆角 | `rounded-xl` | `borderRadius(16)` |
| 高度 | `py-3.5` + 字体 | `height(48)` |
| 图标位置 | `pl-11` | `padding({ left: 44 })` |
| 占位符颜色 | `placeholder:text-gray-500` | `placeholderColor(...)` |

### 导航栏样式

| 属性 | HTML/CSS | ArkUI |
|------|----------|-------|
| 背景 | `backdrop-blur-lg` | 系统默认毛玻璃效果 |
| 定位 | `absolute bottom-0` | `position({ y: '100%' })` |
| 图标容器 | `h-8 w-12` | `width(48) height(32)` |
| 激活状态 | `bg-primary/15` | `backgroundColor(...) opacity(0.15)` |

## 数据结构

```typescript
interface ShortcutItem {
  id: string          // 唯一标识
  title: string       // 标题
  actionCount: number // 动作数量
  icon: string        // 图标(emoji 或资源路径)
  iconBgGradient: ResourceColor[] // 渐变色数组
  hasPlayButton?: boolean // 是否显示播放按钮
}
```

## 使用说明

### 1. 创建项目

```bash
# 使用 DevEco Studio 创建新的 HarmonyOS Next 项目
# 选择 Empty 模板
# 语言选择 ArkTS
```

### 2. 添加文件

将 `harmony_shortcuts.ets` 放入项目的 `src/main/ets/pages/` 目录

### 3. 配置路由

在 `src/main/ets/entryability/EntryAbility.ets` 中配置页面路由

### 4. 运行调试

```bash
# 连接设备或模拟器
# 点击 Run 按钮或按 Ctrl+R
```

## 扩展功能建议

### 1. 搜索过滤

```typescript
@Builder
SearchSection() {
  TextInput({ placeholder: 'Search your library...', text: this.searchValue })
    .onChange((value: string) => {
      this.searchValue = value
      this.filterShortcuts()
    })
}

filterShortcuts() {
  if (this.searchValue) {
    this.filteredShortcuts = this.shortcuts.filter(item =>
      item.title.toLowerCase().includes(this.searchValue.toLowerCase())
    )
  } else {
    this.filteredShortcuts = this.shortcuts
  }
}
```

### 2. 暗色模式

```typescript
@StorageLink('themeMode') themeMode: ThemeColorMode = ThemeColorMode.LIGHT

// 在 build() 中
.backgroundColor(this.themeMode === ThemeColorMode.DARK
  ? $r('sys.color.ohos_id_color_sub_background')
  : Color.White)
```

### 3. 下拉刷新

```typescript
@Builder
ShortcutsGridSection() {
  Refresh({ refreshing: false }) {
    Scroll() {
      // 内容
    }
  }
  .onStateChange((refreshing: boolean) => {
    if (refreshing) {
      // 执行刷新逻辑
    }
  })
}
```

### 4. 长按菜单

```typescript
.gesture(
  LongPressGesture({ repeat: false })
    .onAction(() => {
      this.showContextMenu(item)
    })
)

showContextMenu(item: ShortcutItem) {
  // 使用 promptAction 或自定义弹窗
}
```

## 性能优化

### 1. 列表懒加载

```typescript
LazyForEach(new DataDataSource(this.shortcuts), (item: ShortcutItem) => {
  GridItem() {
    this.ShortcutCard(item)
  }
}, (item: ShortcutItem) => item.id)
```

### 2. 图片缓存

使用 `Image` 组件的 `cacheStrategy` 属性

### 3. 动画优化

使用 `animateTo` 替代直接状态变化，启用硬件加速

## 兼容性说明

- **最低版本**: HarmonyOS NEXT 5.0
- **推荐版本**: HarmonyOS NEXT 5.0.3+
- **屏幕适配**: 支持响应式布局，适配不同屏幕尺寸
- **主题支持**: 完整支持浅色/深色主题

## 注意事项

1. **图标资源**: 当前使用 emoji 替代，生产环境建议使用 SVG 或 PNG 资源
2. **字体**: 使用系统默认字体，可自定义引入外部字体
3. **导航**: 需要配合路由系统实现页面跳转
4. **交互反馈**: 使用 `stateEffect` 和 `onClick` 提供反馈

## 测试建议

1. **单元测试**: 测试数据过滤、状态管理逻辑
2. **UI测试**: 使用 UI Testing 框架测试交互
3. **性能测试**: 滚动流畅度、内存占用
4. **兼容性测试**: 不同设备、不同系统版本

## 参考资料

- [HarmonyOS Next 官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/)
- [ArkUI 组件库](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-overview)
- [ArkTS 语言规范](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-get-started)