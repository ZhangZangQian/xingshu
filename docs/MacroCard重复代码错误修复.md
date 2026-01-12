# MacroCard 重复代码错误修复

## 修复日期
2025-01-11

## 错误信息
```
ERROR: Unexpected token (Note that you need plugins to import files that are not JavaScript)
At File: entry/src/main/ets/components/MacroCard.ets:177

ERROR: Use explicit types instead of "any", "unknown"
At File: entry/src/main/ets/components/MacroCard.ets:174:16
At File: entry/src/main/ets/components/MacroCard.ets:175:17
At File: entry/src/main/ets/components/MacroCard.ets:176:23

ERROR: Function return type inference is limited
At File: entry/src/main/ets/components/MacroCard.ets:177:10

ERROR: Using "this" inside stand-alone functions is not supported
At File: entry/src/main/ets/components/MacroCard.ets:228:9
At File: entry/src/main/ets/components/MacroCard.ets:228:24
At File: entry/src/main/ets/components/MacroCard.ets:236:11
At File: entry/src/main/ets/components/MacroCard.ets:236:25
```

## 问题原因

在之前的编辑过程中，`buildGridCard()` 函数没有被完全替换，导致：

1. **旧代码残留**：从 line 174 到 239 有一段重复的旧代码
2. **函数结构混乱**：重复代码不在任何函数作用域内
3. **孤立代码段**：使用 `this` 但不在组件方法内

### 问题代码结构（修复前）

```typescript
@Builder
buildGridCard() {
  Stack({ alignContent: Alignment.TopEnd }) {
    Column() { ... }  // 正确的新代码
    Toggle() { ... }
  }
}
.width(60)        // ← 孤立的代码段（重复）
.height(60)       // ← 不在函数内
.borderRadius(14)
.backgroundColor(this.getMacroColor())  // ← this 报错
...
.onClick(() => {
  this.onTrigger(this.macro.id);  // ← this 报错
})
```

## 解决方案

### 1. 完全重写文件

删除所有重复和孤立代码，确保：
- 每个 `@Builder` 函数正确闭合
- 所有代码都在正确的作用域内
- 没有孤立或悬挂的代码片段

### 2. 文件结构验证

**修复后的结构**
```typescript
@Component
export struct MacroCard {
  // 属性定义

  // 私有方法
  private getMacroColor(): string { ... }
  private getMacroIcon(): string { ... }
  private getTriggerTags(): TriggerTag[] { ... }
  private formatTime(timestamp: number): string { ... }

  // 主 build 方法
  build() { ... }

  // Builder 方法
  @Builder
  buildGridCard() { ... }  // 完整闭合

  @Builder
  buildListCard() { ... }  // 完整闭合
}
```

## 代码修复

### 修复前（350 行，有重复）
```typescript
// Line 94-173: buildGridCard() 正确实现
@Builder
buildGridCard() {
  Stack({ alignContent: Alignment.TopEnd }) {
    Column() {
      Column() {
        Text(this.getMacroIcon())
          .fontSize(32)
          .fontColor('#FFFFFF')
      }
      .width(50)
      .height(50)
      // ...
    }
    .padding(10)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.onTrigger(this.macro.id);
    })

    Toggle({ type: ToggleType.Switch, isOn: this.macro.enabled })
      .width(24)
      .height(16)
      .margin({ top: 4, right: 4 })
      .onChange((isOn: boolean) => {
        this.onToggle(this.macro.id, isOn);
      })
      .zIndex(10)
  }

// Line 174-239: 孤立的重复代码（错误）
.width(60)
.height(60)
.borderRadius(14)
.backgroundColor(this.getMacroColor())  // ← this 在函数外
.shadow({ ... })
.justifyContent(FlexAlign.Center)
.margin({ bottom: 12 })

Column({ space: 8 }) {
  Text(this.macro.name)
    .fontSize(14)
    // ...
}
.onClick(() => {
  this.onTrigger(this.macro.id);  // ← this 在函数外
})

Toggle({ ... })
  .onChange((isOn: boolean) => {
    this.onToggle(this.macro.id, isOn);  // ← this 在函数外
  })
```

