# HarmonyOS Next 系统图标使用指南

## 概述

HarmonyOS Next 提供了丰富的系统图标资源，开发者可以通过 `SymbolGlyph` 组件轻松使用这些图标。

## SymbolGlyph 组件

### 基本用法

```typescript
SymbolGlyph($r('sys.symbol.图标名称'))
  .fontSize(24)
  .fontColor(['#607AFB'])
```

### 参数说明

- **$r('sys.symbol.图标名称')**：引用系统图标资源
- **fontSize**：图标大小
- **fontColor**：图标颜色，支持数组实现渐变
- **fontWeight**：图标粗细
- **renderingStrategy**：渲染策略（单色、多色、分层）
- **effectStrategy**：动效策略
- **symbolEffect**：自定义动效

### 图标资源名称

系统图标资源名称可以从 [HarmonyOS Symbol 图标库](https://developer.huawei.com/consumer/cn/design/harmonyos-symbol/) 获取。

#### 常用图标分类

##### 系统UI (108个)
- `airplane_fill` - 飞机
- `arrow_clockwise` - 顺时针箭头
- `battery` - 电池
- `bell_fill` - 铃铛（填充）
- `checkmark` - 对勾
- `search` - 搜索
- `settings` - 设置
- `home` - 主页

##### 时间 (12个)
- `clock` - 时钟
- `alarm` - 闹钟
- `hourglass` - 沙漏

##### 编辑 (41个)
- `pencil` - 铅笔
- `trash` - 垃圾桶
- `textformat` - 文本格式

##### 媒体 (31个)
- `play_circle` - 播放圆圈
- `pause_circle` - 暂停圆圈
- `music_note` - 音符
- `speaker` - 扬声器

##### 通信 (25个)
- `message` - 消息
- `mail` - 邮件
- `phone` - 电话

### 获取图标名称

1. 访问 [HarmonyOS Symbol 图标库](https://developer.huawei.com/consumer/cn/design/harmonyos-symbol/)
2. 浏览或搜索需要的图标
3. 点击图标
4. 点击"复制名称"按钮
5. 将名称粘贴到代码中

## 在项目中使用

### 示例代码

```typescript
// 在 Index.ets 中使用系统图标

@Builder
  Header() {
    Row() {
      Text('My Shortcuts')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Button() {
        SymbolGlyph($r('sys.symbol.plus_circle_fill'))
          .fontSize(24)
          .fontColor(['#607AFB'])
      }
      .type(ButtonType.Normal)
      .backgroundColor('rgba(96, 122, 251, 0.1)')
      .borderRadius(999)
      .width(40)
      .height(40)
      .stateEffect(true)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 48, bottom: 8 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

@Builder
  SearchBar() {
    Row() {
      Row() {
        SymbolGlyph($r('sys.symbol.search'))
          .fontSize(20)
          .fontColor(['#9CA3AF'])
          .margin({ left: 16, right: 12 })

        TextInput({ placeholder: 'Search your library...', text: this.searchText })
          .placeholderColor('#6B7280')
          .backgroundColor('transparent')
          .border({ width: 0 })
          .layoutWeight(1)
          .fontSize(14)
          .fontColor('#111827')
          .onChange((value: string) => {
            this.searchText = value;
          })
      }
      .width('100%')
      .height(44)
      .backgroundColor('#E5E7EB')
      .borderRadius(12)
      .alignItems(VerticalAlign.Center)
      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
  }

@Builder
  BottomNavigation() {
    Row() {
      this.TabItem(0, 'square_grid_2x2_fill', 'My Flows', true)
      this.TabItem(1, 'photo_fill', 'Gallery', false)
      this.TabItem(2, 'settings', 'Settings', false)
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 12, bottom: 24 })
    .justifyContent(FlexAlign.SpaceAround)
    .backgroundColor('rgba(255, 255, 255, 0.95)')
    .border({ width: { top: 1 }, color: 'rgba(0, 0, 0, 0.08)' })
    .backdropBlur(20)
    .position({ x: 0, y: '100%' })
    .translate({ y: '-100%' })
  }

@Builder
  TabItem(index: number, iconName: string, label: string, isActive: boolean) {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.' + iconName))
          .fontSize(20)
          .fontColor([isActive ? '#607AFB' : '#9CA3AF'])
      }
      .width(48)
      .height(32)
      .borderRadius(999)
      .backgroundColor(isActive ? 'rgba(96, 122, 251, 0.15)' : 'transparent')
      .justifyContent(FlexAlign.Center)
      .stateEffect(true)
      .onClick(() => {
        this.activeTab = index;
      })

      Text(label)
        .fontSize(10)
        .fontWeight(isActive ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(isActive ? '#607AFB' : '#6B7280')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
  }
```

### 渲染策略

```typescript
// 单色渲染
SymbolGlyph($r('sys.symbol.图标名称'))
  .renderingStrategy(SymbolRenderingStrategy.SINGLE)
  .fontColor(['#607AFB'])

// 多色渲染
SymbolGlyph($r('sys.symbol.图标名称'))
  .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_COLOR)
  .fontColor(['#607AFB', '#A855F7', '#EC4899'])

// 分层渲染
SymbolGlyph($r('sys.symbol.图标名称'))
  .renderingStrategy(SymbolRenderingStrategy.MULTIPLE_OPACITY)
  .fontColor(['#607AFB', '#A855F7', '#EC4899'])
```

### 动效策略

```typescript
// 无动效
SymbolGlyph($r('sys.symbol.图标名称'))
  .effectStrategy(SymbolEffectStrategy.NONE)

// 整体缩放动效
SymbolGlyph($r('sys.symbol.图标名称'))
  .effectStrategy(SymbolEffectStrategy.SCALE)

// 层级动效
SymbolGlyph($r('sys.symbol.图标名称'))
  .effectStrategy(SymbolEffectStrategy.HIERARCHICAL)
```

### 自定义动效

```typescript
@State isActive: boolean = false;

SymbolGlyph($r('sys.symbol.wifi'))
  .fontSize(96)
  .symbolEffect(new HierarchicalSymbolEffect(EffectFillStyle.ITERATIVE), this.isActive)

Button(this.isActive ? '关闭' : '播放').onClick(() => {
  this.isActive = !this.isActive;
})
```

## SymbolSpan 组件

`SymbolSpan` 可以在文本中穿插显示图标：

```typescript
Text() {
  SymbolSpan($r('sys.symbol.star_fill'))
    .fontSize(24)
    .fontColor(['#FBBF24'])

  Text(' 收藏')
    .fontSize(16)
}
```

## 注意事项

1. **API 版本要求**：`SymbolGlyph` 组件从 API 11 开始支持
2. **图标名称**：确保使用正确的图标名称，区分大小写
3. **颜色数组**：`fontColor` 支持数组，用于多色和分层渲染
4. **性能优化**：大量使用图标时，建议使用缓存
5. **兼容性**：确保目标设备支持所使用的图标

## 参考资源

- [HarmonyOS Symbol 图标库](https://developer.huawei.com/consumer/cn/design/harmonyos-symbol/)
- [SymbolGlyph 开发文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-symbolglyph)
- [HarmonyOS 使用系统图标](https://developer.huawei.com/consumer/cn/blog/topic/03175778118834116)
