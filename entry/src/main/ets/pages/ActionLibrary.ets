import router from '@ohos.router';

interface FeaturedWorkflow {
  title: string;
  description: string;
  icon: string;
  iconColor: string;
  tag: string;
  gradientColor: string;
}

interface CategoryItem {
  title: string;
  icon: string;
  iconColor: string;
}

interface SuggestedAction {
  id: number;
  title: string;
  description: string;
  icon: string;
  iconColor: string;
}

@Entry
@Component
struct ActionLibrary {
  @State searchValue: string = '';
  @State featuredWorkflows: FeaturedWorkflow[] = [
    {
      title: 'Morning Briefing',
      description: 'Daily digest, weather, and calendar events spoken aloud.',
      icon: '\u2600',
      iconColor: '#F97316',
      tag: 'v2.4',
      gradientColor: 'linear-gradient(135deg, rgba(249, 115, 22, 0.2), rgba(42, 47, 55, 1))'
    },
    {
      title: 'Auto-Log Expenses',
      description: 'Scan receipts and append to Sheets instantly.',
      icon: '\u{1F4B8}',
      iconColor: '#607AFB',
      tag: 'Auto',
      gradientColor: 'linear-gradient(135deg, rgba(96, 122, 251, 0.2), rgba(42, 47, 55, 1))'
    },
    {
      title: 'ETA Sharer',
      description: 'Calculate drive time and text contacts your arrival.',
      icon: '\u{1F4CD}',
      iconColor: '#A855F7',
      tag: 'GPS',
      gradientColor: 'linear-gradient(135deg, rgba(168, 85, 247, 0.2), rgba(42, 47, 55, 1))'
    }
  ];

  @State categories: CategoryItem[] = [
    { title: 'Apps', icon: '\u{1F4F1}', iconColor: '#3B82F6' },
    { title: 'Scripting', icon: '\u{1F4BB}', iconColor: '#A855F7' },
    { title: 'Media', icon: '\u{1F3A5}', iconColor: '#F97316' },
    { title: 'Location', icon: '\u{1F4E0}', iconColor: '#EF4444' }
  ];

  @State suggestedActions: SuggestedAction[] = [
    {
      id: 1,
      title: 'Get Current Weather',
      description: 'Returns weather at current location',
      icon: '\u26C5',
      iconColor: '#F59E0B'
    },
    {
      id: 2,
      title: 'Resize Image',
      description: 'Scale image to specific dimension',
      icon: '\u{1F6B5}',
      iconColor: '#EC4899'
    },
    {
      id: 3,
      title: 'Run JavaScript',
      description: 'Execute code snippet on webpage',
      icon: '\u{1F4BB}',
      iconColor: '#06B6D4'
    },
    {
      id: 4,
      title: 'Quick Share',
      description: 'Share clipboard to recent contacts',
      icon: '\u{1F447}',
      iconColor: '#22C55E'
    }
  ];

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column({ space: 32 }) {
          this.SearchBar()
          this.FeaturedWorkflows()
          this.Categories()
          this.SuggestedActions()
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 24, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  @Builder
  Header() {
    Row() {
      Text('Action ')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .fontFamily('sans-serif')

      Text('Library')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#607AFB')
        .fontFamily('sans-serif')

      Blank()

      Button() {
        Text('\u2715')
          .fontSize(20)
          .fontColor('#6B7280')
      }
      .type(ButtonType.Normal)
      .backgroundColor('rgba(0, 0, 0, 0.05)')
      .width(36)
      .height(36)
      .borderRadius(999)
      .onClick(() => {
        router.back();
      })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 48, bottom: 16 })
    .backgroundColor('rgba(245, 246, 248, 0.9)')
    .backdropBlur(20)
    .border({ width: { bottom: 1 }, color: 'rgba(0, 0, 0, 0.05)' })
  }

  @Builder
  SearchBar() {
    Stack({ alignContent: Alignment.Center }) {
      Row() {
        Text('\u{1F539}')
          .fontSize(20)
          .fontColor('#9CA3AF')
          .margin({ left: 12, right: 12 })

        TextInput({ placeholder: '> Find actions, apps, or scripts...', text: this.searchValue })
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F4F6')
          .borderRadius(12)
          .onChange((value: string) => {
            this.searchValue = value;
          })
      }
      .width('100%')
      .padding({ left: 4, right: 4 })
      .backgroundColor('#F3F4F6')
      .borderRadius(12)
      .border({ width: 1, color: 'rgba(0, 0, 0, 0.1)' })
      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
    }
    .width('100%')
  }

