# 鸿蒙 Next 自动化宏 App 可行性分析报告

## 一、项目概述

本报告旨在评估在华为鸿蒙 HarmonyOS NEXT 系统上开发一款类似 iPhone 快捷指令（Shortcuts）或安卓 MacroDroid 的自动化宏应用的可行性。

### 参考产品功能特点

**iPhone 快捷指令**：
- 创建自定义工作流
- 跨应用操作自动化
- 支持定时触发、地理位置触发等多种触发方式
- 可调用系统功能和第三方应用

**MacroDroid**：
- 触发器（Trigger）：时间、位置、传感器、应用事件等
- 动作（Action）：发送通知、控制系统设置、执行脚本等
- 条件（Condition）：根据不同条件执行不同动作

---

## 二、鸿蒙 Next 系统能力调研

### 2.1 后台任务管理能力

鸿蒙 Next 提供了完善的后台任务管理框架，可满足自动化应用的核心需求：

#### 任务类型

1. **短时任务（Transient Task）**
   - 适用场景：实时、短时任务
   - 应用场景：用户触发的快速操作，如文件上传、数据同步
   - 限制：有时间配额限制，可通过 `getRemainingDelayTime` 查询剩余时间

2. **长时任务（Continuous Task）**
   - 适用场景：持续性操作
   - 应用场景：音乐播放、导航、文件下载等
   - 特点：需要前台通知栏展示

3. **延迟任务（Work Scheduler）**
   - 适用场景：非紧急的后台工作
   - 触发条件支持：
     - 网络类型（Wi-Fi、移动数据）
     - 电池状态（充电状态、电量百分比）
     - 充电类型（快充、无线充电）
     - 存储状态
     - 定时触发

4. **代理提醒（Agent Reminder）**
   - 适用场景：定时提醒功能
   - 应用场景：闹钟、日历提醒等

#### 技术实现示例

```typescript
import { workScheduler } from '@kit.BackgroundTasksKit';

// 配置延迟任务
let workInfo: workScheduler.WorkInfo = {
  workId: 1,
  networkType: workScheduler.NetworkType.NETWORK_TYPE_WIFI, // Wi-Fi 网络
  bundleName: 'com.example.app',
  abilityName: 'MyAbility',
  // 其他触发条件...
};
```

**可行性评估**：✅ **高度可行**

延迟任务（Work Scheduler）的能力基本可以满足自动化宏的触发需求。

---

### 2.2 跨应用调用与通信

#### Want 机制

鸿蒙 Next 通过 **Want** 对象实现应用间通信和跨应用调用，类似 Android 的 Intent 机制。

##### 启动方式

1. **显式 Want 启动**
   - 明确指定 `bundleName` 和 `abilityName`
   - 适用于已知目标应用的场景

```typescript
import { common } from '@kit.AbilityKit';

let want: Want = {
  bundleName: 'com.example.targetapp',
  abilityName: 'TargetAbility',
  parameters: {
    key: 'value'
  }
};

context.startAbility(want);
```

2. **隐式 Want 启动**
   - 通过 `action`、`entities`、`uri` 等进行模糊匹配
   - 系统会列出所有符合条件的应用供用户选择

##### UIAbility 启动模式

- **Singleton（单例模式）**：适合设置、音乐播放等全局性功能
- **Multiton（多实例模式）**：适合多文档编辑等需要并行操作的场景
- **Specified（指定实例模式）**：特殊场景使用，可为实例创建唯一 Key

**可行性评估**：✅ **可行，但有限制**

- 可以通过 Want 机制启动其他应用
- **限制**：需要目标应用配置相应的 `skills` 声明，才能被隐式调用
- 对于未开放调用接口的系统应用或第三方应用，可能无法直接调用

---

### 2.3 意图框架服务（Intents Kit）

**Intents Kit** 是鸿蒙 Next 提供的意图标准体系，用于连接应用/元服务内的业务功能。

#### 支持的特性类别

- 习惯推荐
- 事件推荐
- 技能调用（语音）
- 本地搜索

#### 智能分发

通过意图共享和意图调用，实现跨应用或模块的数据传递和功能调用。

```typescript
import { IntentsKit } from '@kit.IntentsKit';

// 意图共享示例
IntentsKit.shareIntent({
  action: 'search',
  data: { keyword: '天气' }
});
```

