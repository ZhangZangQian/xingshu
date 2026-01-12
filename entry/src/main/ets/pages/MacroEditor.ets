import router from '@ohos.router';

interface ActionItem {
  id: number;
  type: 'trigger' | 'action' | 'condition' | 'nested';
  title: string;
  icon: string;
  iconColor: string;
  description?: string;
  children?: ActionItem[];
  avatar?: string;
  message?: string;
}

@Entry
@Component
struct MacroEditor {
  @State title: string = 'Morning Routine';
  @State actions: ActionItem[] = [
    {
      id: 1,
      type: 'trigger',
      title: 'At 7:00 AM Daily',
      icon: '\u23F0',
      iconColor: '#FF9500',
      description: 'When'
    },
    {
      id: 2,
      type: 'action',
      title: 'Get Current Weather',
      icon: '\u2600',
      iconColor: '#FF9500',
      description: 'at Current Location'
    },
    {
      id: 3,
      type: 'condition',
      title: 'Scripting',
      icon: '\uD83D\uDEAA',
      iconColor: '#A855F7',
      description: 'If Temperature is greater than 30°C',
        children: [
        {
          id: 4,
          type: 'nested',
          title: 'Send Message',
          icon: '\uD83D\uDCAC',
          iconColor: '#22C55E',
          description: 'To: Mom',
          avatar: 'M',
          message: 'It\'s getting hot in here!'
        }
      ]
    },
    {
      id: 5,
      type: 'action',
      title: 'Play Music',
      icon: '\u266B',
      iconColor: '#EC4899',
      description: 'Playlist: Morning Vibes ☀️'
    }
  ];

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['title']) {
      this.title = params['title'] as string;
    }
  }

  build() {
    Column() {
      this.Header()
      this.Content()
      this.GradientOverlay()
      this.BottomPanel()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F7')
  }

  @Builder
  Header() {
    Row() {
      Button() {
        Row() {
          Text('\u2039')
            .fontSize(20)
            .fontColor('#007AFF')
            .margin({ right: 4 })

          Text('Back')
            .fontSize(16)
            .fontColor('#007AFF')
            .fontWeight(FontWeight.Medium)
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor('transparent')
      .width(80)
      .height(40)
      .borderRadius(999)
      .onClick(() => {
        router.back();
      })

      Column() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')

        Row() {
          Text('')
            .width(6)
            .height(6)
            .borderRadius(999)
            .backgroundColor('#FF9500')
            .margin({ right: 4 })

          Text('Automation')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8E8E93')
            .letterSpacing(0.5)
        }
        .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Center)

      Button() {
        Text('Done')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007AFF')
      }
      .type(ButtonType.Normal)
      .backgroundColor('transparent')
      .width(60)
      .height(40)
      .borderRadius(999)
      .onClick(() => {
        router.back();
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor('rgba(255, 255, 255, 0.8)')
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: '#E5E5EA' })
  }

  @Builder
  Content() {
    Scroll() {
      Column() {
        this.TriggerSection()
        this.ActionsSection()
        this.AddActionButton()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 250 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  TriggerSection() {
    Column() {
      Row() {
        Text('TRIGGER')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#9CA3AF')
          .letterSpacing(0.5)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Column() {
        this.TriggerCard(this.actions[0])
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  ActionsSection() {
    Column() {
      Row() {
        Text('ACTIONS')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#9CA3AF')
          .letterSpacing(0.5)
      }
      .width('100%')
      .margin({ bottom: 8, top: 8 })

      Column({ space: 12 }) {
        ForEach(this.actions.slice(1), (item: ActionItem, index: number) => {
          Stack() {
            if (index < this.actions.slice(1).length - 1) {
              Row()
                .width(2)
                .height(12)
                .backgroundColor('#D1D5DB')
                .position({ x: 36, y: -6 })
                .zIndex(-1)
            }

            this.ActionItemCard(item, index)
          }
          .width('100%')
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ActionItemCard(item: ActionItem, index: number) {
    Column() {
      if (item.type === 'condition') {
        this.ConditionBlock(item, index)
      } else {
        this.ActionCard(item, index)
      }
    }
    .width('100%')
  }

  @Builder
  TriggerCard(item: ActionItem) {
    Stack() {
      Row() {
        Row() {
          Text(item.icon)
            .fontSize(24)
            .fontColor('#FF9500')
        }
        .width(40)
        .height(40)
        .borderRadius(12)
        .backgroundColor('#FFF0D6')
        .justifyContent(FlexAlign.Center)

        Column() {
          Row() {
            Text(item.description || '')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9500')
              .letterSpacing(0.5)

            Blank()

            Text('\u22EE')
              .fontSize(20)
              .fontColor('#D1D5DB')
          }
          .width('100%')

          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
      .border({ width: 2, color: 'rgba(255, 149, 0, 0.3)' })
    }
    .width('100%')
    .borderRadius(12)
  }

  @Builder
  ActionCard(item: ActionItem, index: number) {
    Stack() {
      Row() {
        Stack() {
          Row() {
            Text(item.icon)
              .fontSize(24)
              .fontColor(item.iconColor)
          }
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
          .justifyContent(FlexAlign.Center)

          Row()
            .width(40)
            .height(40)
            .borderRadius(12)
            .backgroundColor(item.iconColor + '1A')
        }
        .width(40)
        .height(40)

        Column() {
          Row() {
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#000000')

            Blank()

            Text('\u2630')
              .fontSize(20)
              .fontColor('#D1D5DB')
          }
          .width('100%')

          if (item.description) {
            Column() {
              if (item.avatar) {
                Row() {
                  Text(item.description.split(':')[0] + ':')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#6B7280')

                  Row() {
                    Text(item.avatar)
                      .fontSize(9)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#166534')

                    Text(item.description.split(': ')[1])
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#166534')
                      .margin({ left: 4 })
                  }
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#F0FDF4')
                  .borderRadius(6)
                  .margin({ left: 8 })
                }
                .margin({ top: 6 })
              } else {
                Text(item.description)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#6B7280')
                  .margin({ top: 6 })
              }

              if (item.message) {
                Row() {
                  Text('\u275D')
                    .fontSize(14)
                    .fontColor('#9CA3AF')
                    .margin({ top: 2 })

                  Text(item.message)
                    .fontSize(12)
                    .fontColor('#374151')
                    .fontStyle(FontStyle.Italic)
                }
                .width('100%')
                .padding(8)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .border({ width: 1, color: '#F3F4F6' })
                .margin({ top: 8 })
              }
            }
            .alignItems(HorizontalAlign.Start)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
      .border({ width: 1, color: '#E5E5EA' })
    }
    .width('100%')
  }

  @Builder
  ConditionBlock(item: ActionItem, index: number) {
    Stack() {
      Column() {
        Row() {
          Stack() {
            Row() {
              Text(item.icon)
                .fontSize(24)
                .fontColor(item.iconColor)
            }
            .width(40)
            .height(40)
            .borderRadius(12)
            .backgroundColor('#FFFFFF')
            .justifyContent(FlexAlign.Center)

            Row()
              .width(40)
              .height(40)
              .borderRadius(12)
              .border({ width: 4, color: '#FFFFFF' })
              .backgroundColor(item.iconColor + '1A')
          }
          .width(40)
          .height(40)

        Column() {
          Row() {
            Text(item.title)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#000000')

            Blank()

            Text('\u2630')
              .fontSize(20)
              .fontColor('#D1D5DB')
          }
          .width('100%')

          if (item.description) {
            Column() {
              if (item.avatar) {
                Row() {
                  Text(item.description.split(':')[0] + ':')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#6B7280')

                  Row() {
                    Text(item.avatar)
                      .fontSize(9)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#166534')

                    Text(item.description.split(': ')[1])
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#166534')
                      .margin({ left: 4 })
                  }
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#F0FDF4')
                  .borderRadius(6)
                  .margin({ left: 8 })
                }
                .margin({ top: 6 })
              } else {
                Text(item.description)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#6B7280')
                  .margin({ top: 6 })
              }

              if (item.message) {
                Row() {
                  Text('\u275D')
                    .fontSize(14)
                    .fontColor('#9CA3AF')
                    .margin({ top: 2 })

                  Text(item.message)
                    .fontSize(12)
                    .fontColor('#374151')
                    .fontStyle(FontStyle.Italic)
                }
                .width('100%')
                .padding(8)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .border({ width: 1, color: '#F3F4F6' })
                .margin({ top: 8 })
              }
            }
            .alignItems(HorizontalAlign.Start)
          }
        }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
        .border({ width: 1, color: '#E5E5EA' })

      if (item.children && item.children.length > 0) {
        Column({ space: 12 }) {
          ForEach(item.children, (child: ActionItem) => {
            this.NestedActionCard(child)
          })

          this.EndIfCard()
        }
        .width('100%')
        .margin({ top: 12 })
      }
      }
    }
    .width('100%')
  }

  @Builder
  NestedActionCard(item: ActionItem) {
    Stack() {
      Row() {
        Stack() {
          Row() {
            Text(item.icon)
              .fontSize(24)
              .fontColor(item.iconColor)
          }
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor('#FFFFFF')
          .justifyContent(FlexAlign.Center)

          Row()
            .width(40)
            .height(40)
            .borderRadius(12)
            .backgroundColor(item.iconColor + '1A')
        }
        .width(40)
        .height(40)

        Column() {
          Row() {
              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#000000')

            Blank()

            Text('\u2630')
              .fontSize(20)
              .fontColor('#D1D5DB')
          }
          .width('100%')

          if (item.description) {
            Column() {
              if (item.avatar) {
                Row() {
                  Text(item.description.split(':')[0] + ':')
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#6B7280')

                  Row() {
                    Text(item.avatar)
                      .fontSize(9)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#166534')

                    Text(item.description.split(': ')[1])
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#166534')
                      .margin({ left: 4 })
                  }
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#F0FDF4')
                  .borderRadius(6)
                  .margin({ left: 8 })
                }
                .margin({ top: 6 })
              } else {
                Text(item.description)
                  .fontSize(12)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#6B7280')
                  .margin({ top: 6 })
              }

              if (item.message) {
                Row() {
                  Text('\u275D')
                    .fontSize(14)
                    .fontColor('#9CA3AF')
                    .margin({ top: 2 })

                  Text(item.message)
                    .fontSize(12)
                    .fontColor('#374151')
                    .fontStyle(FontStyle.Italic)
                }
                .width('100%')
                .padding(8)
                .backgroundColor('#F9FAFB')
                .borderRadius(8)
                .border({ width: 1, color: '#F3F4F6' })
                .margin({ top: 8 })
              }
            }
            .alignItems(HorizontalAlign.Start)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
      .border({ width: 1, color: '#E5E5EA' })
    }
    .width('100%')
  }

  @Builder
  EndIfCard() {
    Stack() {
      Row() {
        Row()
          .width(32)
          .height(32)
          .borderRadius(12)
          .backgroundColor('#F3F4F6')
          .justifyContent(FlexAlign.Center)
          .margin({ left: 4 })

        Column() {
          Text('End If')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#9CA3AF')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('rgba(255, 255, 255, 0.6)')
      .borderRadius(12)
      .border({ width: 1, color: 'rgba(229, 229, 234, 0.6)' })
    }
    .width('100%')
  }

  @Builder
  AddActionButton() {
    Row() {
      Text('+')
        .fontSize(20)
        .fontColor('#9CA3AF')

      Text('Add Action')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4B5563')
        .margin({ left: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .borderRadius(999)
    .border({ width: 1, color: '#D1D5DB' })
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
    .margin({ top: 12, bottom: 12 })
  }

  @Builder
  GradientOverlay() {
    Row()
      .width('100%')
      .height(192)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [['#F2F2F7', 0.0], ['#F2F2F7', 1.0]]
      })
      .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
      .hitTestBehavior(HitTestMode.None)
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })
  }

  @Builder
  BottomPanel() {
    Column() {
      Row() {
        Text('1 Trigger \u2022 4 Actions')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#6B7280')
          .letterSpacing(0.5)

        Blank()

        Row() {
          Button() {
            Text('\u21A9')
              .fontSize(20)
              .fontColor('#9CA3AF')
          }
          .type(ButtonType.Normal)
          .backgroundColor('transparent')
          .width(36)
          .height(36)
          .borderRadius(999)

          Button() {
            Text('\u21AA')
              .fontSize(20)
              .fontColor('#9CA3AF')
          }
          .type(ButtonType.Normal)
          .backgroundColor('transparent')
          .width(36)
          .height(36)
          .borderRadius(999)
        }

        Button() {
          Text('\u25B6')
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .type(ButtonType.Normal)
        .backgroundColor('#007AFF')
        .borderRadius(999)
        .width(44)
        .height(44)
        .shadow({
          radius: 14,
          color: 'rgba(0, 122, 255, 0.3)',
          offsetY: 4
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })

      Row()
        .width(48)
        .height(6)
        .backgroundColor('#E5E5EA')
        .borderRadius(999)
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 20, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius({ topLeft: 32, topRight: 32 })
    .shadow({ radius: 40, color: 'rgba(0, 0, 0, 0.08)', offsetY: -10 })
    .border({ width: { top: 1 }, color: '#F3F4F6' })
    .position({ x: 0, y: '100%' })
    .translate({ y: '-100%' })
  }
}