  @Builder
  FeaturedWorkflows() {
    Column({ space: 16 }) {
      Row() {
        Text('Featured Workflows')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')

        Blank()

        Text('View all')
          .fontSize(14)
          .fontColor('#607AFB')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')

      Scroll() {
        Row({ space: 16 }) {
          ForEach(this.featuredWorkflows, (item: FeaturedWorkflow) => {
            this.FeaturedCard(item)
          })
        }
        .width('100%')
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
    }
    .width('100%')
  }

  @Builder
  FeaturedCard(item: FeaturedWorkflow) {
    Stack({ alignContent: Alignment.BottomStart }) {
      Column()
        .width(320)
        .height(192)
        .borderRadius(16)
        .linearGradient({
          angle: 135,
          colors: [[item.iconColor + '33', 0.0], ['#2A2F37', 1.0]]
        })
        .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.1)', offsetY: 4 })
        .border({ width: 1, color: 'rgba(255, 255, 255, 0.1)' })

      Column({ space: 12 }) {
        Row() {
          Row() {
            Text(item.icon)
              .fontSize(24)
              .fontColor(item.iconColor)
          }
          .width(40)
          .height(40)
          .borderRadius(12)
          .backgroundColor(item.iconColor + '33')
          .border({ width: 1, color: item.iconColor + '4D' })
          .justifyContent(FlexAlign.Center)

          Blank()

          Text(item.tag)
            .fontSize(12)
            .fontColor('rgba(255, 255, 255, 0.7)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('rgba(0, 0, 0, 0.4)')
            .borderRadius(6)
            .border({ width: 1, color: 'rgba(255, 255, 255, 0.1)' })
            .fontFamily('monospace')
        }
        .width('100%')

        Column({ space: 4 }) {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')

          Text(item.description)
            .fontSize(14)
            .fontColor('#9CA3AF')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(24)
    }
    .width(320)
    .height(192)
    .borderRadius(16)
    .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.1)', offsetY: 4 })
    .onClick(() => {
      console.log('Featured workflow clicked:', item.title);
    })
  }

  @Builder
  Categories() {
    Column({ space: 16 }) {
      Text('Categories')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')

      Grid() {
        ForEach(this.categories, (item: CategoryItem) => {
          GridItem() {
            Column({ space: 12 }) {
              Row() {
                Text(item.icon)
                  .fontSize(24)
                  .fontColor(item.iconColor)
              }
              .width(48)
              .height(48)
              .borderRadius(999)
              .backgroundColor(item.iconColor + '1A')
              .justifyContent(FlexAlign.Center)

              Text(item.title)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#374151')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
            .border({ width: 1, color: 'rgba(0, 0, 0, 0.05)' })
          }
          .aspectRatio(1)
          .onClick(() => {
            console.log('Category clicked:', item.title);
          })
        })
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  SuggestedActions() {
    Column({ space: 16 }) {
      Text('Suggested Actions')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')

      Column({ space: 12 }) {
        ForEach(this.suggestedActions, (item: SuggestedAction) => {
          this.SuggestedActionCard(item)
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  SuggestedActionCard(item: SuggestedAction) {
    Row() {
      Row() {
        Text(item.icon)
          .fontSize(24)
          .fontColor(item.iconColor)
      }
      .width(40)
      .height(40)
      .borderRadius(12)
      .backgroundColor(item.iconColor + '1A')
      .border({ width: 1, color: item.iconColor + '33' })
      .justifyContent(FlexAlign.Center)

      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')

        Text(item.description)
          .fontSize(12)
          .fontColor('#6B7280')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 16 })

      Button() {
        Text('+')
          .fontSize(20)
          .fontColor('#607AFB')
      }
      .type(ButtonType.Normal)
      .backgroundColor('#F3F4F6')
      .width(32)
      .height(32)
      .borderRadius(999)
      .onClick(() => {
        console.log('Add action clicked:', item.title);
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.04)', offsetY: 2 })
    .border({ width: 1, color: 'rgba(0, 0, 0, 0.05)' })
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      console.log('Action card clicked:', item.title);
    })
  }
}