**可行性评估**：✅ **中等可行**

- Intents Kit 是较新的框架，功能还在不断完善
- 适合与系统级服务和已接入的应用进行联动
- 对于第三方应用的支持取决于应用是否接入 Intents Kit

---

### 2.4 权限管理

鸿蒙 Next 采用严格的权限管理机制，这对自动化应用提出了挑战。

#### 权限授权方式

1. **系统授权（system_grant）**
   - 安装时自动授予
   - 适用于普通权限，影响较小

2. **用户授权（user_grant）**
   - 运行时动态申请
   - 适用于敏感权限（摄像头、麦克风、通讯录等）

#### 权限等级

- **normal**：普通权限
- **system_basic**：系统基础权限
- **system_core**：系统核心权限

#### 受限权限与 ACL

某些敏感权限需要通过应用市场（AGC）申请权限证书，否则无法使用。

**可行性评估**：⚠️ **面临挑战**

- **敏感权限**：如访问通讯录、短信、通话记录等需要用户授权
- **系统级权限**：如修改系统设置、管理其他应用等可能无法获取
- **用户体验影响**：频繁的权限申请可能影响用户体验

---

### 2.5 系统功能调用

#### 可调用的系统功能

通过 Want 机制，可以拉起部分系统应用：

- **拨号页面**：指定号码拉起系统拨号应用
- **应用市场**：跳转到应用详情页
- **设置页面**：跳转到应用设置页

#### 限制

- 不是所有系统功能都对外开放调用接口
- 修改系统设置（如 Wi-Fi 开关、蓝牙开关）可能受到权限限制

**可行性评估**：⚠️ **部分可行**

- 可以调用部分系统应用和功能
- 深度的系统控制（如切换飞行模式、修改音量等）可能受限

---

## 三、功能对比分析

| 功能模块 | iPhone 快捷指令 | MacroDroid | 鸿蒙 Next 可行性 | 备注 |
|---------|----------------|-----------|-----------------|------|
| **触发器** | | | | |
| 定时触发 | ✅ | ✅ | ✅ | 通过延迟任务实现 |
| 应用启动/关闭触发 | ✅ | ✅ | ⚠️ | 需要监听应用状态，可能受权限限制 |
| 位置触发 | ✅ | ✅ | ✅ | 需要位置权限 |
| 网络状态触发 | ✅ | ✅ | ✅ | 可通过延迟任务条件实现 |
| 电池状态触发 | ✅ | ✅ | ✅ | 可通过延迟任务条件实现 |
| 传感器触发 | ✅ | ✅ | ⚠️ | 需要持续后台监听，可能受限 |
| **动作** | | | | |
| 发送通知 | ✅ | ✅ | ✅ | 通知权限较容易获取 |
| 启动应用 | ✅ | ✅ | ✅ | 通过 Want 机制实现 |
| 调用应用功能 | ✅ | ✅ | ⚠️ | 需要应用配合开放接口 |
| 修改系统设置 | ✅ | ✅ | ❌ | 系统级权限难以获取 |
| 网络请求 | ✅ | ✅ | ✅ | 常规网络权限可获取 |
| 执行脚本 | ✅ | ✅ | ⚠️ | 鸿蒙不支持动态执行代码 |
| 文件操作 | ✅ | ✅ | ✅ | 需要文件访问权限 |
| **条件判断** | | | | |
| 时间条件 | ✅ | ✅ | ✅ | 可在应用逻辑中实现 |
| 位置条件 | ✅ | ✅ | ✅ | 需要位置权限 |
| 网络状态条件 | ✅ | ✅ | ✅ | 可获取网络状态 |
| 电池状态条件 | ✅ | ✅ | ✅ | 可获取电池状态 |
| 应用状态条件 | ✅ | ✅ | ⚠️ | 可能受权限限制 |

**图例**：
- ✅ 完全可行
- ⚠️ 部分可行或有限制
- ❌ 不可行或严重受限

---

## 四、技术架构建议

基于以上调研，建议采用以下技术架构：

### 4.1 核心架构

