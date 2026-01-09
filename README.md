# 鸿蒙宏（HarmonyMacro）

鸿蒙 Next 原生自动化宏应用 - 类似 iPhone 快捷指令的自动化工具

## 项目信息

- **应用名称**: 鸿蒙宏 (HarmonyMacro)
- **Bundle Name**: com.example.harmonymacro
- **版本**: 1.0.0 (1000000)
- **目标 API**: HarmonyOS NEXT API 12
- **开发工具**: DevEco Studio 4.0+

## 项目结构

```
HarmonyMacro/
├── AppScope/                    # 应用级配置
│   ├── app.json5               # 应用全局配置
│   └── resources/              # 应用级资源
│       └── base/
│           ├── element/        # 字符串资源
│           └── media/          # 媒体资源
├── entry/                      # 主模块
│   ├── src/
│   │   ├── main/              # 主代码
│   │   │   ├── ets/           # ArkTS 代码
│   │   │   ├── resources/     # 模块资源
│   │   │   └── module.json5   # 模块配置
│   │   └── ohosTest/          # 单元测试
│   ├── build-profile.json5    # 模块构建配置
│   ├── hvigorfile.ts          # 模块构建脚本
│   ├── obfuscation-rules.txt  # 混淆规则
│   └── oh-package.json5       # 依赖配置
├── hvigor/                     # Hvigor 构建工具配置
│   └── hvigor-config.json5
├── build-profile.json5         # 工程构建配置
├── hvigorfile.ts              # 工程构建脚本
└── docs/                       # 项目文档

```

## 核心功能

### MVP 阶段（v1.0.0）

#### 触发器系统
- ✅ 定时触发器（每日、每周、自定义间隔）
- ✅ 网络状态触发器（Wi-Fi 连接/断开、移动数据）
- ✅ 手动触发器（应用内按钮、桌面快捷方式）

#### 动作系统
- ✅ 启动应用（显式/隐式）
- ✅ 发送通知
- ✅ HTTP 请求（GET/POST/PUT/DELETE）
- ✅ 剪贴板操作（读/写）
- ✅ 打开 URL / Deep Link
- ✅ 文本处理（正则提取、替换）
- ✅ 用户交互对话框（确认、单选、多选、输入）

#### 其他特性
- ✅ 变量系统（系统变量 + 动作输出变量）
- ✅ 条件判断（8 种运算符）
- ✅ 执行日志（查看历史记录）
- ✅ 错误处理和通知

## 参考场景："快小红"

完整实现小红书内容采集到飞书多维表格的自动化流程：

1. 复制小红书链接
2. 点击桌面快捷方式触发宏
3. 读取剪贴板并提取 URL
4. 用户选择爆款标记、分类标签、对标参考
5. 调用飞书扣子 API 上传数据
6. 打开飞书多维表格查看结果

## 快速开始

### 前置要求

- DevEco Studio 4.0+
- HarmonyOS NEXT SDK API 12
- 华为开发者账号（用于真机调试和上架）

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd HarmonyMacro
```

2. **打开项目**
- 启动 DevEco Studio
- File → Open → 选择项目根目录

3. **同步依赖**
- DevEco Studio 会自动同步 oh-package.json5 中的依赖
- 如果未自动同步，点击 "Sync Now"

4. **配置签名**
- 在 DevEco Studio 中配置自动签名
- File → Project Structure → Signing Configs

5. **运行项目**
- 连接鸿蒙设备或启动模拟器
- 点击 Run 按钮

## 开发指南

### 添加新的触发器类型

1. 在 `TriggerTypes.ts` 中添加类型常量
2. 在 `TriggerManager.ts` 中实现注册逻辑
3. 在 UI 中添加配置界面

### 添加新的动作类型

1. 在 `ActionTypes.ts` 中添加类型常量
2. 创建新的动作执行器（继承 `BaseAction`）
3. 在 `EntryAbility.ts` 中注册执行器
4. 在 UI 中添加配置界面

### 调试技巧

- 使用 `Logger.debug()` 记录详细日志
- 在 DevEco Studio 中查看 Hilog 输出
- 使用 Chrome DevTools 调试 WebView（如果有）

## 构建与发布

### 构建 HAP 包

```bash
# MacOS 环境
## Debug 版本
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p requiredDeviceType=tablet assembleHap --analyze=normal --parallel --incremental --daemon

## Release 版本
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p requiredDeviceType=tablet assembleHap --analyze=normal --parallel --incremental --daemon --release


# Windows 环境
## Debug 版本
"D:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon

## Release 版本
"D:\Program Files\Huawei\DevEco Studio\tools\node\node.exe" "D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon --release
```

### 上架华为应用市场

1. 在 AppGallery Connect 创建应用
2. 配置应用信息、图标、截图
3. 上传 HAP 包
4. 提交审核

## 技术亮点

- 🌟 **DialogEventBus 架构**: 反向依赖注入，优雅解决服务层与 UI 层通信
- 🌟 **智能时间计算**: 精确的模运算算法处理跨周/跨天场景
- 🌟 **降级方案设计**: 连续单选模拟多选，无需 UI 层配合
- 🌟 **完整的错误处理**: 统一 try-catch + 详细日志 + 用户通知

## 贡献指南

欢迎贡献代码、报告 Bug 或提出新功能建议！

### 提交 Pull Request

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件

## 联系方式

- 项目主页: <repository-url>
- 问题反馈: <repository-url>/issues
- 文档: `./docs/`

## 致谢

- 华为鸿蒙团队提供的优秀开发平台
- 所有贡献者的辛勤付出

---

**最后更新**: 2026-01-06
**项目状态**: MVP 开发完成，待测试
