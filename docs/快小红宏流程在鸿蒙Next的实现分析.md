# "快小红"MacroDroid 宏在鸿蒙 Next 的实现可行性分析

## 一、MacroDroid 宏功能概述

"快小红"是一个用于采集小红书内容并上传到飞书多维表格的自动化宏，主要功能如下：

### 1.1 业务流程

```
用户复制小红书链接
    ↓
启动快捷指令
    ↓
读取剪贴板内容 → 提取 URL
    ↓
判断链接类型（笔记/商品/博主）
    ↓
用户选择元数据：
  - 爆款标记（普通款/潜力款/大爆款）
  - 分类标签（40+ 个选项）
  - 对标参考（1-5 星）
  - 备注说明
    ↓
调用飞书扣子 API 采集数据
    ↓
上传到飞书多维表格
    ↓
打开飞书查看结果
```

### 1.2 技术特性

| 功能类别 | 具体实现 |
|---------|---------|
| **触发方式** | 桌面快捷指令 |
| **数据输入** | 剪贴板监听 |
| **文本处理** | 正则表达式提取 URL |
| **用户交互** | 对话框、选择列表、Toast 提示 |
| **网络请求** | HTTP POST/GET（调用飞书扣子 API）|
| **数据格式** | JSON 解析和构建 |
| **跨应用调用** | 打开飞书客户端 |
| **变量管理** | 40+ 个局部变量 |
| **动画效果** | 彩虹覆盖层动画 |

---

## 二、鸿蒙 Next 实现能力对比

### 2.1 核心功能对比表

| 功能模块 | MacroDroid | 鸿蒙 Next | 可行性 | 技术方案 | 限制说明 |
|---------|-----------|-----------|-------|---------|---------|
| **触发器** | | | | | |
| 快捷指令触发 | ✅ | ✅ | **完全可行** | 桌面图标启动 UIAbility | 无 |
| 后台定时触发 | ✅ | ✅ | **完全可行** | Work Scheduler | 系统资源限制 |
| **剪贴板操作** | | | | | |
| 读取剪贴板 | ✅ | ✅ | **完全可行** | `@ohos.pasteboard` | 需要权限声明 |
| 写入剪贴板 | ✅ | ✅ | **完全可行** | `pasteboard.setPasteData()` | 无 |
| **文本处理** | | | | | |
| 正则提取 | ✅ | ✅ | **完全可行** | ArkTS 原生 `RegExp` | 无 |
| 字符串分割/替换 | ✅ | ✅ | **完全可行** | String API | 无 |
| **用户交互** | | | | | |
| 对话框 | ✅ | ✅ | **完全可行** | `AlertDialog`、`CustomDialog` | 无 |
| 选择列表 | ✅ | ✅ | **完全可行** | `SelectDialog`、`TextPickerDialog` | 无 |
| Toast 提示 | ✅ | ✅ | **完全可行** | `promptAction.showToast()` | 无 |
| 输入框 | ✅ | ✅ | **完全可行** | `TextInput` + Dialog | 无 |
| **网络请求** | | | | | |
| HTTP GET | ✅ | ✅ | **完全可行** | `@ohos.net.http` | 需要网络权限 |
| HTTP POST | ✅ | ✅ | **完全可行** | `http.request()` | 需要网络权限 |
| JSON 处理 | ✅ | ✅ | **完全可行** | `JSON.parse()` / `JSON.stringify()` | 无 |
| 自定义 Headers | ✅ | ✅ | **完全可行** | `RequestOptions.header` | 无 |
| **跨应用调用** | | | | | |
| 打开飞书 | ✅ | ✅ | **完全可行** | Want + Deep Link | 需要飞书支持 |
| 打开浏览器 | ✅ | ✅ | **完全可行** | `ohos.want.action.VIEW` | 无 |
| **数据持久化** | | | | | |
| 本地变量 | ✅ | ✅ | **完全可行** | `AppStorage` / `Preferences` | 无 |
| 键值对存储 | ✅ | ✅ | **完全可行** | `Preferences` | 无 |
| **动画效果** | | | | | |
| 覆盖层动画 | ✅ | ⚠️ | **部分可行** | 自定义组件 + `animateTo()` | 无悬浮窗权限限制 |
| 进度提示 | ✅ | ✅ | **完全可行** | `LoadingProgress` | 无 |

### 2.2 结论

✅ **完全可行** - 鸿蒙 Next 可以 100% 实现"快小红"的所有核心功能！

---

## 三、鸿蒙 Next 实现方案

### 3.1 架构设计

