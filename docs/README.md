# HarmonyOS Next My Shortcuts App

## 项目简介

这是一个基于 HarmonyOS Next 开发的快捷方式管理应用，展示了将 Web 设计转换为原生 HarmonyOS 应用的实现过程。项目包含两个主要页面：

1. **首页 (Index)**：快捷方式列表展示
2. **编辑器页 (MacroEditor)**：工作流编辑器

## 功能特性

### 首页
- ✅ 响应式首页布局
- ✅ 快捷方式网格展示
- ✅ 搜索功能
- ✅ 底部导航栏
- ✅ 卡片交互效果
- ✅ 滚动列表支持
- ✅ 毛玻璃效果
- ✅ 渐变背景和阴影

### 编辑器页
- ✅ 工作流编辑器布局
- ✅ 触发器卡片展示
- ✅ 动作卡片列表
- ✅ 条件块嵌套支持
- ✅ 固定底部操作面板
- ✅ 渐变遮罩效果
- ✅ 页面路由导航

## 技术栈

- **开发语言**：ArkTS (TypeScript)
- **UI 框架**：ArkUI
- **API Level**：HarmonyOS Next API 15+
- **IDE**：DevEco Studio 5.0+

## 项目结构

```
xingshu_v2/
├── entry/
│   └── src/
│       └── main/
│           ├── ets/
│           │   ├── entryability/
│           │   │   └── EntryAbility.ets
│           │   └── pages/
│           │       ├── Index.ets          # 首页
│           │       └── MacroEditor.ets    # 编辑器页
│           └── resources/
│               ├── base/
│               │   ├── element/
│               │   │   ├── color.json
│               │   │   ├── float.json
│               │   │   ├── string.json
│               │   │   └── main_pages.json  # 路由配置
│               │   └── media/
│               └── dark/
├── html/
│   ├── index.html                        # 首页原始 HTML
│   └── macro_editor.html                 # 编辑器页原始 HTML
├── docs/                                 # 项目文档
│   ├── README.md
│   ├── HarmonyOS-首页实现文档.md
│   ├── MacroEditor-页面实现文档.md
│   ├── HarmonyOS-系统图标使用指南.md
│   ├── 项目完成总结.md
│   └── HarmonyOS_UI转换文档.md
├── AppScope/
├── build-profile.json5
└── oh-package.json5
```

## 快速开始

### 环境要求

- DevEco Studio 5.0.3 或更高版本
- HarmonyOS Next SDK
- Node.js 16.x 或更高版本

### 安装步骤

1. 克隆或下载项目
2. 使用 DevEco Studio 打开项目
3. 等待依赖自动下载
4. 连接设备或启动模拟器
5. 点击运行按钮

### 项目配置

```json5
// build-profile.json5
{
  "apiType": "stageMode",
  "buildOption": {},
  "targets": [
    {
      "name": "default"
    }
  ]
}
```

## 主要组件

### Index.ets（首页）

应用首页组件，包含以下部分：

#### 1. Header（头部）

显示应用标题和添加按钮。

#### 2. SearchBar（搜索栏）

提供搜索输入框，支持实时搜索。

#### 3. ShortcutsList（快捷方式列表）

以网格布局展示快捷方式卡片，支持滚动。

#### 4. BottomNavigation（底部导航）

固定底部的导航栏，包含三个选项卡。

### MacroEditor.ets（编辑器页）

工作流编辑器组件，包含以下部分：

#### 1. Header（顶部导航栏）

返回按钮、工作流标题、完成按钮。

#### 2. TriggerSection（触发器区域）

显示工作流的触发器（如时间触发器）。

#### 3. ActionsSection（动作区域）

显示工作流的动作列表，支持条件块嵌套。

#### 4. AddActionButton（添加动作按钮）

用于添加新的动作到工作流中。

#### 5. BottomPanel（底部操作面板）

显示统计信息、撤销/重做按钮、播放按钮。

## 数据结构

### ShortcutItem（首页）

```typescript
interface ShortcutItem {
  id: number;        // 快捷方式 ID
  name: string;      // 快捷方式名称
  actions: number;   // 包含的动作数量
  iconSymbol: string; // 图标符号
  gradient: string[];// 渐变颜色数组
}
```

### ActionItem（编辑器页）

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

| 用途 | 颜色值 |
|------|--------|
| 主色 | #607AFB |
| 背景色 | #F5F6F8 |
| 卡片背景 | #FFFFFF |
| 文字主色 | #111827 |
| 文字次色 | #6B7280 |
| 边框色 | rgba(0, 0, 0, 0.06) |

### 间距系统

| 大小 | 值 |
|------|-----|
| xs | 4px |
| sm | 8px |
| md | 12px |
| lg | 16px |
| xl | 20px |
| 2xl | 24px |

## 图标方案

当前版本使用 Unicode 字符作为图标占位符。生产环境建议使用 HarmonyOS 系统图标：

```typescript
// 使用系统图标
SymbolGlyph($r('sys.symbol.search'))
  .fontSize(20)
  .fontColor(['#9CA3AF'])
```

详细说明请参考 [HarmonyOS-系统图标使用指南.md](./docs/HarmonyOS-系统图标使用指南.md)

## 交互效果

### 首页交互

#### 卡片点击

```typescript
.onClick(() => {
  router.pushUrl({
    url: 'pages/MacroEditor',
    params: {
      title: item.name
    }
  });
})
```

#### 标签切换

```typescript
.onClick(() => {
  this.activeTab = index;
})
```

#### 搜索输入

```typescript
.onChange((value: string) => {
  this.searchText = value;
})
```

### 编辑器页交互

#### 页面导航

```typescript
// 返回上一页
router.back();

// 接收参数
aboutToAppear() {
  const params = router.getParams() as Record<string, Object>;
  if (params && params['title']) {
    this.title = params['title'] as string;
  }
}
```

## 性能优化

1. **懒加载**：使用 `ForEach` 的第三个参数作为 key
2. **滚动优化**：设置 `edgeEffect(EdgeEffect.Spring)`
3. **隐藏滚动条**：设置 `scrollBar(BarState.Off)`

## 待实现功能

### 首页

- [ ] 添加快捷方式功能
- [ ] 编辑快捷方式
- [ ] 删除快捷方式
- [ ] 搜索过滤
- [ ] 深色模式切换
- [ ] 数据持久化
- [ ] 动画效果增强
- [ ] 空状态展示
- [ ] 加载状态

### 编辑器页

- [ ] 连接线绘制（卡片之间的连接线）
- [ ] 添加动作功能
- [ ] 编辑动作功能
- [ ] 删除动作功能
- [ ] 拖拽排序功能
- [ ] 撤销/重做功能
- [ ] 播放/测试工作流
- [ ] 条件块展开/折叠
- [ ] 长按拖拽反馈

## 文档

- [README.md](./README.md) - 项目说明
- [HarmonyOS-首页实现文档.md](./HarmonyOS-首页实现文档.md) - 首页详细的实现说明
- [MacroEditor-页面实现文档.md](./MacroEditor-页面实现文档.md) - 编辑器页详细的实现说明
- [HarmonyOS-系统图标使用指南.md](./HarmonyOS-系统图标使用指南.md) - 系统图标使用方法
- [项目完成总结.md](./项目完成总结.md) - 项目完成情况总结

## 参考资源

- [HarmonyOS Next 官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/)
- [HarmonyOS Symbol 图标库](https://developer.huawei.com/consumer/cn/design/harmonyos-symbol/)
- [ArkUI 组件文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/)

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue
- 发送邮件
- 加入讨论组
