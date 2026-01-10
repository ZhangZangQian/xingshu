# ExecutionLogDetail 页面复制功能

## 功能概述

在执行日志详情页（ExecutionLogDetail.ets）中，为输入数据和输出数据添加了复制按钮，方便用户快速复制日志内容。

## 实现的功能

### 1. 导入 ClipboardService

```typescript
import { ClipboardService } from '../services/ClipboardService';
```

### 2. 添加 ClipboardService 实例

```typescript
private clipboardService: ClipboardService = ClipboardService.getInstance();
```

### 3. 新增 copyData 方法

```typescript
/**
 * 复制数据到剪贴板
 */
private async copyData(data: string, dataType: string): Promise<void> {
  try {
    await this.clipboardService.writeText(data);
    promptAction.showToast({ message: `${dataType} 已复制到剪贴板` });
    Logger.info('ExecutionLogDetail', `Copied ${dataType}: ${data.substring(0, 50)}...`);
  } catch (error) {
    const errorMsg = (error as Error).message || 'Unknown error';
    Logger.error('ExecutionLogDetail', `Failed to copy ${dataType}: ${errorMsg}`);
    promptAction.showToast({ message: `复制失败: ${errorMsg}` });
  }
}
```

### 4. 输入数据复制按钮

在"输入数据"标题旁边添加了"复制"按钮：

```typescript
Column({ space: 6 }) {
  Row() {
    Text('输入数据')
      .fontSize(13)
      .fontColor('#666666')
      .fontWeight(FontWeight.Medium)
      .layoutWeight(1)

    Button('复制')
      .fontSize(11)
      .fontColor('#007DFF')
      .backgroundColor(Color.Transparent)
      .height(28)
      .onClick(() => {
        this.copyData(this.formatJsonData(actionLog.inputData), '输入数据');
      })
  }
  .width('100%')

  Text(this.formatJsonData(actionLog.inputData))
    .fontSize(12)
    .fontColor('#333333')
    .fontFamily('monospace')
    .lineHeight(18)
    .padding(12)
    .backgroundColor('#F5F7FA')
    .borderRadius(6)
    .width('100%')
}
```

### 5. 输出数据复制按钮

在"输出数据"标题旁边添加了"复制"按钮：

```typescript
if (actionLog.outputData) {
  Column({ space: 6 }) {
    Row() {
      Text('输出数据')
        .fontSize(13)
        .fontColor('#666666')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)

      Button('复制')
        .fontSize(11)
        .fontColor('#007DFF')
        .backgroundColor(Color.Transparent)
        .height(28)
        .onClick(() => {
          this.copyData(this.formatJsonData(actionLog.outputData), '输出数据');
        })
    }
    .width('100%')

    Text(this.formatJsonData(actionLog.outputData))
      .fontSize(12)
      .fontColor('#333333')
      .fontFamily('monospace')
      .lineHeight(18)
      .padding(12)
      .backgroundColor('#F5F7FA')
      .borderRadius(6)
      .width('100%')
  }
  .width('100%')
  .alignItems(HorizontalAlign.Start)
}
```

## 功能特性

### 1. 一键复制

- 点击"复制"按钮即可将数据复制到剪贴板
- 自动显示成功提示："输入数据已复制到剪贴板"或"输出数据已复制到剪贴板"

### 2. 错误处理

- 如果复制失败，会显示错误提示："复制失败: <错误信息>"
- 同时在日志中记录错误详情

### 3. 日志记录

- 成功复制时记录：`Copied <数据类型>: <数据前50个字符>...`
- 失败时记录：`Failed to copy <数据类型>: <错误信息>`

### 4. 用户体验

- 按钮样式：透明背景，蓝色文字
- 按钮高度：28px，与文本对齐
- 字体大小：11px，保持一致性
- Toast 提示：清晰告知用户复制结果

## 使用场景

### 场景 1：复制输入数据

1. 打开执行日志详情页
2. 展开某个动作的详情
3. 点击"输入数据"旁边的"复制"按钮
4. 数据自动复制到剪贴板
5. 看到提示："输入数据已复制到剪贴板"

### 场景 2：复制输出数据

1. 打开执行日志详情页
2. 展开某个动作的详情
3. 点击"输出数据"旁边的"复制"按钮
4. 数据自动复制到剪贴板
5. 看到提示："输出数据已复制到剪贴板"

### 场景 3：复制失败处理

1. 如果系统剪贴板权限被拒绝
2. 看到提示："复制失败: <错误信息>"
3. 可以查看日志了解详细错误

## 技术细节

### ClipboardService 调用

```typescript
await this.clipboardService.writeText(data);
```

### Toast 提示

```typescript
promptAction.showToast({ message: `${dataType} 已复制到剪贴板` });
```

### 日志记录

```typescript
Logger.info('ExecutionLogDetail', `Copied ${dataType}: ${data.substring(0, 50)}...`);
```

## 代码位置

- **文件**：`entry/src/main/ets/pages/ExecutionLogDetail.ets`
- **新增方法**：`copyData(data: string, dataType: string)`
- **修改位置**：
  - 第 22 行：添加 clipboardService 实例
  - 第 214-224 行：添加 copyData 方法
  - 第 519-543 行：输入数据部分添加复制按钮
  - 第 554-581 行：输出数据部分添加复制按钮

## 注意事项

1. **剪贴板权限**
   - 确保应用有剪贴板访问权限
   - 在 module.json5 中声明权限（如果需要）

2. **空数据处理**
   - 如果 inputData 或 outputData 为空或 undefined，`formatJsonData` 会返回 "无"
   - 点击复制按钮会复制"无"字符串

3. **格式化数据**
   - `formatJsonData` 方法会将 JSON 字符串格式化为可读格式
   - 如果 JSON 解析失败，返回原始字符串

4. **并发复制**
   - 用户可以连续点击多次复制按钮
   - 每次点击都会覆盖剪贴板中的内容

## 测试建议

### 1. 功能测试

- [ ] 点击输入数据复制按钮，验证数据是否正确复制
- [ ] 点击输出数据复制按钮，验证数据是否正确复制
- [ ] 验证 Toast 提示是否正确显示
- [ ] 验证日志是否正确记录

### 2. 边界测试

- [ ] 复制空数据
- [ ] 复制超长数据
- [ ] 复制特殊字符数据
- [ ] 复制非 JSON 格式数据

### 3. 错误处理测试

- [ ] 剪贴板权限被拒绝时的行为
- [ ] 剪贴板服务不可用时的行为

---

**文档版本**：1.0
**最后更新**：2026-01-10
**作者**：Claude Code
