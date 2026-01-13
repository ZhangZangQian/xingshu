import { PageHeader, SearchBar } from '../components/CommonComponents';

interface GalleryItem {
  id: number;
  name: string;
  description: string;
  iconSymbol: string;
  gradient: string[];
}

interface Category {
  id: number;
  name: string;
  items: GalleryItem[];
}

@Entry
@Component
export struct GalleryPage {
  @State searchText: string = '';
  @State categories: Category[] = [
    {
      id: 1,
      name: 'Essential Shortcuts',
      items: [
        { id: 1, name: 'Directions Home', description: 'Get ETA and start navigation home.', iconSymbol: '\u2302', gradient: ['#60A5FA', '#2563EB'] },
        { id: 2, name: 'Laundry Timer', description: 'Set a timer for your laundry cycle.', iconSymbol: '\u23F2', gradient: ['#FB923C', '#EF4444'] },
        { id: 3, name: 'Scan QR', description: 'Quickly scan any QR code.', iconSymbol: '\u2913', gradient: ['#4ADE80', '#059669'] }
      ]
    },
    {
      id: 2,
      name: 'Work from Home',
      items: [
        { id: 4, name: 'Zoom Meeting', description: 'Join your next calendar event.', iconSymbol: '\u23F5', gradient: ['#A855F7', '#C026D3'] },
        { id: 5, name: 'Focus Mode', description: 'Enable DND until 5 PM.', iconSymbol: '\u1F615', gradient: ['#22D3EE', '#3B82F6'] },
        { id: 6, name: 'Daily Log', description: 'Log your daily tasks to Notes.', iconSymbol: '\u270F', gradient: ['#EC4899', '#F43F5E'] }
      ]
    },
    {
      id: 3,
      name: 'Photography',
      items: [
        { id: 7, name: 'Photo Grid', description: 'Combine photos into a grid.', iconSymbol: '\u1F5C2', gradient: ['#FACC15', '#F97316'] },
        { id: 8, name: 'Make GIF', description: 'Turn your video into a GIF.', iconSymbol: '\u29F7', gradient: ['#2DD4BF', '#059669'] }
      ]
    }
  ];

  build() {
    Column() {
      PageHeader({
        title: 'Gallery',
        showAvatar: true,
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAdC6A82e5ULPURAk6K2yH4FSCE5lFgSSK6xz2T-4qPiJ1fxwcOKdpE_vJSPj6zruV0C3ioTK0H7OIyhQchjOxcEkJ4UFPJKLSseWiCTZ_abmqY1izpKOaWwk3EnOKo7q-DgpAZJ-Cjfcuz9Dk4CYBtHpFyBXArWMaMjo0s5bAkwnIXBAwAdjOgBy4tFworHWkW1gd8HgqGcSBeGsCoZkqhFk9X2bzeppMh3UcN1WnhURvlHMt0wJnGDPU_4COA0QtNADL-WR8PM7Y'
      })
      SearchBar({ placeholder: 'Search Gallery...', searchText: $searchText })
      this.GalleryContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6F8')
  }

  @Builder
  GalleryContent() {
    Scroll() {
      Column() {
        // Editor's Choice Card
        this.EditorChoiceCard()

        // Category Sections
        ForEach(this.categories, (category: Category) => {
          this.CategorySection(category)
        }, (category: Category) => category.id.toString())
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 8, bottom: 20 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  EditorChoiceCard() {
    Column() {
      Stack() {
        // Background gradient
        Column()
          .width('100%')
          .height(200)
          .borderRadius(16)
          .linearGradient({
            angle: 135,
            colors: [['#6366F1', 0.0], ['#607AFB', 1.0]]
          })
          .shadow({ radius: 20, color: 'rgba(99, 102, 241, 0.25)', offsetY: 8 })

        // Decorative icon
        Text('\u2728')
          .fontSize(140)
          .fontColor('rgba(255, 255, 255, 0.1)')
          .position({ x: -30, y: -30 })
          .rotate({ angle: 12 })

        // Content
        Column() {
          Text('Editor\'s Choice')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(4)
            .margin({ bottom: 12 })

          Text('Automate your Morning Routine')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 8 })

          Text('Start your day right with these essential productivity shortcuts.')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('rgba(255, 255, 255, 0.9)')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('80%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .margin({ bottom: 24 })
  }

  @Builder
  CategorySection(category: Category) {
    Column() {
      // Header
      Row() {
        Text(category.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')

        Text('See All')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#607AFB')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 })

      // Horizontal scroll list
      Scroll() {
        Row({ space: 16 }) {
          ForEach(category.items, (item: GalleryItem) => {
            this.GalleryItemCard(item)
          }, (item: GalleryItem) => item.id.toString())
        }
        .padding({ right: 4 })
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .margin({ bottom: 24 })
  }

  @Builder
  GalleryItemCard(item: GalleryItem) {
    Column() {
      Row() {
        Row() {
          Text(item.iconSymbol)
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .width(48)
        .height(48)
        .borderRadius(12)
        .linearGradient({
          angle: 135,
          colors: [[item.gradient[0], 0.0], [item.gradient[1], 1.0]]
        })
        .justifyContent(FlexAlign.Center)
        .shadow({ radius: 8, color: item.gradient[1] + '33', offsetY: 4 })

        Blank()
      }
      .width('100%')

      Column() {
        Text(item.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111827')
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(item.description)
          .fontSize(11)
          .fontWeight(FontWeight.Normal)
          .fontColor('#6B7280')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .lineHeight(16)
          .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button() {
        Row() {
          Text('+')
            .fontSize(14)
            .fontColor('#607AFB')
            .margin({ right: 4 })
          Text('Add')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#607AFB')
        }
      }
      .type(ButtonType.Normal)
      .backgroundColor('#F3F4F6')
      .borderRadius(8)
      .width('100%')
      .height(32)
      .margin({ top: 12 })
      .onClick(() => {
        console.info(`Add ${item.name}`);
      })
    }
    .width(160)
    .height(192)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(0, 0, 0, 0.05)' })
    .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.05)', offsetY: 2 })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Start)
  }
}