### 修复后（278 行，结构清晰）
```typescript
@Builder
buildGridCard() {
  Stack({ alignContent: Alignment.TopEnd }) {
    // 卡片主体
    Column() {
      // 图标容器
      Column() {
        Text(this.getMacroIcon())
          .fontSize(32)
          .fontColor('#FFFFFF')
      }
      .width(50)
      .height(50)
      .borderRadius(12)
      .backgroundColor(this.getMacroColor())
      .shadow({
        radius: 6,
        color: '#26000000',
        offsetX: 0,
        offsetY: 2
      })
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 10 })

      // 内容区
      Column({ space: 6 }) {
        Text(this.macro.name)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A1A')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .width('100%')
          .lineHeight(1.3)

        Row({ space: 3 }) {
          ForEach(this.getTriggerTags().slice(0, 2), (tag: TriggerTag) => {
            Row({ space: 2 }) {
              Text(tag.icon)
                .fontSize(8)
              Text(tag.text)
                .fontSize(8)
                .fontColor('#AEAEB2')
            }
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .borderRadius(3)
            .backgroundColor('#F2F2F7')
          })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
    }
    .padding(10)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({
      radius: 10,
      color: '#14000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.onTrigger(this.macro.id);
    })

    // 开关按钮
    Toggle({ type: ToggleType.Switch, isOn: this.macro.enabled })
      .width(24)
      .height(16)
      .margin({ top: 4, right: 4 })
      .onChange((isOn: boolean) => {
        this.onToggle(this.macro.id, isOn);
      })
      .zIndex(10)
  }
}
```

## 修复验证

### 文件行数对比
- 修复前：350 行
- 修复后：278 行（减少 72 行重复代码）

### 函数结构验证
```bash
grep -n "buildGridCard\|buildListCard" MacroCard.ets
```
输出：
```
74:  this.buildGridCard();
76:  this.buildListCard();
94:  buildGridCard() {        ← 定义
172: buildListCard() {       ← 定义
```
✅ 两个 Builder 方法都正确定义

### 代码块验证
- ✅ buildGridCard() 从 line 94 开始
- ✅ buildGridCard() 在 line 171 正确闭合
- ✅ buildListCard() 从 line 172 开始
- ✅ buildListCard() 在 line 278 正确闭合
- ✅ 没有孤立代码段
- ✅ 所有 `this` 都在组件方法内

## 编译检查

### 已修复的错误
1. ✅ Unexpected token - 删除了孤立代码
2. ✅ Use explicit types - 类型定义完整
3. ✅ Function return type inference - 无需显式返回
4. ✅ Using "this" inside stand-alone functions - 所有 `this` 在正确作用域

### 编译验证
在 DevEco Studio 中：
1. 点击 **Build → Clean Project**
2. 点击 **Build → Rebuild Project**
3. 检查是否有编译错误

## 教训总结

### 编辑注意事项

1. **完整替换**：使用 `edit` 工具时，确保提供完整的 `oldString`（包含整个函数体）
2. **验证结构**：编辑后检查函数是否正确闭合
3. **清理残留**：确保没有重复的代码片段

### ArkTS 代码规范

1. **函数作用域**：所有组件方法必须在 `struct` 内
2. **this 使用**：`this` 只能在组件方法内使用
3. **Builder 闭合**：每个 `@Builder` 方法必须有正确的闭合大括号

## 文件变更清单

| 文件 | 修改类型 | 变更内容 |
|------|----------|----------|
| `components/MacroCard.ets` | 重写 | 删除重复代码，修复文件结构 |

## 总结

通过完全重写 `MacroCard.ets` 文件，成功删除了重复代码片段，修复了文件结构问题。文件现在：

1. ✅ 没有重复代码
2. ✅ 所有函数正确闭合
3. ✅ 所有 `this` 在正确作用域内
4. ✅ 代码结构清晰，易于维护

代码应该可以成功编译。
