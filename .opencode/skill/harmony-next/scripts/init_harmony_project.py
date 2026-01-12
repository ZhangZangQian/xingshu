#!/usr/bin/env python3
"""
HarmonyOS NEXT 项目初始化脚本

功能：
- 创建标准项目结构
- 生成基础配置文件
- 创建示例页面和组件
"""

import os
import sys
from pathlib import Path

def create_project_structure(project_name: str) -> None:
    """创建标准HarmonyOS项目结构"""
    project_path = Path(project_name)

    # 主目录
    dirs = [
        project_path / "src" / "main" / "ets" / "pages",
        project_path / "src" / "main" / "ets" / "components",
        project_path / "src" / "main" / "ets" / "viewmodels",
        project_path / "src" / "main" / "ets" / "services",
        project_path / "src" / "main" / "ets" / "models",
        project_path / "src" / "main" / "ets" / "utils",
        project_path / "src" / "main" / "resources" / "base" / "element",
        project_path / "src" / "main" / "resources" / "base" / "media",
        project_path / "src" / "main" / "resources" / "rawfile",
    ]

    for dir_path in dirs:
        dir_path.mkdir(parents=True, exist_ok=True)

    print(f"项目结构已创建在: {project_path}")

def create_sample_files(project_name: str) -> None:
    """创建示例文件"""
    project_path = Path(project_name)

    # EntryAbility.ets
    entry_ability = project_path / "src" / "main" / "ets" / "entryability" / "EntryAbility.ets"
    entry_ability.parent.mkdir(parents=True, exist_ok=True)
    entry_ability.write_text("""import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    console.info('[EntryAbility] onCreate');
  }

  onDestroy() {
    console.info('[EntryAbility] onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    console.info('[EntryAbility] onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('Failed to load content. Cause: ' + JSON.stringify(err));
        return;
      }
      console.info('Succeeded in loading content.');
    });
  }

  onWindowStageDestroy() {
    console.info('[EntryAbility] onWindowStageDestroy');
  }

  onForeground() {
    console.info('[EntryAbility] onForeground');
  }

  onBackground() {
    console.info('[EntryAbility] onBackground');
  }
}
""")

    # Index.ets
    index_page = project_path / "src" / "main" / "ets" / "pages" / "Index.ets"
    index_page.write_text("""@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)

        Button('Click Me')
          .fontSize(20)
          .width(200)
          .height(50)
          .margin({ top: 20 })
          .onClick(() => {
            this.message = 'Hello HarmonyOS NEXT!';
          })
      }
      .width('100%')
    }
    .height('100%')
  }
}
""")

    # app.json5
    app_json = project_path / "AppScope" / "app.json5"
    app_json.parent.mkdir(parents=True, exist_ok=True)
    app_json.write_text("""{
  "app": {
    "bundleName": "com.example.{0}",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:app_icon",
    "label": "$string:app_name",
    "targetAPIVersion": 12
  }
}
""".format(project_name.lower()))

    # module.json5
    module_json = project_path / "src" / "main" / "module.json5"
    module_json.write_text("""{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "default",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:icon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ]
  }
}
""")

    print("示例文件已创建")

def create_utils(project_name: str) -> None:
    """创建工具类"""
    project_path = Path(project_name)

    # Logger.ets
    logger = project_path / "src" / "main" / "ets" / "utils" / "Logger.ets"
    logger.write_text("""import hilog from '@ohos.hilog';

export class Logger {
  private static DOMAIN: number = 0x0001;
  private static TAG: string = '{0}';

  static debug(message: string, ...args: unknown[]): void {
    hilog.debug(this.DOMAIN, this.TAG, message, ...args);
  }

  static info(message: string, ...args: unknown[]): void {
    hilog.info(this.DOMAIN, this.TAG, message, ...args);
  }

  static warn(message: string, ...args: unknown[]): void {
    hilog.warn(this.DOMAIN, this.TAG, message, ...args);
  }

  static error(message: string, ...args: unknown[]): void {
    hilog.error(this.DOMAIN, this.TAG, message, ...args);
  }
}
""".format(project_name))

    print("工具类已创建")

def main():
    if len(sys.argv) < 2:
        print("用法: python init_harmony_project.py <项目名称>")
        sys.exit(1)

    project_name = sys.argv[1]

    print(f"正在初始化 HarmonyOS NEXT 项目: {project_name}")

    create_project_structure(project_name)
    create_sample_files(project_name)
    create_utils(project_name)

    print("\n项目初始化完成！")
    print(f"\n下一步:")
    print(f"1. 打开 DevEco Studio")
    print(f"2. 选择 File > Open")
    print(f"3. 选择项目目录: {project_name}")
    print(f"4. 开始开发您的 HarmonyOS NEXT 应用")

if __name__ == "__main__":
    main()
