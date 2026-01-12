import { Macro, Folder } from '../models/Macro';
import { DatabaseService } from '../services/DatabaseService';
import { MacroEngine } from '../services/MacroEngine';
import { MacroCard } from '../components/MacroCard';
import { FABButton } from '../components/FABButton';
import { EmptyState } from '../components/EmptyState';
import { SingleSelectDialog } from '../components/SingleSelectDialog';
import { MultiSelectDialog } from '../components/MultiSelectDialog';
import { TextInputDialog } from '../components/TextInputDialog';
import { FolderInputDialog } from '../components/FolderInputDialog';
import { DialogEventBus } from '../services/actions/UserDialogAction';
import { UserDialogConfig } from '../models/Macro';
import { BUILTIN_FOLDERS } from '../constants/FolderConstants';
import Logger from '../utils/Logger';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';

interface FolderInfo {
  name: string;
  isManaged: boolean;
}

@Component
export struct MacrosTab {
  @State macros: Macro[] = [];
  @State folders: Folder[] = [];
  @State folderMacroCounts: Map<number, number> = new Map();
  @State loading: boolean = true;
  @State viewMode: 'grid' | 'list' = 'grid';
  @State showMenu: boolean = false;
  @State menuTargetMacroId: number = 0;
  @State currentFolderId: number | null = null;

  private databaseService: DatabaseService = DatabaseService.getInstance();
  private macroEngine: MacroEngine = MacroEngine.getInstance();
  private singleSelectDialogController: CustomDialogController | null = null;
  private multiSelectDialogController: CustomDialogController | null = null;
  private textInputDialogController: CustomDialogController | null = null;
  private folderInputDialogController: CustomDialogController | null = null;
  private dialogEventBus: DialogEventBus = DialogEventBus.getInstance();

  async aboutToAppear() {
    await this.loadFolders();
    await this.loadMacros();
    this.registerDialogHandlers();
  }

  onPageShow() {
    this.loadFolders();
    this.loadMacros();
  }

  private async loadFolders() {
    try {
      this.folders = await this.databaseService.getAllFolders();
      this.folderMacroCounts = await this.databaseService.getAllFoldersMacroCount();
      Logger.info('MacrosTab', `Loaded ${this.folders.length} folders`);
    } catch (error) {
      Logger.error('MacrosTab', 'Failed to load folders', error as Error);
    }
  }

  private registerDialogHandlers() {
    this.dialogEventBus.registerSingleSelectHandler(async (config: UserDialogConfig) => {
      return new Promise((resolve) => {
        this.singleSelectDialogController = new CustomDialogController({
          builder: SingleSelectDialog({
            title: config.title,
            options: config.options || [],
            onConfirm: (selected: string, index: number) => {
              resolve({ value: selected, index: index });
            }
          }),
          customStyle: true
        });
        this.singleSelectDialogController.open();
      });
    });

    this.dialogEventBus.registerMultiSelectHandler(async (config: UserDialogConfig) => {
      return new Promise((resolve) => {
        this.multiSelectDialogController = new CustomDialogController({
          builder: MultiSelectDialog({
            title: config.title,
            options: config.options || [],
            onConfirm: (selected: string[]) => {
              resolve(selected);
            }
          }),
          customStyle: true
        });
        this.multiSelectDialogController.open();
      });
    });

    this.dialogEventBus.registerTextInputHandler(async (config: UserDialogConfig) => {
      return new Promise((resolve) => {
        this.textInputDialogController = new CustomDialogController({
          builder: TextInputDialog({
            title: config.title,
            message: config.message,
            placeholder: config.placeholder,
            defaultValue: config.defaultValue,
            onConfirm: (text: string) => {
              resolve(text);
            }
          }),
          customStyle: true
        });
        this.textInputDialogController.open();
      });
    });

    Logger.info('MacrosTab', 'Dialog handlers registered');
  }

