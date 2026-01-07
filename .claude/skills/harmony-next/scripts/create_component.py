#!/usr/bin/env python3
"""
HarmonyOS Next 自定义组件模板生成脚本
用法: python create_component.py <组件名称> [--path 输出路径]
示例: python create_component.py CustomButton --path src/main/ets/components
"""

import os
import sys
import argparse
from pathlib import Path


def to_pascal_case(name: str) -> str:
    """转换为大驼峰命名"""
    return ''.join(word.capitalize() for word in name.split('_'))


def create_component_template(component_name: str) -> str:
    """生成组件模板代码"""
    pascal_name = to_pascal_case(component_name)

    template = f'''/**
 * {pascal_name} 自定义组件
 *
 * @example
 * {pascal_name}({{
 *   title: '标题',
 *   onClick: () => {{
 *     console.info('Clicked');
 *   }}
 * }})
 */
@Component
export struct {pascal_name} {{
  // 父组件传入的属性 (单向同步)
  @Prop title: string = '';

  // 父子组件双向绑定
  @Link isSelected: boolean;

  // 组件内部状态
  @State private internalState: string = '';

  // 回调函数
  private onClick?: () => void;
  private onLongPress?: () => void;

  /**
   * 组件即将挂载
   */
  aboutToAppear() {{
    console.info('[{pascal_name}] aboutToAppear');
    this.initialize();
  }}

  /**
   * 组件即将卸载
   */
  aboutToDisappear() {{
    console.info('[{pascal_name}] aboutToDisappear');
    this.cleanup();
  }}

  /**
   * 初始化组件
   */
  private initialize() {{
    // TODO: 初始化逻辑
  }}

  /**
   * 清理资源
   */
  private cleanup() {{
    // TODO: 清理逻辑
  }}

  /**
   * 处理点击事件
   */
  private handleClick() {{
    console.info('[{pascal_name}] handleClick');
    this.onClick?.();
  }}

  /**
   * 处理长按事件
   */
  private handleLongPress() {{
    console.info('[{pascal_name}] handleLongPress');
    this.onLongPress?.();
  }}

  /**
   * 构建组件UI
   */
  build() {{
    Column() {{
      // TODO: 实现组件UI
      Text(this.title)
        .fontSize(16)
        .fontColor('#333333')

      Text('这是一个自定义组件模板')
        .fontSize(14)
        .fontColor('#999999')
        .margin({{ top: 8 }})
    }}
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => this.handleClick())
    .gesture(
      LongPressGesture({{ repeat: false }})
        .onAction(() => this.handleLongPress())
    )
  }}
}}

/**
 * 组件预览 (仅用于开发时预览)
 */
@Preview
@Component
struct {pascal_name}Preview {{
  @State isSelected: boolean = false;

  build() {{
    Column({{ space: 12 }}) {{
      {pascal_name}({{
        title: '示例标题',
        isSelected: $isSelected,
        onClick: () => {{
          console.info('Preview clicked');
        }}
      }})

      Text(`选中状态: ${{this.isSelected}}`)
        .fontSize(14)
        .fontColor('#666666')

      Button('切换选中状态')
        .onClick(() => {{
          this.isSelected = !this.isSelected;
        }})
    }}
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
  }}
}}
'''
    return template


def main():
    parser = argparse.ArgumentParser(description='生成 HarmonyOS Next 自定义组件模板')
    parser.add_argument('name', help='组件名称 (如: CustomButton, UserCard)')
    parser.add_argument('--path', default='components', help='输出路径 (默认: components)')

    args = parser.parse_args()

    component_name = args.name
    output_path = Path(args.path)

    # 创建输出目录
    output_path.mkdir(parents=True, exist_ok=True)

    # 生成文件
    pascal_name = to_pascal_case(component_name)
    file_name = f"{pascal_name}.ets"
    file_path = output_path / file_name

    if file_path.exists():
        response = input(f"文件 {file_path} 已存在,是否覆盖? (y/N): ")
        if response.lower() != 'y':
            print("操作已取消")
            return

    # 写入文件
    template_code = create_component_template(component_name)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(template_code)

    print(f"✓ 组件创建成功: {file_path}")
    print(f"\n使用方法:")
    print(f"1. 在需要使用的页面中导入:")
    print(f"   import {{ {pascal_name} }} from '../{args.path}/{pascal_name}';")
    print(f"2. 在 build() 方法中使用:")
    print(f'''   {pascal_name}({{
     title: '标题',
     isSelected: $isSelected
   }})''')


if __name__ == '__main__':
    main()
