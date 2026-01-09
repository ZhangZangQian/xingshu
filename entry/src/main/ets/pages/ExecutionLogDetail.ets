import { ExecutionLog, ActionExecutionLog, Action } from '../models/Macro';
import { DatabaseService } from '../services/DatabaseService';
import { ActionTypes } from '../constants/ActionTypes';
import Logger from '../utils/Logger';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

/**
 * 执行日志详情页
 */
@Entry
@Component
struct ExecutionLogDetailPage {
  @State logId: number = 0;
  @State executionLog: ExecutionLog | null = null;
  @State actionLogs: ActionExecutionLog[] = [];
  @State actions: Map<number, Action> = new Map();
  @State loading: boolean = true;
  @State showDetails: Map<number, boolean> = new Map();
  private databaseService: DatabaseService = DatabaseService.getInstance();

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.logId = params?.logId as number || 0;

    if (this.logId > 0) {
      await this.loadData();
    } else {
      promptAction.showToast({ message: '日志 ID 无效' });
      router.back();
    }
  }

  /**
   * 加载数据
   */
  private async loadData() {
    try {
      this.loading = true;

      // 加载执行日志
      this.executionLog = await this.databaseService.getExecutionLogById(this.logId);

      if (!this.executionLog) {
        promptAction.showToast({ message: '未找到日志记录' });
        router.back();
        return;
      }

      // 加载动作执行日志
      this.actionLogs = await this.databaseService.getActionExecutionLogsByExecutionLogId(this.logId);

      // 加载所有关联的动作信息
      const actionIds = this.actionLogs.map(log => log.actionId);
      for (const actionId of actionIds) {
        try {
          const action = await this.databaseService.getActionById(actionId);
          if (action) {
            this.actions.set(actionId, action);
          }
        } catch (error) {
          const errorMsg = (error as Error).message || 'Unknown error';
          Logger.warn('ExecutionLogDetail', `Failed to load action ${actionId}: ${errorMsg}`);
        }
      }

      // 默认展开失败的动作
      this.actionLogs.forEach(log => {
        if (log.status === 'failed') {
          this.showDetails.set(log.id, true);
        }
      });

      Logger.info('ExecutionLogDetail', `Loaded ${this.actionLogs.length} action logs`);
    } catch (error) {
      Logger.error('ExecutionLogDetail', 'Failed to load data', error as Error);
      promptAction.showToast({ message: '加载数据失败' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 返回
   */
  private handleBack() {
    router.back();
  }

  /**
   * 切换详情展开状态
   */
  private toggleDetails(logId: number) {
    const current = this.showDetails.get(logId) || false;
    this.showDetails.set(logId, !current);
  }

  /**
   * 格式化时间戳
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    const milliseconds = String(date.getMilliseconds()).padStart(3, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${milliseconds}`;
  }

  /**
   * 格式化时间戳（短格式）
   */
  private formatShortTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    const milliseconds = String(date.getMilliseconds()).padStart(3, '0');
    return `${hours}:${minutes}:${seconds}.${milliseconds}`;
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
   * 获取动作类型文本
   */
  private getActionTypeText(actionType: string): string {
    return ActionTypes.getDisplayName(actionType);
  }

  /**
   * 获取触发类型文本
   */
  private getTriggerTypeText(triggerType: string): string {
    switch (triggerType) {
      case 'time':
        return '定时触发';
      case 'network':
        return '网络触发';
      case 'manual':
        return '手动触发';
      case 'clipboard':
        return '剪贴板触发';
      default:
        return triggerType;
    }
  }

  /**
   * 格式化 JSON 数据
   */
  private formatJsonData(jsonStr: string | undefined): string {
    if (!jsonStr) return '无';
    try {
      const data: ESObject = JSON.parse(jsonStr);
      return JSON.stringify(data, null, 2);
    } catch {
      return jsonStr;
    }
  }

  /**
   * 获取动作配置
   */
  private getAction(actionId: number): Action | undefined {
    return this.actions.get(actionId);
  }

  /**
   * 检查是否显示详情
   */
  private shouldShowDetail(logId: number): boolean {
    return this.showDetails.get(logId) || false;
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button() {
          Row({ space: 4 }) {
            Text('←')
              .fontSize(20)
              .fontColor('#007DFF')
            Text('返回')
              .fontSize(16)
              .fontColor('#007DFF')
          }
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.handleBack();
        })

        Text('执行日志详情')
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
      .border({ width: { bottom: 1 }, color: '#E5E5E5' })

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#007DFF')

          Text('加载中...')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.executionLog) {
        Scroll() {
          Column({ space: 16 }) {
            // 执行日志概览卡片
            Column({ space: 12 }) {
              // 状态图标和标题
              Row() {
                Text(this.getStatusText(this.executionLog.status) === '成功' ? '✓' :
                     this.getStatusText(this.executionLog.status) === '失败' ? '✗' : '!')
                  .fontSize(32)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#ffffff')
                  .width(56)
                  .height(56)
                  .borderRadius(28)
                  .backgroundColor(this.getStatusColor(this.executionLog.status))
                  .textAlign(TextAlign.Center)

                Column({ space: 6 }) {
                  Text(this.getStatusText(this.executionLog.status))
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getStatusColor(this.executionLog.status))

                  Text(`耗时 ${this.executionLog.duration}ms`)
                    .fontSize(14)
                    .fontColor('#999999')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 16 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#ffffff')
              .borderRadius({ topLeft: 12, topRight: 12 })

              // 详细信息
              Column({ space: 10 }) {
                Row() {
                  Text('触发方式')
                    .fontSize(14)
                    .fontColor('#666666')
                    .width(80)

                  Text(this.getTriggerTypeText(this.executionLog.triggerType))
                    .fontSize(14)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                }
                .width('100%')

                Row() {
                  Text('执行时间')
                    .fontSize(14)
                    .fontColor('#666666')
                    .width(80)

                  Text(this.formatTime(this.executionLog.executedAt))
                    .fontSize(14)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                }
                .width('100%')

                if (this.executionLog.errorMessage) {
                  Column({ space: 8 }) {
                    Text('错误信息')
                      .fontSize(14)
                      .fontColor('#666666')
                      .fontWeight(FontWeight.Medium)

                    Text(this.executionLog.errorMessage)
                      .fontSize(14)
                      .fontColor('#ff4d4f')
                      .lineHeight(22)
                      .padding(12)
                      .backgroundColor('#FFF1F0')
                      .borderRadius(6)
                      .width('100%')
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }
              }
              .width('100%')
              .padding(16)
              .padding({ top: 0 })
              .backgroundColor('#FAFAFA')
              .borderRadius({ bottomLeft: 12, bottomRight: 12 })
            }
            .width('100%')
            .shadow({
              radius: 6,
              color: 'rgba(0, 0, 0, 0.08)',
              offsetX: 0,
              offsetY: 2
            })

            // 动作执行日志标题
            Row() {
              Text('动作执行详情')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')

              Blank()

              Text(`${this.actionLogs.length} 个动作`)
                .fontSize(14)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 4, right: 4 })

            // 动作执行日志列表
            if (this.actionLogs.length === 0) {
              Column() {
                Text('📝')
                  .fontSize(48)
                  .margin({ bottom: 12 })

                Text('暂无动作执行记录')
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding({ top: 32, bottom: 32 })
              .justifyContent(FlexAlign.Center)
            } else {
              Column({ space: 12 }) {
                ForEach(this.actionLogs, (actionLog: ActionExecutionLog, index: number) => {
                  Column({ space: 0 }) {
                    // 时间线节点和基本信息
                    Row() {
                      // 时间线
                      Column({ space: 0 }) {
                        if (index === 0) {
                          Text('')
                            .width(2)
                            .height(16)
                        }
                        // 状态节点
                        Column() {
                          Text(actionLog.status === 'success' ? '✓' : '✗')
                            .fontSize(14)
                            .fontWeight(FontWeight.Bold)
                            .fontColor('#ffffff')
                            .width(24)
                            .height(24)
                            .borderRadius(12)
                            .backgroundColor(this.getStatusColor(actionLog.status))
                            .textAlign(TextAlign.Center)
                        }
                        .width(24)
                        .height(24)
                        // 连接线
                        if (index < this.actionLogs.length - 1) {
                          Text('')
                            .width(2)
                            .height(32)
                            .backgroundColor('#E5E5E5')
                            .margin({ top: 4 })
                        }
                      }
                      .width(24)
                      .alignItems(HorizontalAlign.Center)

                      // 动作信息
                      Column({ space: 8 }) {
                        Row({ space: 12 }) {
                          // 序号
                          Text(`${index + 1}.`)
                            .fontSize(14)
                            .fontColor('#999999')
                            .fontWeight(FontWeight.Medium)
                            .width(24)

                          // 动作类型
                          Text(this.getActionTypeText(actionLog.actionType))
                            .fontSize(15)
                            .fontWeight(FontWeight.Bold)
                            .fontColor('#333333')
                            .layoutWeight(1)

                          // 状态标签
                          Text(actionLog.status === 'success' ? '成功' : '失败')
                            .fontSize(12)
                            .fontColor(this.getStatusColor(actionLog.status))
                            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                            .backgroundColor(this.getStatusColor(actionLog.status) + '15')
                            .borderRadius(10)
                        }
                        .width('100%')

                        // 时间和耗时
                        Row({ space: 16 }) {
                          Text(`⏱ ${actionLog.duration}ms`)
                            .fontSize(12)
                            .fontColor('#999999')

                          Text(`🕐 ${this.formatShortTime(actionLog.executedAt)}`)
                            .fontSize(12)
                            .fontColor('#999999')
                        }

                        // 错误信息
                        if (actionLog.errorMessage) {
                          Text(actionLog.errorMessage)
                            .fontSize(13)
                            .fontColor('#ff4d4f')
                            .lineHeight(20)
                            .padding(10)
                            .backgroundColor('#FFF1F0')
                            .borderRadius(6)
                            .width('100%')
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      .margin({ left: 16 })

                      // 展开按钮
                      Button(this.shouldShowDetail(actionLog.id) ? '收起' : '详情')
                        .fontSize(12)
                        .fontColor('#007DFF')
                        .backgroundColor(Color.Transparent)
                        .onClick(() => {
                          this.toggleDetails(actionLog.id);
                        })
                    }
                    .width('100%')
                    .padding(16)
                    .onClick(() => {
                      this.toggleDetails(actionLog.id);
                    })

                    // 详细信息（可展开）
                    if (this.shouldShowDetail(actionLog.id)) {
                      Column({ space: 12 }) {
                        // 输入数据
                        Column({ space: 6 }) {
                          Text('输入数据')
                            .fontSize(13)
                            .fontColor('#666666')
                            .fontWeight(FontWeight.Medium)

                          Text(this.formatJsonData(actionLog.inputData))
                            .fontSize(12)
                            .fontColor('#333333')
                            .fontFamily('monospace')
                            .lineHeight(18)
                            .padding(12)
                            .backgroundColor('#F5F7FA')
                            .borderRadius(6)
                            .width('100%')
                            .maxLines(20)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .width('100%')
                        .alignItems(HorizontalAlign.Start)

                        // 输出数据
                        if (actionLog.outputData) {
                          Column({ space: 6 }) {
                            Text('输出数据')
                              .fontSize(13)
                              .fontColor('#666666')
                              .fontWeight(FontWeight.Medium)

                            Text(this.formatJsonData(actionLog.outputData))
                              .fontSize(12)
                              .fontColor('#333333')
                              .fontFamily('monospace')
                              .lineHeight(18)
                              .padding(12)
                              .backgroundColor('#F5F7FA')
                              .borderRadius(6)
                              .width('100%')
                              .maxLines(20)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                          .width('100%')
                          .alignItems(HorizontalAlign.Start)
                        }
                      }
                      .width('100%')
                      .padding(16)
                      .padding({ top: 0 })
                      .backgroundColor('#FAFAFA')
                      .borderRadius(8)
                    }
                  }
                  .width('100%')
                  .backgroundColor('#ffffff')
                  .borderRadius(12)
                  .shadow({
                    radius: 4,
                    color: 'rgba(0, 0, 0, 0.06)',
                    offsetX: 0,
                    offsetY: 1
                  })
                }, (actionLog: ActionExecutionLog) => actionLog.id.toString())
              }
              .width('100%')
            }

            // 底部留白
            Text('')
              .height(16)
          }
          .padding(16)
          .width('100%')
        }
        .flexGrow(1)
        .scrollBar(BarState.Auto)
        .backgroundColor('#F5F7FA')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  /**
   * 信息行组件
   */
  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .width(80)

      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
  }
}