  private async loadMacros() {
    try {
      this.loading = true;
      this.macros = await this.databaseService.getAllMacros();
      Logger.info('MacrosTab', `Loaded ${this.macros.length} macros`);
    } catch (error) {
      Logger.error('MacrosTab', 'Failed to load macros', error as Error);
      promptAction.showToast({ message: '加载宏列表失败' });
    } finally {
      this.loading = false;
    }
  }

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
      Logger.error('MacrosTab', 'Failed to toggle macro', error as Error);
      promptAction.showToast({ message: '操作失败' });
    }
  }

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
      Logger.error('MacrosTab', 'Failed to trigger macro', error as Error);
      promptAction.showToast({ message: '触发宏失败' });
    }
  }

  private handleEditMacro(id: number) {
    router.pushUrl({
      url: 'pages/MacroEditor',
      params: { macroId: id }
    });
  }

  private handleMoreMacro(id: number) {
    this.menuTargetMacroId = id;
    this.showMenu = true;
  }

  private async handleDeleteMacro(id: number) {
    try {
      await promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这个宏吗？',
        buttons: [
          { text: '取消', color: '#000000' },
          { text: '删除', color: '#FF3B30' }
        ]
      }).then(async (result) => {
        if (result.index === 1) {
          await this.databaseService.deleteMacro(id);
          promptAction.showToast({ message: '宏已删除' });
          await this.loadMacros();
        }
      });
    } catch (error) {
      Logger.error('MacrosTab', 'Failed to delete macro', error as Error);
      promptAction.showToast({ message: '删除失败' });
    }
  }

  private handleAddMacro() {
    router.pushUrl({
      url: 'pages/MacroEditor'
    });
  }

  private handleNavigateToLog() {
    router.pushUrl({
      url: 'pages/ExecutionLog'
    });
  }

  private handleNavigateToGlobalVariables() {
    router.pushUrl({
      url: 'pages/GlobalVariables'
    });
  }

  private handleFolderSelect(folderId: number) {
    this.currentFolderId = folderId;
  }

  private handleBackToFolderList() {
    this.currentFolderId = null;
  }

  private getCurrentFolderInfo(): FolderInfo {
    if (this.currentFolderId === BUILTIN_FOLDERS.ALL_MACROS.id) {
      const info: FolderInfo = { name: BUILTIN_FOLDERS.ALL_MACROS.name, isManaged: false };
      return info;
    }
    if (this.currentFolderId === BUILTIN_FOLDERS.UNASSIGNED.id) {
      const info: FolderInfo = { name: BUILTIN_FOLDERS.UNASSIGNED.name, isManaged: false };
      return info;
    }
    const folder = this.folders.find(f => f.id === this.currentFolderId);
    if (folder) {
      const info: FolderInfo = { name: folder.name, isManaged: true };
      return info;
    }
    const info: FolderInfo = { name: '未知文件夹', isManaged: false };
    return info;
  }

  private handleCreateFolder() {
    this.folderInputDialogController = new CustomDialogController({
      builder: FolderInputDialog({
        title: '新建文件夹',
        defaultName: '',
        defaultIcon: 'folder',
        onConfirm: (name: string, icon: string) => {
          this.onCreateFolder(name, icon);
        },
        onCancel: () => {
          this.folderInputDialogController = null;
        }
      }),
      customStyle: true
    });
    this.folderInputDialogController.open();
  }

  private async onCreateFolder(name: string, icon: string) {
    try {
      await this.databaseService.insertFolder({
        name: name,
        icon: icon,
        createdAt: Date.now(),
        updatedAt: Date.now()
      });
      promptAction.showToast({ message: '文件夹创建成功' });
      await this.loadFolders();
      this.folderInputDialogController = null;
    } catch (error) {
      Logger.error('MacrosTab', 'Failed to create folder', error as Error);
      promptAction.showToast({ message: '创建文件夹失败' });
    }
  }

  private handleManageFolder() {
    promptAction.showToast({ message: '点击文件夹项可展开管理' });
  }

  private async handleRenameFolder() {
    if (!this.currentFolderId || this.currentFolderId === BUILTIN_FOLDERS.ALL_MACROS.id || this.currentFolderId === BUILTIN_FOLDERS.UNASSIGNED.id) {
      promptAction.showToast({ message: '请先进入一个可管理的文件夹' });
      return;
    }

    const folder = this.folders.find(f => f.id === this.currentFolderId);
    if (!folder) return;

    this.folderInputDialogController = new CustomDialogController({
      builder: FolderInputDialog({
        title: '重命名文件夹',
        defaultName: folder.name,
        defaultIcon: folder.icon || 'folder',
        onConfirm: (name: string, icon: string) => {
          this.onUpdateFolder(folder.id, name, icon);
        },
        onCancel: () => {
          this.folderInputDialogController = null;
        }
      }),
      customStyle: true
    });
    this.folderInputDialogController.open();
  }

  private async onUpdateFolder(id: number, name: string, icon: string) {
    try {
      await this.databaseService.updateFolder(id, {
        name: name,
        icon: icon,
        updatedAt: Date.now()
      });
      promptAction.showToast({ message: '文件夹更新成功' });
      await this.loadFolders();
      this.folderInputDialogController = null;
    } catch (error) {
      Logger.error('MacrosTab', 'Failed to update folder', error as Error);
      promptAction.showToast({ message: '更新文件夹失败' });
    }
  }

  private async handleDeleteFolder() {
    if (!this.currentFolderId || this.currentFolderId === BUILTIN_FOLDERS.ALL_MACROS.id || this.currentFolderId === BUILTIN_FOLDERS.UNASSIGNED.id) {
      promptAction.showToast({ message: '请先进入一个可管理的文件夹' });
      return;
    }

    const folder = this.folders.find(f => f.id === this.currentFolderId);
    if (!folder) return;

    try {
      await promptAction.showDialog({
        title: '确认删除',
        message: `确定要删除文件夹"${folder.name}"吗？文件夹内的宏将被移动到未分类。`,
        buttons: [
          { text: '取消', color: '#000000' },
          { text: '删除', color: '#FF3B30' }
        ]
      }).then(async (result) => {
        if (result.index === 1) {
          await this.databaseService.deleteFolder(folder.id);
          promptAction.showToast({ message: '文件夹已删除' });
          this.currentFolderId = null;
          await this.loadFolders();
          await this.loadMacros();
        }
      });
    } catch (error) {
      Logger.error('MacrosTab', 'Failed to delete folder', error as Error);
      promptAction.showToast({ message: '删除文件夹失败' });
    }
  }

  @Builder
  FolderItem(folderId: number, folderName: string, iconSymbol: string, count: number) {
    Button() {
      Row({ space: 12 }) {
        SymbolGlyph($r(iconSymbol))
          .fontSize(20)
          .fontColor(['#007DFF'])

        Text(folderName)
          .fontSize(16)
          .fontColor('#1A1A1A')
          .flexGrow(1)

        Text(`${count}`)
          .fontSize(14)
          .fontColor('#AEAEB2')
          .margin({ right: 4 })

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontColor(['#C7C7CC'])
      }
      .width('100%')
      .padding({ left: 16, right: 12, top: 10, bottom: 10 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.handleFolderSelect(folderId);
    })
  }

  @Builder
  FolderContentView(folderId: number, folderName: string, isManagedFolder: boolean) {
    Column({ space: 0 }) {
      Row({ space: 8 }) {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(20)
            .fontColor(['#007DFF'])
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.handleBackToFolderList();
        })

        Text(folderName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
          .flexGrow(1)

        if (isManagedFolder) {
          Row({ space: 12 }) {
            Button('重命名')
              .fontSize(15)
              .height(36)
              .onClick(() => {
                this.handleRenameFolder();
              })

            Button('删除')
              .fontSize(15)
              .height(36)
              .backgroundColor('#FFE5E5')
              .fontColor('#FF3B30')
              .onClick(() => {
                this.handleDeleteFolder();
              })
          }
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })
      .backgroundColor('#FFFFFF')

      if (this.viewMode === 'grid') {
        Grid() {
          ForEach(this.macros.filter(m => {
            if (folderId === BUILTIN_FOLDERS.ALL_MACROS.id) return true;
            if (folderId === BUILTIN_FOLDERS.UNASSIGNED.id) return m.folderId === null;
            return m.folderId === folderId;
          }), (macro: Macro) => {
            GridItem() {
              MacroCard({
                macro: macro,
                viewMode: this.viewMode,
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
                },
                onMore: (id: number) => {
                  this.handleMoreMacro(id);
                }
              })
            }
          }, (macro: Macro) => macro.id.toString())
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .padding(16)
        .width('100%')
      } else {
        Column({ space: 10 }) {
          ForEach(this.macros.filter(m => {
            if (folderId === BUILTIN_FOLDERS.ALL_MACROS.id) return true;
            if (folderId === BUILTIN_FOLDERS.UNASSIGNED.id) return m.folderId === null;
            return m.folderId === folderId;
          }), (macro: Macro) => {
            MacroCard({
              macro: macro,
              viewMode: this.viewMode,
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
              },
              onMore: (id: number) => {
                this.handleMoreMacro(id);
              }
            })
          }, (macro: Macro) => macro.id.toString())
        }
        .padding(16)
        .width('100%')
      }
    }
    .width('100%')
  }

  @Builder
  MenuPanel() {
    Column() {
      Button('重命名文件夹')
        .width('100%')
        .height(48)
        .backgroundColor(Color.Transparent)
        .fontColor('#1A1A1A')
        .onClick(() => {
          this.handleRenameFolder();
          this.showMenu = false;
        })

      Divider()
        .color('#E5E5EA')

      Button('删除文件夹')
        .width('100%')
        .height(48)
        .backgroundColor(Color.Transparent)
        .fontColor('#FF3B30')
        .onClick(() => {
          this.handleDeleteFolder();
          this.showMenu = false;
        })

      Divider()
        .color('#E5E5EA')

      Button('取消')
        .width('100%')
        .height(48)
        .backgroundColor(Color.Transparent)
        .fontColor('#007DFF')
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.showMenu = false;
        })
    }
    .width(280)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 24,
      color: '#30000000',
      offsetX: 0,
      offsetY: 8
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      if (this.currentFolderId === null) {
        Column() {
          Row() {
            Text('我的宏')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A1A')
              .flexGrow(1)

            Button('全局变量')
              .fontSize(15)
              .height(36)
              .margin({ right: 8 })
              .onClick(() => {
                this.handleNavigateToGlobalVariables();
              })

            Button('执行日志')
              .fontSize(15)
              .height(36)
              .onClick(() => {
                this.handleNavigateToLog();
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })
          .backgroundColor('#FFFFFF')

          if (this.loading) {
            Column() {
              Text('加载中...')
                .fontSize(16)
                .fontColor('#AEAEB2')
            }
            .width('100%')
            .flexGrow(1)
            .justifyContent(FlexAlign.Center)
          } else {
            Scroll() {
              Column({ space: 0 }) {
                this.FolderItem(BUILTIN_FOLDERS.ALL_MACROS.id, BUILTIN_FOLDERS.ALL_MACROS.name,
                  `sys.symbol.${BUILTIN_FOLDERS.ALL_MACROS.icon}`, this.folderMacroCounts.get(BUILTIN_FOLDERS.ALL_MACROS.id) || 0)

                Divider()
                  .color('#E5E5EA')
                  .padding({ left: 16 })

                this.FolderItem(BUILTIN_FOLDERS.UNASSIGNED.id, BUILTIN_FOLDERS.UNASSIGNED.name,
                  'sys.symbol.folder', this.folderMacroCounts.get(BUILTIN_FOLDERS.UNASSIGNED.id) || 0)

                if (this.folders.length > 0) {
                  Divider()
                    .color('#E5E5EA')
                    .margin({ top: 8, bottom: 8 })

                  Row() {
                    Text('文件夹')
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#8E8E93')
                      .flexGrow(1)

                    Button() {
                      SymbolGlyph($r('sys.symbol.plus'))
                        .fontSize(16)
                        .fontColor(['#007DFF'])
                    }
                    .width(28)
                    .height(28)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => {
                      this.handleCreateFolder();
                    })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })

                  ForEach(this.folders, (folder: Folder) => {
                    Column() {
                      Divider()
                        .color('#E5E5EA')
                        .padding({ left: 16 })

                      this.FolderItem(folder.id, folder.name, `sys.symbol.${folder.icon || 'folder'}`,
                        this.folderMacroCounts.get(folder.id) || 0)
                    }
                    .width('100%')
                  }, (folder: Folder) => folder.id.toString())
                }

                Divider()
                  .color('#E5E5EA')
                  .margin({ top: 8, bottom: 8 })

                Row() {
                  Button() {
                    Row({ space: 8 }) {
                      SymbolGlyph($r('sys.symbol.gearshape'))
                        .fontSize(16)
                        .fontColor(['#007DFF'])
                      Text('管理文件夹')
                        .fontSize(15)
                        .fontColor('#007DFF')
                    }
                  }
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.showMenu = true;
                  })
                }
                .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
            .flexGrow(1)
            .scrollBar(BarState.Auto)
            .align(Alignment.TopStart)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
      } else {
        Column() {
          Scroll() {
            this.FolderContentView(this.currentFolderId, this.getCurrentFolderInfo().name, this.getCurrentFolderInfo().isManaged)
          }
          .flexGrow(1)
          .scrollBar(BarState.Auto)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#FFFFFF')
      }

      FABButton({
        onTap: () => {
          this.handleAddMacro();
        }
      })

      if (this.showMenu) {
        Column() {
          this.MenuPanel()
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showMenu = false;
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
