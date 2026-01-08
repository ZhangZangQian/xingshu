# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 HarmonyOS NEXT 原生自动化宏应用（类似 iOS 快捷指令），允许用户创建自动化工作流，通过触发器（定时、网络状态、手动）执行一系列动作（HTTP 请求、通知、剪贴板操作等）。

**关键信息**：
- 目标平台：HarmonyOS NEXT API 12 (targetSdkVersion: 6.0.1(21))
- 开发语言：ArkTS (TypeScript for HarmonyOS)
- 构建工具：Hvigor
- 包名：com.example.harmonymacro
- 项目状态：MVP 完成，待完善测试

## 构建和运行

### 开发环境
```bash
# 必需：DevEco Studio 4.0+
# 必需：HarmonyOS NEXT SDK API 12

# 运行应用（Debug 模式）
# 在 DevEco Studio 中点击 Run 按钮，或使用命令行：
"D:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon

# 构建 Release 版本
"D:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon --release

# 运行测试（单元测试）
# 在 entry/src/test/ 或 entry/src/ohosTest/ 目录下的测试文件
# 在 DevEco Studio 中右键测试文件 → Run Test
```

### 关键配置文件
- `entry/src/main/resources/base/profile/main_pages.json` - **页面路由配置（必需创建）**
- `entry/src/main/module.json5` - 模块配置（权限声明、Ability 配置）
- `build-profile.json5` - 构建配置
- `entry/oh-package.json5` - 依赖管理

## 核心架构

### 三层架构

```
UI 层 (pages/)
    ↓ 调用
服务层 (services/)
    ↓ 依赖
模型层 (models/)
```

### 核心执行流程

**宏执行引擎（MacroEngine）** 是整个应用的核心调度器：

1. **初始化阶段**（EntryAbility.onCreate）
   ```
   MacroEngine.initialize(context)
     → 初始化 DatabaseService
     → 加载所有已启用的宏
     → 注册触发器到 TriggerManager
   ```

2. **触发阶段**
   ```
   TriggerManager 监听系统事件（定时器、网络变化）
     → 触发条件满足时调用 MacroEngine.executeMacro(macroId, triggerType)
   ```

3. **执行阶段**
   ```
   MacroEngine.executeMacro()
     → 创建 ExecutionContext（变量上下文）
     → ConditionEvaluator 评估前置条件
     → ActionExecutor 顺序执行动作列表
     → 记录执行日志到数据库
     → 发送通知（成功或失败）
   ```

### 关键设计模式

#### 1. 单例模式（所有服务类）
所有核心服务都是单例：`MacroEngine`、`DatabaseService`、`TriggerManager`、`ActionExecutor`、`ConditionEvaluator`

#### 2. 策略模式（动作执行器）
每种动作类型（HTTP 请求、通知、剪贴板等）实现 `BaseAction` 接口，在 `EntryAbility.initializeApp()` 中注册到 `ActionExecutor`。

**注册示例**：
```typescript
// entry/src/main/ets/entryability/EntryAbility.ts:79-97
const actionExecutor = ActionExecutor.getInstance();
actionExecutor.registerExecutor(ActionType.LAUNCH_APP, new LaunchAppAction());
actionExecutor.registerExecutor(ActionType.NOTIFICATION, new NotificationAction());
// ... 注册其他动作执行器
```

#### 3. 观察者模式（触发器系统）
`TriggerManager` 监听系统事件（workScheduler、网络状态变化），当事件触发时回调 `MacroEngine.executeMacro()`。

#### 4. 依赖注入（Context 传递）
需要系统能力（启动应用、打开 URL）的动作执行器通过 `setContext(context)` 接收 UIAbility 上下文。

### 数据库设计

使用 HarmonyOS 关系型数据库（RDB），核心表：

- `macro` - 宏定义（名称、描述、启用状态）
- `trigger` - 触发器（定时、网络、手动）
- `action` - 动作列表（顺序执行）
- `condition` - 条件判断（可选，前置验证）
- `variable` - 变量（全局变量 + 宏级变量）
- `execution_log` - 执行日志

**数据库位置**：`/data/storage/el2/database/rdb/HarmonyMacro.db`

### 变量系统

支持两种变量：

1. **系统变量**（只读）：`{SYSTEM.CURRENT_TIME}`、`{SYSTEM.WIFI_SSID}` 等
2. **动作输出变量**：通过 `saveToVariable` 配置将动作结果存储为变量

**变量引用格式**：`{variable_name}`

