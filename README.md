# HarmonyOS 快捷指令 (HarmonyOS Shortcuts)

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-HarmonyOS%20Next-green.svg)
![License](https://img.shields.io/badge/license-MIT-orange.svg)

一款功能强大的 HarmonyOS Next 原生自动化应用，类似于 iPhone 快捷指令，帮助你通过简单的拖拽和配置，创建个性化的自动化工作流。

</div>

## ✨ 特性

### 🎯 核心功能

- **快捷方式管理**：创建、编辑、管理你的快捷方式
- **可视化编辑器**：直观的工作流编辑界面，支持拖拽配置
- **触发器系统**：支持时间、位置、事件等多种触发方式
- **丰富动作库**：内置数百种系统动作，覆盖通信、媒体、办公等场景
- **条件判断**：支持 If/Else 条件逻辑，实现复杂自动化
- **嵌套流程**：支持多层级嵌套，构建强大的工作流
- **智能建议**：基于使用习惯推荐相关动作

### 🎨 界面设计

- **深色模式**：自动适配系统主题，支持深色模式
- **流畅动画**：丝滑的过渡动画和交互反馈
- **响应式布局**：完美适配各种屏幕尺寸

### ⚡ 性能优化

- **原生实现**：HarmonyOS Next 原生开发，性能卓越
- **即时执行**：毫秒级响应，无延迟触发
- **低功耗**：优化的后台执行策略，省电省流量
- **离线运行**：大部分动作支持离线执行

## 📸 截图

| 首页 | 编辑器 |
|------|--------|
| ![首页](docs/images/home.png) | ![编辑器](docs/images/editor.png) |

*截图将在项目完成后添加*

## 🏗️ 项目结构

```
xingshu_v2/
├── entry/                          # 应用主模块
│   └── src/
│       └── main/
│           ├── ets/
│           │   ├── entryability/
│           │   │   └── EntryAbility.ets     # 应用入口
│           │   └── pages/
│           │       ├── Index.ets            # 首页 - 快捷方式列表
│           │       └── MacroEditor.ets      # 编辑器 - 工作流编辑
│           └── resources/                  # 资源文件
│               ├── base/element/           # 颜色、字符串等资源
│               └── base/media/             # 图片、图标资源
├── html/                            # 原始 HTML 设计参考
│   ├── index.html                     # 首页设计
│   └── macro_editor.html              # 编辑器设计
├── docs/                            # 项目文档
│   ├── README.md                     # 项目说明
│   ├── HarmonyOS-首页实现文档.md      # 首页实现细节
│   ├── MacroEditor-页面实现文档.md    # 编辑器实现细节
│   ├── HarmonyOS-系统图标使用指南.md  # 系统图标使用
│   └── 项目完成总结.md               # 项目总结
├── AppScope/                        # 应用全局配置
├── build-profile.json5               # 构建配置
└── oh-package.json5                  # 依赖配置
```

## 🚀 快速开始

### 环境要求

- **DevEco Studio**: 5.0.3 或更高版本
- **HarmonyOS SDK**: API 15 或更高版本
- **Node.js**: 16.x 或更高版本
- **操作系统**: Windows 10/11, macOS, Linux

### 安装步骤

1. **克隆项目**

```bash
git clone https://github.com/your-username/xingshu_v2.git
cd xingshu_v2
```

2. **打开项目**

使用 DevEco Studio 打开项目文件夹，IDE 会自动识别并配置项目。

3. **等待依赖下载**

IDE 会自动下载所需的 HarmonyOS SDK 和依赖包，请耐心等待。

4. **连接设备或启动模拟器**

- 连接 HarmonyOS Next 真机
- 或在 DevEco Studio 中启动模拟器

5. **运行应用**

点击 DevEco Studio 工具栏的运行按钮，或使用快捷键 `Shift + F10`

### 编译配置

项目使用以下配置：

```json5
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

## 💡 使用指南

### 创建快捷方式

1. 在首页点击右上角的 `+` 按钮
2. 进入编辑器页面
3. 配置触发器（如时间、位置等）
4. 添加动作（如发送消息、播放音乐等）
5. 点击右上角 `Done` 保存

### 编辑快捷方式

1. 在首页点击任意快捷方式卡片
2. 进入编辑器页面
3. 修改触发器或动作
4. 点击 `Done` 保存更改

### 运行快捷方式

- 在首页快捷方式卡片上点击播放按钮
- 或在编辑器中点击底部播放按钮
- 快捷方式将立即执行配置的动作

### 快捷方式示例

#### 🌅 晨间提醒

**触发器**: 每天早上 7:00

**动作**:
1. 获取当前天气
2. 如果温度 > 30°C
   - 发送消息给家人："今天天气很热，注意防暑！"
3. 播放"晨间活力"歌单

#### 🏠 到家提醒

**触发器**: 到达家附近 100 米

**动作**:
1. 发送消息到家庭群："我快到家了"
2. 打开家中 Wi-Fi
3. 设置空调为舒适温度

#### 🔋 省电模式

**触发器**: 电量 < 20%

**动作**:
1. 关闭蓝牙
2. 降低屏幕亮度
3. 关闭后台应用
4. 发送通知："电量低，已启用省电模式"

## 🛠️ 技术栈

### 核心技术

- **开发语言**: ArkTS (TypeScript)
- **UI 框架**: ArkUI
- **API Level**: HarmonyOS Next API 15+
- **IDE**: DevEco Studio 5.0+

### 主要特性

- **声明式 UI**: 基于 ArkUI 的声明式开发范式
- **响应式状态**: 使用 `@State` 实现数据驱动视图
- **路由导航**: 使用 `@ohos.router` 实现页面跳转
- **组件化开发**: 高度模块化的组件设计
- **类型安全**: TypeScript 类型检查，减少运行时错误

## 📦 开发计划

### 已完成 ✅

- [x] 首页快捷方式列表
- [x] 搜索功能
- [x] 底部导航栏
- [x] 工作流编辑器基础界面
- [x] 触发器卡片展示
- [x] 动作卡片列表
- [x] 条件块嵌套支持
- [x] 页面路由导航
- [x] 样式还原（95%+）

### 进行中 🚧

- [ ] 连接线绘制
- [ ] 添加/编辑/删除动作
- [ ] 拖拽排序功能

### 计划中 📋

- [ ] 完整的动作库
- [ ] 条件逻辑实现
- [ ] 变量系统
- [ ] 快捷方式分享
- [ ] iCloud 同步
- [ ] Widget 组件
- [ ] 语音触发
- [ ] 深色模式
- [ ] 动画效果增强
- [ ] 性能优化
- [ ] 数据持久化

## 🎯 核心功能详解

### 触发器 (Triggers)

触发器是启动快捷方式的条件，支持以下类型：

| 类型 | 说明 | 示例 |
|------|------|------|
| 时间 | 定时触发 | 每天早上 7:00 |
| 位置 | 到达/离开某个地点 | 到达公司 |
| 事件 | 系统事件 | 收到新邮件 |
| NFC | 扫描 NFC 标签 | 扫描工牌 |
| 语音 | 语音指令 | "Siri，执行晨间提醒" |

### 动作 (Actions)

动作是快捷方式执行的具体操作，包括：

**通信类**
- 发送短信/消息
- 发送邮件
- 拨打电话

**媒体类**
- 播放音乐
- 显示图片
- 录制视频

**系统类**
- 设置闹钟
- 调整音量
- 打开应用

**办公类**
- 创建日历事件
- 添加提醒事项
- 创建笔记

**位置类**
- 获取当前位置
- 导航到目的地
- 查找附近地点

### 条件判断 (Conditions)

支持复杂的条件逻辑：

- **If**: 如果条件满足，执行后续动作
- **Else**: 如果条件不满足，执行其他动作
- **Repeat**: 重复执行指定次数
- **Wait**: 等待指定时间
- **Choose**: 多条件分支

## 🤝 贡献

我们欢迎任何形式的贡献！

### 如何贡献

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

### 贡献指南

- 遵循现有代码风格
- 添加必要的注释
- 更新相关文档
- 确保所有测试通过
- 提交前进行代码审查

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

## 🙏 致谢

感谢以下开源项目和服务：

- [HarmonyOS](https://developer.huawei.com/consumer/cn/harmonyos/) - 华为鸿蒙操作系统
- [ArkUI](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/) - 鸿蒙声明式 UI 开发框架
- [Tailwind CSS](https://tailwindcss.com/) - 原始设计使用的 CSS 框架

## 📮 联系方式

- **Issues**: [提交问题](https://github.com/your-username/xingshu_v2/issues)
- **Discussions**: [参与讨论](https://github.com/your-username/xingshu_v2/discussions)
- **Email**: your-email@example.com

## 📊 项目进度

<details>
<summary>点击展开查看详细进度</summary>

### 功能开发进度

| 模块 | 进度 | 状态 |
|------|------|------|
| 首页界面 | 100% | ✅ 完成 |
| 编辑器界面 | 80% | 🚧 进行中 |
| 触发器系统 | 20% | ⏳ 计划中 |
| 动作库 | 10% | ⏳ 计划中 |
| 条件判断 | 30% | ⏳ 计划中 |
| 数据存储 | 0% | ⏳ 计划中 |
| 分享功能 | 0% | ⏳ 计划中 |

### UI 完成度

| 页面 | 还原度 | 状态 |
|------|--------|------|
| 首页 | 95% | ✅ 完成 |
| 编辑器 | 90% | ✅ 完成 |
| 设置页 | 0% | ⏳ 待开始 |

</details>

## 🎉 更新日志

### v1.0.0 (2025-01-12)

#### 新增
- ✨ 首页快捷方式列表界面
- ✨ 工作流编辑器界面
- ✨ 触发器和动作卡片展示
- ✨ 条件块嵌套支持
- ✨ 页面路由导航
- 🎨 iOS 风格设计
- 🎨 响应式布局

#### 优化
- ⚡ 性能优化
- 🐛 修复已知问题

---

<div align="center">

如果这个项目对你有帮助，请给它一个 ⭐️

Made with ❤️ by [Your Name]

</div>
