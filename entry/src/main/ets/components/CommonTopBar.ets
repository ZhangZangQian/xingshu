/**
 * 通用顶部导航栏
 * 使用全局 @Builder 实现统一的顶部栏布局
 */

/**
 * 顶部栏配置参数
 */
export interface TopBarConfig {
  /** 标题文本 */
  title: string;
  /** 左侧按钮文本（默认"取消"） */
  leftButtonText?: string;
  /** 右侧按钮文本（默认"保存"） */
  rightButtonText?: string;
  /** 左侧按钮点击回调 */
  onLeftClick: () => void;
  /** 右侧按钮点击回调 */
  onRightClick: () => void;
  /** 是否隐藏左侧按钮 */
  hideLeftButton?: boolean;
  /** 是否隐藏右侧按钮 */
  hideRightButton?: boolean;
  /** 是否需要避让状态栏（用于 @CustomDialog 等全屏场景，默认 false） */
  avoidStatusBar?: boolean;
}

/**
 * 通用顶部导航栏 Builder
 *
 * 使用示例：
 * ```typescript
 * // 普通页面（@Entry）
 * CommonTopBar({
 *   title: '编辑宏',
 *   onLeftClick: () => { this.handleCancel(); },
 *   onRightClick: () => { this.handleSave(); }
 * })
 *
 * // 自定义对话框（@CustomDialog）需要避让状态栏
 * CommonTopBar({
 *   title: '编辑宏',
 *   avoidStatusBar: true,
 *   onLeftClick: () => { this.handleCancel(); },
 *   onRightClick: () => { this.handleSave(); }
 * })
 * ```
 */
@Builder
export function CommonTopBar(config: TopBarConfig) {
  Row() {
    // 左侧按钮
    if (!config.hideLeftButton) {
      Button(config.leftButtonText || '取消')
        .fontSize(16)
        .backgroundColor(Color.Transparent)
        .fontColor('#007DFF')
        .onClick(() => {
          config.onLeftClick();
        })
    } else {
      // 占位，保持布局对称
      Text('')
        .width(60)
    }

    // 中间标题
    Text(config.title)
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .flexGrow(1)
      .textAlign(TextAlign.Center)

    // 右侧按钮
    if (!config.hideRightButton) {
      Button(config.rightButtonText || '保存')
        .fontSize(16)
        .backgroundColor(Color.Transparent)
        .fontColor('#007DFF')
        .onClick(() => {
          config.onRightClick();
        })
    } else {
      // 占位，保持布局对称
      Text('')
        .width(60)
    }
  }
  .width('100%')
  .padding({
    left: 16,
    right: 16,
    top: config.avoidStatusBar ? 56 : 16, // 自定义对话框需要额外避让状态栏（48vp + 8vp）
    bottom: 16
  })
  .backgroundColor('#ffffff')
}