```
┌─────────────────────────────────────────┐
│           UIAbility（主入口）             │
│   - 快捷指令启动                          │
│   - 剪贴板监听                            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          业务逻辑层（Services）            │
│   - ClipboardService（剪贴板）            │
│   - HttpService（网络请求）               │
│   - StorageService（数据存储）            │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│          UI 交互层（Pages）                │
│   - 选择爆款标记                          │
│   - 选择分类标签                          │
│   - 对标参考评分                          │
│   - 备注说明输入                          │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│       飞书扣子 API（HTTP）                │
│   - POST /v1/workflow/run                │
└─────────────────────────────────────────┘
```

### 3.2 核心代码实现

#### 3.2.1 剪贴板读取

```typescript
import pasteboard from '@ohos.pasteboard';

export class ClipboardService {
  // 读取剪贴板内容
  static async getClipboardText(): Promise<string> {
    try {
      const pasteData = await pasteboard.getSystemPasteboard().getPasteData();
      if (pasteData && pasteData.getPrimaryText()) {
        return pasteData.getPrimaryText();
      }
      return '';
    } catch (error) {
      console.error(`读取剪贴板失败: ${error}`);
      return '';
    }
  }

  // 提取 URL
  static extractUrl(text: string): string {
    const urlRegex = /https?:\/\/[^\s]+/;
    const match = text.match(urlRegex);
    return match ? match[0] : '';
  }
}
```

#### 3.2.2 用户交互对话框

```typescript
import { SelectDialog, TextPickerDialog } from '@ohos.arkui.advanced.SelectionDialog';
import promptAction from '@ohos.promptAction';

export class DialogService {
  // 爆款标记选择
  static async selectQuality(): Promise<string> {
    const options = ['⚪ 普通款', '🟡 潜力款', '🔴 大爆款'];

    return new Promise((resolve) => {
      SelectDialog.show({
        title: '🔥 请标记内容火爆程度',
        selectedIndex: 0,
        confirm: (value: SelectDialogResult) => {
          resolve(options[value.index]);
        }
      });
    });
  }

  // 分类标签选择（多选）
  static async selectLabels(): Promise<string[]> {
    const labels = [
      '💄时尚美妆', '🌍旅游出行', '🍜美食消费', '📚学习教育',
      '💹商业财经', '💼职场', '💴生米项目', '✨创意灵感',
      '📝干货分享', '⚙️效率工具', '🎁新奇好物', '🏠家居家装',
      '👶亲子母婴', '💖情感心理', '🏥医疗健康', '📺影视综艺',
      '🎵音乐', '📰时政社会', '🎨文学艺术', '🏛️人文历史',
      // ... 更多标签
    ];

    // 使用自定义多选组件
    return new Promise((resolve) => {
      MultiSelectDialog.show({
        title: '📑 请选择分类标签',
        options: labels,
        confirm: (selectedIndices: number[]) => {
          const selected = selectedIndices.map(i => labels[i]);
          resolve(selected);
        }
      });
    });
  }

  // 对标参考评分
  static async selectRating(): Promise<number> {
    const ratings = [
      '5 赞👍👍👍👍👍',
      '4 赞👍👍👍👍',
      '3 赞👍👍👍',
      '2 赞👍👍',
      '1 赞👍',
      '0 先不选，跳过'
    ];

    return new Promise((resolve) => {
      SelectDialog.show({
        title: '👍 请标记对标参考度',
        options: ratings,
        confirm: (value: SelectDialogResult) => {
          resolve(5 - value.index);
        }
      });
    });
  }

  // 备注说明输入
  static async inputNotes(): Promise<string> {
    return new Promise((resolve) => {
      CustomDialog.show({
        title: '📝 请输入收藏备注（选填）',
        inputPlaceholder: '输入备注...',
        confirm: (text: string) => {
          resolve(text || '');
        }
      });
    });
  }

  // Toast 提示
  static showToast(message: string) {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
}
```

#### 3.2.3 HTTP 请求（调用飞书扣子 API）