```
┌─────────────────────────────────────────┐
│           用户界面层（UI Layer）          │
│  - 触发器配置                             │
│  - 动作配置                               │
│  - 宏管理                                 │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         业务逻辑层（Business Layer）      │
│  - 宏执行引擎                             │
│  - 条件判断引擎                           │
│  - 动作调度器                             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          系统能力层（System Layer）       │
│  - Work Scheduler（延迟任务）             │
│  - Want 机制（跨应用调用）                │
│  - Intents Kit（意图框架）                │
│  - 后台任务管理                           │
└─────────────────────────────────────────┘
```

### 4.2 开发技术栈

- **开发语言**：ArkTS（TypeScript 扩展）
- **开发框架**：ArkUI（鸿蒙官方 UI 框架）
- **开发工具**：DevEco Studio
- **API 版本**：API 12+（HarmonyOS NEXT）

### 4.3 核心模块设计

#### 1. 触发器管理模块

```typescript
// 触发器基类
abstract class Trigger {
  id: string;
  type: TriggerType;

  abstract register(): void;
  abstract unregister(): void;
  abstract checkCondition(): boolean;
}

// 定时触发器
class TimeTrigger extends Trigger {
  scheduleTime: Date;

  register() {
    // 使用 Work Scheduler 注册延迟任务
  }
}

// 位置触发器
class LocationTrigger extends Trigger {
  latitude: number;
  longitude: number;
  radius: number;

  register() {
    // 使用地理围栏 API
  }
}
```

#### 2. 动作执行模块

```typescript
// 动作基类
abstract class Action {
  id: string;
  type: ActionType;

  abstract execute(context: ExecutionContext): Promise<void>;
}

// 启动应用动作
class LaunchAppAction extends Action {
  bundleName: string;
  abilityName: string;
  parameters?: Record<string, any>;

  async execute(context: ExecutionContext) {
    let want: Want = {
      bundleName: this.bundleName,
      abilityName: this.abilityName,
      parameters: this.parameters
    };
    await context.startAbility(want);
  }
}

// 发送通知动作
class SendNotificationAction extends Action {
  title: string;
  content: string;

  async execute(context: ExecutionContext) {
    // 使用通知 API 发送通知
  }
}
```

#### 3. 宏执行引擎

```typescript
class MacroEngine {
  async executeMacro(macro: Macro, context: ExecutionContext) {
    // 1. 检查条件
    if (!this.checkConditions(macro.conditions, context)) {
      return;
    }

    // 2. 依次执行动作
    for (const action of macro.actions) {
      try {
        await action.execute(context);
      } catch (error) {
        // 错误处理
        this.handleError(error);
      }
    }
  }

  private checkConditions(conditions: Condition[], context: ExecutionContext): boolean {
    return conditions.every(condition => condition.check(context));
  }
}
```

---

## 五、面临的主要挑战

### 5.1 权限限制

**问题**：
- 敏感权限需要用户授权，频繁申请影响体验
- 系统级权限难以获取，限制了某些自动化功能
- 无法修改系统设置（如 Wi-Fi、蓝牙开关）

**解决方案**：
- 在应用首次启动时集中申请必要权限，并向用户说明用途
- 对于无法获取的权限，提供替代方案或提示用户手动操作
- 与华为官方沟通，申请特殊权限（ACL）

### 5.2 第三方应用支持

**问题**：
- 第三方应用未开放调用接口，无法直接操作
- 无法获取应用的内部状态和数据

**解决方案**：
- 优先支持鸿蒙官方应用和已接入 Intents Kit 的应用
- 提供"应用协作平台",鼓励第三方应用接入
- 使用可用的公开接口（如分享接口、URI Scheme）

### 5.3 后台运行限制

**问题**：
- 后台任务受到系统资源管控,可能被终止
- 长时任务需要前台通知，影响用户体验

**解决方案**：
- 合理使用延迟任务，避免持续后台运行
- 向用户说明后台运行的必要性,申请电池优化白名单
- 优化任务执行逻辑，减少资源占用

### 5.4 跨设备协同

**问题**：
- 鸿蒙主打分布式能力，但跨设备自动化需要额外的复杂度

**机会**：
- 可以利用鸿蒙的分布式能力，实现跨设备的自动化场景
- 例如：手机触发，平板执行；设备间数据同步等

---

