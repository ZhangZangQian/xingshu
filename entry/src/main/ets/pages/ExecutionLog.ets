import { ExecutionLog, Macro } from '../models/Macro';
import { DatabaseService } from '../services/DatabaseService';
import Logger from '../utils/Logger';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

/**
 * 执行日志页
 */
@Entry
@Component
struct ExecutionLogPage {
  @State logs: ExecutionLog[] = [];
  @State macros: Map<number, Macro> = new Map();
  @State loading: boolean = true;
  @State refreshing: boolean = false;
  private databaseService: DatabaseService = DatabaseService.getInstance();

  async aboutToAppear() {
    await this.loadLogs();
  }

  /**
   * 加载执行日志
   */
  private async loadLogs() {
    try {
      this.loading = true;
      this.logs = await this.databaseService.getAllExecutionLogs(100);

      // 加载所有关联的宏信息
      const uniqueIds: number[] = [];
      const idSet = new Set<number>();
      for (const log of this.logs) {
        if (!idSet.has(log.macroId)) {
          idSet.add(log.macroId);
          uniqueIds.push(log.macroId);
        }
      }
      for (const macroId of uniqueIds) {
        try {
          const macro = await this.databaseService.getMacroById(macroId);
          if (macro) {
            this.macros.set(macroId, macro);
          }
        } catch (error) {
          const errorMsg = (error as Error).message || 'Unknown error';
          Logger.warn('ExecutionLog', `Failed to load macro ${macroId}: ${errorMsg}`);
        }
      }

      Logger.info('ExecutionLog', `Loaded ${this.logs.length} logs`);
    } catch (error) {
      Logger.error('ExecutionLog', 'Failed to load logs', error as Error);
      promptAction.showToast({ message: '加载日志失败' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 下拉刷新
   */
  private async onRefresh() {
    this.refreshing = true;
    await this.loadLogs();
    this.refreshing = false;
  }

  /**
   * 点击日志项，跳转到详情页
   */
  private handleLogClick(log: ExecutionLog) {
    router.pushUrl({
      url: 'pages/ExecutionLogDetail',
      params: {
        logId: log.id
      }
    });
  }

  /**
   * 返回首页
   */
  private handleBack() {
    router.back();
  }

  /**
   * 获取宏信息
   */
  private getMacro(macroId: number): Macro | undefined {
    return this.macros.get(macroId);
  }

  /**
   * 格式化时间戳
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    return `${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  /**
   * 获取状态颜色
   */
  private getStatusColor(status: string): string {
    switch (status) {
      case 'success':
        return '#52c41a';
      case 'failed':
        return '#ff4d4f';
      case 'partial':
        return '#faad14';
      default:
        return '#999999';
    }
  }

  /**
   * 获取状态文本
   */
  private getStatusText(status: string): string {
    switch (status) {
      case 'success':
        return '成功';
      case 'failed':
        return '失败';
      case 'partial':
        return '部分失败';
      default:
        return '未知';
    }
  }

  /**
   * 获取状态图标
   */
  private getStatusIcon(status: string): string {
    switch (status) {
      case 'success':
        return '✓';
      case 'failed':
        return '✗';
      case 'partial':
        return '!';
      default:
        return '?';
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            this.handleBack();
          })

        Text('执行日志')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .flexGrow(1)
          .textAlign(TextAlign.Center)

        // 占位，保持布局对称
        Text('')
          .width(60)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#ffffff')

      // 日志列表
      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')

          Text('加载中...')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.logs.length === 0) {
        Column() {
          Text('📋')
            .fontSize(64)
            .margin({ bottom: 16 })

          Text('暂无执行日志')
            .fontSize(16)
            .fontColor('#999999')

          Text('执行宏后将显示日志记录')
            .fontSize(14)
            .fontColor('#CCCCCC')
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Refresh({ refreshing: $$this.refreshing }) {
          Scroll() {
            Column({ space: 12 }) {
              ForEach(this.logs, (log: ExecutionLog) => {
                Column({ space: 0 }) {
                  // 顶部状态栏
                  Row() {
                    // 状态图标
                    Text(this.getStatusIcon(log.status))
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#ffffff')
                      .width(32)
                      .height(32)
                      .borderRadius(16)
                      .backgroundColor(this.getStatusColor(log.status))
                      .textAlign(TextAlign.Center)

                    Column({ space: 4 }) {
                      // 宏名称
                      Text(this.getMacro(log.macroId)?.name || `宏 #${log.macroId}`)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#333333')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      // 触发方式
                      Row({ space: 8 }) {
                        Text('触发：')
                          .fontSize(12)
                          .fontColor('#999999')

                        Text(this.getTriggerTypeText(log.triggerType))
                          .fontSize(12)
                          .fontColor('#666666')
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                    .margin({ left: 12 })

                    // 状态标签
                    Text(this.getStatusText(log.status))
                      .fontSize(12)
                      .fontColor(this.getStatusColor(log.status))
                      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                      .backgroundColor(this.getStatusColor(log.status) + '15')
                      .borderRadius(12)
                  }
                  .width('100%')
                  .padding(16)
                  .backgroundColor('#ffffff')
                  .borderRadius({ topLeft: 12, topRight: 12 })

                  // 底部信息栏
                  Row() {
                    // 时间
                    Row({ space: 4 }) {
                      Text('🕐')
                        .fontSize(12)

                      Text(this.formatTime(log.executedAt))
                        .fontSize(12)
                        .fontColor('#999999')
                    }

                    // 分隔符
                    Text('|')
                      .fontSize(12)
                      .fontColor('#DDDDDD')
                      .margin({ left: 8, right: 8 })

                    // 执行时长
                    Row({ space: 4 }) {
                      Text('⏱')
                        .fontSize(12)

                      Text(`${log.duration}ms`)
                        .fontSize(12)
                        .fontColor('#999999')
                    }

                    Blank()

                    // 查看详情箭头
                    Text('查看详情')
                      .fontSize(12)
                      .fontColor('#007DFF')
                  }
                  .width('100%')
                  .padding(12)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor('#FAFAFA')
                  .borderRadius({ bottomLeft: 12, bottomRight: 12 })
                  .onClick(() => {
                    this.handleLogClick(log);
                  })
                }
                .backgroundColor('#ffffff')
                .borderRadius(12)
                .shadow({
                  radius: 4,
                  color: 'rgba(0, 0, 0, 0.08)',
                  offsetX: 0,
                  offsetY: 2
                })
              }, (log: ExecutionLog) => log.id.toString())
            }
            .padding(16)
            .width('100%')
          }
          .flexGrow(1)
          .scrollBar(BarState.Auto)
        }
        .flexGrow(1)
        .onStateChange((status: RefreshStatus) => {
          if (status === RefreshStatus.Inactive && this.refreshing) {
            this.onRefresh();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  /**
   * 获取触发类型文本
   */
  private getTriggerTypeText(triggerType: string): string {
    switch (triggerType) {
      case 'time':
        return '定时';
      case 'network':
        return '网络';
      case 'manual':
        return '手动';
      case 'clipboard':
        return '剪贴板';
      default:
        return triggerType;
    }
  }
}