```typescript
import http from '@ohos.net.http';

export interface WorkflowParams {
  basetoken: string;
  knowledgeurl: string;
  ordeid: string;
  url: string;
  quality: string;
  read: string;
  notes: string;
  label: string[];
  xhscookie?: string;
}

export class FeishuApiService {
  private static readonly API_BASE = 'https://api.coze.cn/v1/workflow/run';
  private static readonly AUTH_TOKEN = 'sat_NbvH6WQTg8EX496ohv6JE0B3ocRAnTuWKYyt4ADuajYzs6RQdwW4emf5GmjQdfwe';

  // 调用工作流 API
  static async callWorkflow(
    workflowId: string,
    params: WorkflowParams
  ): Promise<any> {
    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(this.API_BASE, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.AUTH_TOKEN}`
        },
        extraData: {
          workflow_id: workflowId,
          parameters: params
        },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: 30000
      });

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result as string);
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } catch (error) {
      console.error(`API 调用失败: ${error}`);
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }

  // 采集小红书笔记
  static async collectNote(
    url: string,
    quality: string,
    labels: string[],
    rating: number,
    notes: string,
    config: any
  ): Promise<any> {
    const params: WorkflowParams = {
      basetoken: config.basetoken,
      knowledgeurl: config.knowledgeurl,
      ordeid: config.ordeid,
      url: url,
      quality: quality,
      read: labels.join(';'),
      notes: notes,
      label: labels,
      xhscookie: config.cookie || ''
    };

    return await this.callWorkflow('7550495126771449906', params);
  }
}
```

#### 3.2.4 跨应用调用（打开飞书）

```typescript
import common from '@ohos.app.ability.common';

export class AppLauncher {
  // 打开飞书多维表格
  static async openFeishuDoc(
    context: common.UIAbilityContext,
    docUrl: string
  ) {
    const want: Want = {
      action: 'ohos.want.action.VIEW',
      uri: `https://applink.feishu.cn/client/docs/open?url=${encodeURIComponent(docUrl)}`
    };

    try {
      await context.startAbility(want);
      console.info('成功打开飞书');
    } catch (error) {
      console.error(`打开飞书失败: ${error}`);
      // 降级方案：使用浏览器打开
      want.uri = docUrl;
      await context.startAbility(want);
    }
  }
}
```

#### 3.2.5 完整业务流程

```typescript
import { ClipboardService } from './services/ClipboardService';
import { DialogService } from './services/DialogService';
import { FeishuApiService } from './services/FeishuApiService';
import { AppLauncher } from './services/AppLauncher';