## 六、开发路线图建议

### Phase 1：MVP（最小可行产品）

**功能范围**：
- ✅ 定时触发器
- ✅ 网络状态触发器
- ✅ 电池状态触发器
- ✅ 启动应用动作
- ✅ 发送通知动作
- ✅ 网络请求动作
- ✅ 简单的条件判断

**开发周期**：建议 2-3 个月

### Phase 2：功能扩展

**新增功能**：
- 位置触发器
- 调用系统应用（拨号、短信等）
- 文件操作动作
- 更复杂的条件判断逻辑
- 宏的导入导出

**开发周期**：建议 2-3 个月

### Phase 3：高级功能

**新增功能**：
- Intents Kit 集成（调用第三方应用）
- 传感器触发器
- 跨设备协同自动化
- 社区宏市场（用户分享宏）
- AI 辅助创建宏

**开发周期**：建议 3-4 个月

---

## 七、商业化与上架

### 7.1 应用市场上架要求

- 需要在华为应用市场（AppGallery）提交审核
- 敏感权限需要详细说明使用场景
- 不得违反用户隐私和系统安全规范

### 7.2 商业模式建议

1. **免费版**：提供基础的触发器和动作
2. **高级版**：通过订阅或一次性付费解锁高级功能
3. **企业版**：面向企业用户，提供批量管理和定制化功能

---

## 八、总结与建议

### 8.1 可行性总结

**总体评估**：⚠️ **可行，但需要适度降低预期**

鸿蒙 Next 系统提供了足够的基础能力来开发自动化宏应用，特别是在以下方面：
- ✅ 后台任务管理（延迟任务、定时任务）
- ✅ 跨应用调用（Want 机制）
- ✅ 部分系统功能调用

然而，以下方面会面临挑战：
- ⚠️ 系统级权限受限
- ⚠️ 第三方应用支持依赖应用生态
- ⚠️ 深度系统控制能力有限

### 8.2 关键建议

1. **降低初期预期**：
   - 不要期望达到 iOS 快捷指令或 MacroDroid 的完整功能
   - 优先实现核心的、可实现的功能

2. **与华为官方合作**：
   - 申请成为华为开发者合作伙伴
   - 争取特殊权限和技术支持
   - 参与鸿蒙生态建设计划

3. **构建应用生态**：
   - 建立第三方应用接入平台
   - 提供 SDK 供其他应用接入
   - 推动更多应用支持自动化调用

4. **用户教育**：
   - 明确告知用户功能限制
   - 提供详细的使用教程
   - 收集用户反馈，持续优化

5. **合规与安全**：
   - 严格遵守华为应用市场规范
   - 保护用户隐私和数据安全
   - 避免滥用权限

### 8.3 竞争优势

如果能成功开发，该应用将具有以下优势：
- 🏆 **市场空白**：鸿蒙生态目前缺少成熟的自动化工具
- 🏆 **先发优势**：尽早进入市场，建立品牌认知
- 🏆 **分布式特性**：利用鸿蒙的跨设备能力，提供独特体验

---

## 九、参考资料

