# stopPropagation 错误修复

## 修复日期
2025-01-11

## 错误信息
```
ERROR: 10505001 ArkTS Compiler Error
Error Message: Property 'stopPropagation' does not exist on type 'ClickEvent'.
At File: entry/src/main/ets/components/MacroCard.ets:168:17
```

## 问题原因
在 ArkTS 中，`ClickEvent` 类型不支持 `stopPropagation()` 方法。HarmonyOS 的事件处理机制与 Web 标准不同。

## 解决方案

### 优化前（错误代码）
```typescript
Toggle({ type: ToggleType.Switch, isOn: this.macro.enabled })
  .width(28)
  .height(18)
  .margin({ top: 6, right: 6 })
  .onChange((isOn: boolean) => {
    this.onToggle(this.macro.id, isOn);
  })
  .zIndex(10)
  .onClick((event: ClickEvent) => {
    event.stopPropagation();  // 错误：ClickEvent 没有 stopPropagation
  })
```

### 优化后（正确代码）
```typescript
Toggle({ type: ToggleType.Switch, isOn: this.macro.enabled })
  .width(28)
  .height(18)
  .margin({ top: 6, right: 6 })
  .onChange((isOn: boolean) => {
    this.onToggle(this.macro.id, isOn);
  })
  .zIndex(10)  // 移除 onClick 和 stopPropagation
```

## 技术说明

### ArkTS 事件处理

1. **Toggle 组件的 onChange 事件**
   - 已经处理了开关的交互
   - 不会触发父组件的 onClick 事件
   - 不需要额外的 stopPropagation

2. **zIndex 优先级**
   - `zIndex: 10` 确保开关在卡片上层
   - 开关区域优先响应点击事件

3. **事件冒泡机制**
   - ArkTS 的组件默认支持事件冒泡
   - 但交互组件（如 Toggle、Button）会拦截事件
   - 不需要手动调用 stopPropagation

### HarmonyOS 与 Web 的差异

| 特性 | Web (DOM) | HarmonyOS (ArkTS) |
|------|------------|-------------------|
| 事件对象 | Event | ClickEvent / TouchEvent |
| stopPropagation | 支持 | 不支持 |
| 事件拦截 | 手动 | 自动（交互组件） |

## 验证

### 编译检查
- ✅ 编译器不再报错
- ✅ 代码符合 ArkTS 规范

### 功能检查
- ✅ 开关切换功能正常
- ✅ 卡片点击功能正常
- ✅ 两个点击事件不会相互干扰

## 文件变更清单

| 文件 | 修改类型 | 变更内容 |
|------|----------|----------|
| `components/MacroCard.ets` | 修改 | 移除 onClick 和 stopPropagation |

## 总结

移除了 ArkTS 不支持的 `stopPropagation` 调用。Toggle 组件的 `onChange` 事件已经正确处理了开关交互，不会触发父组件的 `onClick` 事件，因此不需要额外的防冒泡逻辑。

代码现在符合 ArkTS 编译规范，可以成功编译。
