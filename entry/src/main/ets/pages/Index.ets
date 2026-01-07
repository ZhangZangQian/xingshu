import { Macro } from '../models/Macro';
import { DatabaseService } from '../services/DatabaseService';
import { MacroEngine } from '../services/MacroEngine';
import { MacroCard } from '../components/MacroCard';
import Logger from '../utils/Logger';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

/**
 * 宏列表页
 */
@Entry
@Component
struct Index {
  @State macros: Macro[] = [];
  @State loading: boolean = true;
  private databaseService: DatabaseService = DatabaseService.getInstance();
  private macroEngine: MacroEngine = MacroEngine.getInstance();

  async aboutToAppear() {
    await this.loadMacros();
  }

  /**
   * 加载宏列表
   */
  private async loadMacros() {
    try {
      this.loading = true;
      this.macros = await this.databaseService.getAllMacros();
      Logger.info('Index', `Loaded ${this.macros.length} macros`);
    } catch (error) {
      Logger.error('Index', 'Failed to load macros', error as Error);
      promptAction.showToast({ message: '加载宏列表失败' });
    } finally {
      this.loading = false;
    }
  }

  /**
   * 切换宏启用状态
   */
  private async handleToggleMacro(id: number, enabled: boolean) {
    try {
      if (enabled) {
        await this.macroEngine.enableMacro(id);
        promptAction.showToast({ message: '宏已启用' });
      } else {
        await this.macroEngine.disableMacro(id);
        promptAction.showToast({ message: '宏已禁用' });
      }
      await this.loadMacros();
    } catch (error) {
      Logger.error('Index', 'Failed to toggle macro', error as Error);
      promptAction.showToast({ message: '操作失败' });
    }
  }

  /**
   * 手动触发宏
   */
  private async handleTriggerMacro(id: number) {
    try {
      promptAction.showToast({ message: '开始执行宏...' });
      const success = await this.macroEngine.manualTrigger(id);
      if (success) {
        promptAction.showToast({ message: '宏执行成功' });
      } else {
        promptAction.showToast({ message: '宏执行失败，请查看日志' });
      }
    } catch (error) {
      Logger.error('Index', 'Failed to trigger macro', error as Error);
      promptAction.showToast({ message: '触发宏失败' });
    }
  }

  /**
   * 编辑宏
   */
  private handleEditMacro(id: number) {
    router.pushUrl({
      url: 'pages/MacroEditor',
      params: { macroId: id }
    });
  }

  /**
   * 删除宏
   */
  private async handleDeleteMacro(id: number) {
    try {
      await promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这个宏吗？',
        buttons: [
          { text: '取消', color: '#000000' },
          { text: '删除', color: '#ff4d4f' }
        ]
      }).then(async (result) => {
        if (result.index === 1) {
          await this.databaseService.deleteMacro(id);
          promptAction.showToast({ message: '宏已删除' });
          await this.loadMacros();
        }
      });
    } catch (error) {
      Logger.error('Index', 'Failed to delete macro', error as Error);
      promptAction.showToast({ message: '删除失败' });
    }
  }

  /**
   * 添加新宏
   */
  private handleAddMacro() {
    router.pushUrl({
      url: 'pages/MacroEditor'
    });
  }

  /**
   * 跳转到执行日志页
   */
  private handleNavigateToLog() {
    router.pushUrl({
      url: 'pages/ExecutionLog'
    });
  }

  /**
   * 跳转到全局变量管理页
   */
  private handleNavigateToGlobalVariables() {
    router.pushUrl({
      url: 'pages/GlobalVariables'
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 主内容区
      Column() {
        // 顶部标题栏
        Row() {
          Text('鸿蒙宏')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .flexGrow(1)

          Button('全局变量')
            .fontSize(14)
            .height(36)
            .margin({ right: 8 })
            .onClick(() => {
              this.handleNavigateToGlobalVariables();
            })

          Button('执行日志')
            .fontSize(14)
            .height(36)
            .onClick(() => {
              this.handleNavigateToLog();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
        .backgroundColor('#ffffff')

        // 宏列表
        if (this.loading) {
          Column() {
            Text('加载中...')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .flexGrow(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.macros.length === 0) {
          Column() {
            Text('暂无宏')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ bottom: 8 })

            Text('点击右下角按钮添加')
              .fontSize(14)
              .fontColor('#cccccc')
          }
          .width('100%')
          .flexGrow(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: 0 }) {
              ForEach(this.macros, (macro: Macro) => {
                MacroCard({
                  macro: macro,
                  onToggle: (id: number, enabled: boolean) => {
                    this.handleToggleMacro(id, enabled);
                  },
                  onTrigger: (id: number) => {
                    this.handleTriggerMacro(id);
                  },
                  onEdit: (id: number) => {
                    this.handleEditMacro(id);
                  },
                  onDelete: (id: number) => {
                    this.handleDeleteMacro(id);
                  }
                })
              }, (macro: Macro) => macro.id.toString())
            }
            .padding({ left: 16, right: 16, top: 16, bottom: 88 })
            .width('100%')
          }
          .flexGrow(1)
          .scrollBar(BarState.Auto)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')

      // 悬浮添加按钮
      Button('+')
        .fontSize(32)
        .width(56)
        .height(56)
        .borderRadius(28)
        .margin({ right: 16, bottom: 16 })
        .onClick(() => {
          this.handleAddMacro();
        })
    }
    .width('100%')
    .height('100%')
  }
}
