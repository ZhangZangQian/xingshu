#!/usr/bin/env python3
"""
HarmonyOS Next 页面模板生成脚本
用法: python create_page.py <页面名称> [--path 输出路径]
示例: python create_page.py HomePage --path src/main/ets/pages
"""

import os
import sys
import argparse
from pathlib import Path


def to_pascal_case(name: str) -> str:
    """转换为大驼峰命名"""
    return ''.join(word.capitalize() for word in name.split('_'))


def create_page_template(page_name: str) -> str:
    """生成页面模板代码"""
    pascal_name = to_pascal_case(page_name)

    template = f'''import router from '@ohos.router';

/**
 * {pascal_name} 页面
 */
@Entry
@Component
struct {pascal_name} {{
  @State message: string = '{pascal_name}';
  @State isLoading: boolean = false;

  /**
   * 页面即将出现
   */
  aboutToAppear() {{
    console.info('[{pascal_name}] aboutToAppear');
    this.loadData();
  }}

  /**
   * 页面即将消失
   */
  aboutToDisappear() {{
    console.info('[{pascal_name}] aboutToDisappear');
  }}

  /**
   * 加载数据
   */
  async loadData() {{
    this.isLoading = true;
    try {{
      // TODO: 实现数据加载逻辑
      console.info('[{pascal_name}] Loading data...');
    }} catch (err) {{
      console.error('[{pascal_name}] Load data error:', JSON.stringify(err));
    }} finally {{
      this.isLoading = false;
    }}
  }}

  /**
   * 返回上一页
   */
  goBack() {{
    router.back();
  }}

  /**
   * 构建页面UI
   */
  build() {{
    Column() {{
      // 标题栏
      Row() {{
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => this.goBack())

        Text(this.message)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位保持居中
        Blank().width(24)
      }}
      .width('100%')
      .height(56)
      .padding({{ left: 16, right: 16 }})
      .backgroundColor('#FFFFFF')

      // 内容区域
      if (this.isLoading) {{
        // 加载中
        Column() {{
          LoadingProgress()
            .width(50)
            .height(50)
          Text('加载中...')
            .margin({{ top: 12 }})
            .fontSize(14)
            .fontColor('#999999')
        }}
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }} else {{
        // 页面内容
        Column() {{
          Text('页面内容')
            .fontSize(16)
        }}
        .width('100%')
        .layoutWeight(1)
        .padding(16)
      }}
    }}
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }}
}}
'''
    return template


def main():
    parser = argparse.ArgumentParser(description='生成 HarmonyOS Next 页面模板')
    parser.add_argument('name', help='页面名称 (如: HomePage, UserDetail)')
    parser.add_argument('--path', default='pages', help='输出路径 (默认: pages)')

    args = parser.parse_args()

    page_name = args.name
    output_path = Path(args.path)

    # 创建输出目录
    output_path.mkdir(parents=True, exist_ok=True)

    # 生成文件
    pascal_name = to_pascal_case(page_name)
    file_name = f"{pascal_name}.ets"
    file_path = output_path / file_name

    if file_path.exists():
        response = input(f"文件 {file_path} 已存在,是否覆盖? (y/N): ")
        if response.lower() != 'y':
            print("操作已取消")
            return

    # 写入文件
    template_code = create_page_template(page_name)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(template_code)

    print(f"✓ 页面创建成功: {file_path}")
    print(f"\n下一步:")
    print(f"1. 在 src/main/resources/base/profile/main_pages.json 中注册页面:")
    print(f'   "src/main/ets/{args.path}/{file_name}"')
    print(f"2. 实现页面的业务逻辑")


if __name__ == '__main__':
    main()
'''