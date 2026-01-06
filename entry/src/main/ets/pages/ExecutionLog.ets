import { ExecutionLog } from '../models/Macro';
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
  @State loading: boolean = true;
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
      Logger.info('ExecutionLog', `Loaded ${this.logs.length} logs`);
    } catch (error) {
      Logger.error('ExecutionLog', 'Failed to load logs', error as Error);
      promptAction.showToast({ message: '加载日志失败' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 返回首页
   */
  private handleBack() {
    router.back();
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
          Text('加载中...')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.logs.length === 0) {
        Column() {
          Text('暂无执行日志')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 0 }) {
            ForEach(this.logs, (log: ExecutionLog) => {
              Column({ space: 8 }) {
                // 第一行：宏 ID 和状态
                Row() {
                  Text(`宏 #${log.macroId}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .flexGrow(1)

                  Text(this.getStatusText(log.status))
                    .fontSize(14)
                    .fontColor(this.getStatusColor(log.status))
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor(this.getStatusColor(log.status) + '20')
                    .borderRadius(4)
                }
                .width('100%')

                // 第二行：触发类型
                Text(`触发方式：${log.triggerType}`)
                  .fontSize(14)
                  .fontColor('#666666')

                // 第三行：执行时间和时长
                Row() {
                  Text(this.formatTime(log.executedAt))
                    .fontSize(12)
                    .fontColor('#999999')
                    .flexGrow(1)

                  Text(`${log.duration}ms`)
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .width('100%')

                // 错误信息（如果有）
                if (log.errorMessage) {
                  Text(log.errorMessage)
                    .fontSize(12)
                    .fontColor('#ff4d4f')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
              }
              .padding(16)
              .width('100%')
              .backgroundColor('#ffffff')
              .borderRadius(8)
              .margin({ bottom: 8 })
            }, (log: ExecutionLog) => log.id.toString())
          }
          .padding(16)
          .width('100%')
        }
        .flexGrow(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