**解析顺序**：
```
VariableParser.parseVariables(text, context)
  → 提取所有 {xxx} 变量引用
  → 优先查找系统变量
  → 其次查找执行上下文中的动态变量
  → 替换为实际值
```

## 常见开发场景

### 添加新的动作类型

1. 在 `entry/src/main/ets/constants/ActionTypes.ts` 添加类型常量
2. 在 `entry/src/main/ets/services/actions/` 创建新的动作执行器类
3. 实现 `BaseAction` 接口（`execute()` 方法）
4. 在 `EntryAbility.initializeApp()` 中注册执行器
5. 在 `MacroEditor.ets` 页面添加配置 UI

### 添加新的触发器类型

1. 在 `entry/src/main/ets/constants/TriggerTypes.ts` 添加类型常量
2. 在 `TriggerManager.ts` 的 `registerTrigger()` 方法中添加注册逻辑
3. 实现系统事件监听（workScheduler、网络状态变化等）
4. 在 `MacroEditor.ets` 页面添加配置 UI

### 修改变量解析逻辑

编辑 `entry/src/main/ets/utils/VariableParser.ts`，注意：
- 变量名格式：`{variable_name}`
- 系统变量优先于动态变量
- 未找到的变量保持原样（不替换）

### 调试宏执行流程

关键日志标签：
- `MacroEngine` - 宏执行引擎主流程
- `TriggerManager` - 触发器注册和触发事件
- `ActionExecutor` - 动作执行详情
- `ConditionEvaluator` - 条件判断结果
- `DatabaseService` - 数据库操作

在 DevEco Studio Hilog 面板按标签筛选日志。

## 重要约束和注意事项

### HarmonyOS NEXT 特有限制

1. **promptAction.showDialog 不支持输入**
   - 问题：系统对话框无法输入文本
   - 解决方案：使用页面内嵌编辑区域（参考 `GlobalVariables.ets`）

2. **UI 层无法直接调用服务层对话框**
   - 问题：服务层（如 `UserDialogAction`）无法直接弹出 UI 对话框
   - 解决方案：通过 `DialogEventBus` 反向依赖注入（计划实现）

3. **后台任务限制**
   - 定时触发器受系统电池优化影响
   - 需要在系统设置中允许后台运行

### 代码规范

- 类名：PascalCase（如 `MacroEngine`）
- 方法名：camelCase（如 `executeMacro`）
- 常量名：UPPER_SNAKE_CASE（如 `DB_NAME`）
- 文件名：PascalCase.ts/.ets（如 `MacroEngine.ts`）
- 页面组件使用 `.ets` 扩展名，服务类使用 `.ts` 扩展名

### 错误处理标准

所有异步方法必须使用 try-catch：
```typescript
try {
  // 业务逻辑
} catch (error) {
  Logger.error('ClassName', 'Method failed', error as Error);
  // 向用户展示友好提示
  promptAction.showToast({ message: '操作失败' });
}
```

## 当前已知问题（待修复）

1. **路由配置缺失**：需创建 `entry/src/main/resources/base/profile/main_pages.json`
2. **用户对话框集成未完成**：`UserDialogAction` 无法弹出对话框（需实现 DialogEventBus）
3. **测试覆盖不足**：单元测试覆盖率 < 20%
4. **性能未优化**：宏执行启动时间未达标（目标 < 1 秒）

## 参考场景："快小红"

这是一个典型的自动化流程，演示了应用的核心能力：

**目标**：从小红书采集内容到飞书多维表格

**流程**：
1. 用户复制小红书链接
2. 点击桌面快捷方式触发宏
3. 读取剪贴板（ClipboardAction）
4. 正则提取 URL（TextProcessAction）
5. 弹出对话框让用户选择分类（UserDialogAction）
6. 调用飞书 API 上传数据（HttpRequestAction）
7. 打开飞书多维表格（OpenUrlAction）

参考 `docs/快小红宏流程在鸿蒙Next的实现分析.md` 获取完整实现细节。

## 技术文档位置

- **需求规范**：`.claude/specs/harmonyos-automation-app/requirements-spec.md`
- **实现报告**：`docs/核心模块补充实现报告.md`
- **快速开始**：`docs/快速开始指南.md`
- **构建问题**：`docs/构建问题解决方案.md`
- **代码审查**：`docs/code-review-round2.md`

## 语言要求

所有对话和文档使用中文。文档使用 markdown 格式，统一放在 `docs/` 目录下。