### 官方文档
- [HarmonyOS NEXT 开发文档](https://developer.huawei.com/consumer/cn/doc/)
- [HarmonyOS 开发平台](https://developer.huawei.com/consumer/cn/develop/)

### 后台任务与延迟任务
- [HarmonyOS Next延迟任务管理](https://my.oschina.net/u/9346979/blog/18483412)
- [延迟任务管理：HarmonyOS Next 的灵活后台调度](https://www.cnblogs.com/samex/p/18508050)
- [解析短时任务与长时任务](https://www.cnblogs.com/samex/p/18508049)
- [HarmonyOS后台任务管理开发指南](https://www.cnblogs.com/HarmonyOSDev/p/17863847.html)

### UIAbility 与跨应用调用
- [HarmonyOSNext 超全开发指南：UIAbility组件与跨端协作](https://segmentfault.com/a/1190000046618022)
- [HarmonyOS —— UIAbility 页面跳转总结](https://cloud.tencent.com/developer/article/2375084)
- [HarmonyOS Next开发学习手册——信息传递载体Want](https://blog.csdn.net/maniuT/article/details/139938221)

### Intents Kit（意图框架）
- [HarmonyOS NEXT 应用元服务开发 Intents Kit](https://blog.csdn.net/weixin_69135651/article/details/143602146)
- [HarmonyOS Next 技术实践-基于意图框架服务实现智能分发](https://harmonyosdev.csdn.net/6767c4d882931a478c3478ad.html)

### 权限管理
- [鸿蒙Next权限申请全攻略](https://www.cnblogs.com/samex/p/18527106)
- [HarmonyOS NEXT 头像制作项目系列教程之权限配置与管理](https://segmentfault.com/a/1190000046534368)
- [HarmonyOS Next 分布式管理权限控制](https://www.cnblogs.com/samex/p/18547369)
- [鸿蒙系统中应用权限等级介绍](https://segmentfault.com/a/1190000046806094)

---

**报告生成时间**：2026-01-06
**API 版本**：HarmonyOS NEXT API 12+
**报告作者**：Claude（AI 助手）

---

## 附录：关键代码示例

### A. 延迟任务注册示例

```typescript
import { workScheduler } from '@kit.BackgroundTasksKit';

export class TaskScheduler {
  // 注册一个定时任务
  static registerTimedTask(taskId: number, delayMs: number) {
    let workInfo: workScheduler.WorkInfo = {
      workId: taskId,
      bundleName: 'com.example.macroapp',
      abilityName: 'MacroExecutorAbility',
      // 延迟触发
      delay: delayMs,
      // 是否重复
      isRepeat: false,
      // 是否持久化
      isPersisted: true
    };

    try {
      workScheduler.startWork(workInfo);
      console.info(`Task ${taskId} registered successfully`);
    } catch (error) {
      console.error(`Failed to register task: ${error}`);
    }
  }

  // 注册一个基于条件的任务
  static registerConditionalTask(taskId: number) {
    let workInfo: workScheduler.WorkInfo = {
      workId: taskId,
      bundleName: 'com.example.macroapp',
      abilityName: 'MacroExecutorAbility',
      // 网络条件
      networkType: workScheduler.NetworkType.NETWORK_TYPE_WIFI,
      // 电池条件
      isCharging: true,
      batteryLevel: 30,
      // 存储条件
      storageRequest: workScheduler.StorageRequest.STORAGE_LEVEL_LOW
    };

    try {
      workScheduler.startWork(workInfo);
      console.info(`Conditional task ${taskId} registered successfully`);
    } catch (error) {
      console.error(`Failed to register task: ${error}`);
    }
  }

  // 取消任务
  static cancelTask(taskId: number) {
    try {
      workScheduler.stopWork(workInfo, false);
      console.info(`Task ${taskId} cancelled`);
    } catch (error) {
      console.error(`Failed to cancel task: ${error}`);
    }
  }
}
```

### B. 跨应用启动示例

```typescript
import { common, Want } from '@kit.AbilityKit';

export class AppLauncher {
  // 显式启动应用
  static async launchAppExplicitly(
    context: common.UIAbilityContext,
    bundleName: string,
    abilityName: string,
    params?: Record<string, any>
  ) {
    let want: Want = {
      bundleName: bundleName,
      abilityName: abilityName,
      parameters: params
    };

    try {
      await context.startAbility(want);
      console.info(`Launched ${bundleName}/${abilityName}`);
    } catch (error) {
      console.error(`Failed to launch app: ${error}`);
      throw error;
    }
  }

  // 隐式启动（通过 action）
  static async launchAppImplicitly(
    context: common.UIAbilityContext,
    action: string,
    uri?: string,
    type?: string
  ) {
    let want: Want = {
      action: action,
      uri: uri,
      type: type
    };

    try {
      await context.startAbility(want);
      console.info(`Launched app with action: ${action}`);
    } catch (error) {
      console.error(`Failed to launch app: ${error}`);
      throw error;
    }
  }

  // 拨打电话示例
  static async makePhoneCall(
    context: common.UIAbilityContext,
    phoneNumber: string
  ) {
    let want: Want = {
      action: 'ohos.want.action.DIAL',
      uri: `tel:${phoneNumber}`
    };

    await context.startAbility(want);
  }

  // 打开浏览器示例
  static async openUrl(
    context: common.UIAbilityContext,
    url: string
  ) {
    let want: Want = {
      action: 'ohos.want.action.VIEW',
      uri: url
    };

    await context.startAbility(want);
  }
}
```

### C. 权限申请示例

```typescript
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

export class PermissionManager {
  // 检查权限
  static async checkPermission(
    permission: Permissions
  ): Promise<boolean> {
    let atManager = abilityAccessCtrl.createAtManager();
    let grantStatus = await atManager.checkAccessToken(
      getContext().applicationInfo.accessTokenId,
      permission
    );

    return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }

  // 请求权限
  static async requestPermissions(
    context: common.UIAbilityContext,
    permissions: Permissions[]
  ): Promise<boolean> {
    try {
      let atManager = abilityAccessCtrl.createAtManager();
      let data = await atManager.requestPermissionsFromUser(
        context,
        permissions
      );

      // 检查所有权限是否都被授予
      let allGranted = data.authResults.every(
        result => result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
      );

      return allGranted;
    } catch (error) {
      console.error(`Failed to request permissions: ${error}`);
      return false;
    }
  }

  // 批量请求常用权限
  static async requestCommonPermissions(
    context: common.UIAbilityContext
  ): Promise<void> {
    const permissions: Permissions[] = [
      'ohos.permission.LOCATION',           // 位置权限
      'ohos.permission.APPROXIMATELY_LOCATION', // 粗略位置
      'ohos.permission.INTERNET',           // 网络权限
      'ohos.permission.GET_WIFI_INFO',      // Wi-Fi 信息
      'ohos.permission.NOTIFICATION_CONTROLLER' // 通知权限
    ];

    await this.requestPermissions(context, permissions);
  }
}
```

### D. 宏数据模型示例

```typescript
// 触发器类型枚举
export enum TriggerType {
  TIME = 'time',              // 定时触发
  LOCATION = 'location',      // 位置触发
  NETWORK = 'network',        // 网络状态触发
  BATTERY = 'battery',        // 电池状态触发
  APP_LAUNCH = 'app_launch'   // 应用启动触发
}

// 动作类型枚举
export enum ActionType {
  LAUNCH_APP = 'launch_app',          // 启动应用
  SEND_NOTIFICATION = 'notification', // 发送通知
  HTTP_REQUEST = 'http_request',      // HTTP 请求
  OPEN_URL = 'open_url',              // 打开 URL
  MAKE_CALL = 'make_call'             // 拨打电话
}

// 触发器接口
export interface Trigger {
  id: string;
  type: TriggerType;
  enabled: boolean;
  config: any; // 具体配置
}

// 动作接口
export interface Action {
  id: string;
  type: ActionType;
  config: any; // 具体配置
}

// 条件接口
export interface Condition {
  field: string;       // 条件字段（如 'battery', 'network'）
  operator: string;    // 运算符（如 '>', '<', '=='）
  value: any;          // 比较值
}

// 宏定义
export interface Macro {
  id: string;
  name: string;
  description?: string;
  enabled: boolean;
  trigger: Trigger;
  conditions: Condition[];
  actions: Action[];
  createdAt: Date;
  updatedAt: Date;
}

// 示例：创建一个定时宏
export function createTimedMacro(): Macro {
  return {
    id: 'macro_001',
    name: '每日早报提醒',
    description: '每天早上 8 点发送通知',
    enabled: true,
    trigger: {
      id: 'trigger_001',
      type: TriggerType.TIME,
      enabled: true,
      config: {
        hour: 8,
        minute: 0,
        repeat: true,
        daysOfWeek: [1, 2, 3, 4, 5] // 周一到周五
      }
    },
    conditions: [
      {
        field: 'network',
        operator: '==',
        value: 'wifi' // 仅在 Wi-Fi 下执行
      }
    ],
    actions: [
      {
        id: 'action_001',
        type: ActionType.SEND_NOTIFICATION,
        config: {
          title: '早安提醒',
          content: '新的一天开始了！',
          sound: true
        }
      },
      {
        id: 'action_002',
        type: ActionType.OPEN_URL,
        config: {
          url: 'https://news.example.com'
        }
      }
    ],
    createdAt: new Date(),
    updatedAt: new Date()
  };
}
```

---

希望本报告能为您的项目决策提供有价值的参考！