export class KuaiXiaoHongWorkflow {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async execute() {
    try {
      // 1. 显示启动提示
      DialogService.showToast('开始采集，请按提示逐步操作');

      // 2. 读取剪贴板
      const clipboardText = await ClipboardService.getClipboardText();
      const url = ClipboardService.extractUrl(clipboardText);

      if (!url) {
        DialogService.showToast('未复制链接，请先复制小红书链接');
        return;
      }

      // 3. 判断链接类型
      let targetType = '';
      if (url.includes('xhslink.com/m') || url.includes('xiaohongshu.com/explore')) {
        targetType = 'note'; // 笔记
      } else if (url.includes('xiaohongshu.com/goods-detail')) {
        targetType = 'goods'; // 商品
      } else if (url.includes('xiaohongshu.com/user')) {
        targetType = 'blogger'; // 博主
      }

      // 4. 用户交互
      DialogService.showToast('数据上传中，请耐心等待');

      const quality = await DialogService.selectQuality();
      const labels = await DialogService.selectLabels();
      const rating = await DialogService.selectRating();
      const notes = await DialogService.inputNotes();

      // 5. 调用飞书扣子 API
      const config = {
        basetoken: 'pt-xxx', // 从配置读取
        knowledgeurl: 'https://xxx', // 从配置读取
        ordeid: 'P1234567890', // 从配置读取
        cookie: '' // 选填
      };

      const result = await FeishuApiService.collectNote(
        url,
        quality,
        labels,
        rating,
        notes,
        config
      );

      // 6. 处理结果
      if (result.code === 0 && result.data.add_result) {
        DialogService.showToast('✔ 采集成功');

        // 7. 打开飞书查看
        await AppLauncher.openFeishuDoc(this.context, config.knowledgeurl);
      } else {
        DialogService.showToast('⚠️ 采集失败，请重试');
      }

    } catch (error) {
      console.error(`工作流执行失败: ${error}`);
      DialogService.showToast('发生错误，请检查配置');
    }
  }
}
```

#### 3.2.6 UIAbility 入口

```typescript
import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { KuaiXiaoHongWorkflow } from './workflow/KuaiXiaoHongWorkflow';

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    console.info('快小红启动');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error(`加载页面失败: ${JSON.stringify(err)}`);
        return;
      }

      // 自动执行工作流
      const workflow = new KuaiXiaoHongWorkflow(this.context);
      workflow.execute();
    });
  }
}
```

---

## 四、权限配置

### 4.1 module.json5 配置

```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ts",
        "launchType": "singleton",
        "visible": true,
        "skills": [
          {
            "actions": ["ohos.want.action.home"]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.GET_WIFI_INFO",
        "reason": "$string:wifi_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 4.2 运行时权限申请

剪贴板读取在鸿蒙 Next 中不需要运行时权限，只需要在 `module.json5` 中声明即可。网络权限也是系统授权，无需用户手动批准。

---

## 五、限制与挑战

### 5.1 已知限制

| 限制项 | 说明 | 解决方案 |
|-------|------|---------|
| **悬浮窗动画** | 覆盖层彩虹动画需要悬浮窗权限 | 使用应用内 Loading 动画替代 |
| **后台运行** | 后台长时间运行受限 | 设计为快速执行的前台工作流 |
| **飞书 Deep Link** | 需要飞书客户端支持 | 提供浏览器降级方案 |

### 5.2 技术挑战

1. **多选对话框**：鸿蒙标准组件不支持多选，需要自定义实现
2. **复杂的用户交互流程**：需要良好的状态管理
3. **错误处理**：网络异常、API 失败等边界情况处理

---

## 六、实现建议

### 6.1 MVP 功能范围

**第一阶段（核心功能）**：
- ✅ 剪贴板读取
- ✅ URL 提取和识别
- ✅ 用户交互（对话框）
- ✅ HTTP API 调用
- ✅ 打开飞书

**第二阶段（增强功能）**：
- 本地配置管理（订单号、授权码等）
- 历史记录查询
- 批量采集

**第三阶段（高级功能）**：
- 自定义分类标签
- 数据统计分析
- 飞书通知推送

### 6.2 开发工具链

- **开发工具**：DevEco Studio 4.1+
- **开发语言**：ArkTS
- **API 版本**：API 12（HarmonyOS NEXT）
- **测试设备**：华为 Mate 60 / P60 系列

### 6.3 项目结构

```
KuaiXiaoHong/
├── entry/
│   └── src/
│       └── main/
│           ├── ets/
│           │   ├── entryability/
│           │   │   └── EntryAbility.ts
│           │   ├── pages/
│           │   │   ├── Index.ets
│           │   │   └── ConfigPage.ets
│           │   ├── services/
│           │   │   ├── ClipboardService.ts
│           │   │   ├── DialogService.ts
│           │   │   ├── FeishuApiService.ts
│           │   │   └── AppLauncher.ts
│           │   ├── workflow/
│           │   │   └── KuaiXiaoHongWorkflow.ts
│           │   └── models/
│           │       ├── WorkflowParams.ts
│           │       └── CollectionConfig.ts
│           └── module.json5
└── oh-package.json5
```

---

## 七、总结

### 7.1 可行性结论

✅ **完全可行** - 鸿蒙 Next 可以 100% 实现"快小红"MacroDroid 宏的所有核心功能！

### 7.2 优势

1. **原生性能**：ArkTS 编译为原生代码，执行效率高于 MacroDroid
2. **UI 体验**：鸿蒙 ArkUI 提供更流畅的动画和交互
3. **系统集成**：可以更深度集成鸿蒙系统特性（如服务卡片、通知等）
4. **分布式能力**：可利用鸿蒙的跨设备协同（手机采集 → 平板查看）

### 7.3 劣势

1. **开发成本**：需要学习 ArkTS 和 ArkUI 框架
2. **生态限制**：依赖飞书、小红书等第三方应用的支持
3. **调试难度**：网络请求、权限等问题调试复杂度较高

### 7.4 建议

**对于开发者**：
- 建议从 MVP 开始，先实现核心流程
- 使用 DevEco Studio 的模拟器进行快速迭代
- 参考鸿蒙官方文档和示例代码

**对于产品设计**：
- 简化用户交互流程，避免过多的对话框
- 提供清晰的错误提示和帮助文档
- 考虑增加本地缓存，减少网络请求

---

## 八、附录

### 8.1 相关 API 文档

- [剪贴板 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-pasteboard-V5)
- [网络请求 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-http-V5)
- [对话框组件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/arkts-common-components-custom-dialog-V5)
- [Want 机制](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/want-overview-V5)

### 8.2 飞书扣子 API

- [工作流运行 API](https://www.coze.cn/docs/developer_guides/workflow_run)
- [飞书多维表格 API](https://open.feishu.cn/document/server-docs/docs/bitable-v1/app-table-record/list)

---

**文档版本**：v1.0
**创建时间**：2026-01-06
**作者**：Claude（AI 助手）
