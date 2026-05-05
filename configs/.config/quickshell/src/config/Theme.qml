// Theme.qml
pragma Singleton
import QtQuick

QtObject {
    // --- Global Palette ---
    readonly property color bg:        "#1a1b26"
    readonly property color bgElevated:"#24283b"
    readonly property color border:    "#2f334d"
    readonly property color fg:        "#c0caf5"
    readonly property color fgMuted:   "#565f89"
    readonly property color accent:    "#7aa2f7"
    readonly property color accentHot: "#0db9d7"
    readonly property color separator: "#33c0caf5"
    readonly property color danger:    "#e06c75"

    // --- Global Spacing & Sizing ---
    readonly property int   s1: 4
    readonly property int   s2: 8
    readonly property int   s3: 12
    readonly property int   s4: 16
    readonly property int   s5: 24

    readonly property int   widgetRadius: 12
    readonly property int   borderWidth: 2

    readonly property string fontFamily: "Inter"
    readonly property string fontFamilyIcons: "Symbols Nerd Font Mono"

    readonly property int    fontWeightThin:     Font.Thin
    readonly property int    fontWeightLight:    Font.Light
    readonly property int    fontWeightNormal:   Font.Normal
    readonly property int    fontWeightMedium:   Font.Medium
    readonly property int    fontWeightDemiBold: Font.DemiBold
    readonly property int    fontWeightBold:     Font.Bold
    readonly property int    fontWeightBlack:    Font.Black

    readonly property int    fontWeight:         fontWeightNormal

    readonly property int    fontSizeHeading: 18
    readonly property int    fontSizeLarge:   15
    readonly property int    fontSizeNormal:  13
    readonly property int    fontSizeSmall:   11
    readonly property int    fontSizeTiny:    10
    
    readonly property int    fontSize:        fontSizeNormal
    readonly property int    iconSize:        16

    readonly property int popupGap: s2
    readonly property int belowBar: popupGap
    readonly property int aboveDock: 66

    // --- Component: AppIcon ---
    readonly property int appIconDefaultSize: 48

    // --- Component: Button ---
    readonly property int buttonHorizontalPadding: 8
    readonly property int buttonVerticalPadding: 4
    readonly property int buttonRadius: 8
    readonly property color buttonBgColor: "transparent"
    readonly property color buttonContentColor: Theme.fg
    readonly property color buttonHoverColor: Theme.fg
    readonly property real buttonHoverOpacity: 0.06
    readonly property real buttonPressedOpacity: 0.12
    readonly property int buttonAnimDuration: 120

    // --- Component: ConfirmPopup ---
    readonly property int confirmPopupDefaultTimeout: 60
    readonly property int confirmPopupCloseDelay: 200
    readonly property real confirmPopupHiddenScale: 0.95
    readonly property int confirmPopupAnimDuration: 200

    // --- Component: Label ---
    readonly property int labelGap: 6

    // --- Component: PopupBase ---
    readonly property int popupDefaultWidth: 400
    readonly property int popupDefaultHeight: 200
    readonly property int popupOpenDuration: 280
    readonly property int popupCloseDuration: 140
    readonly property real popupHiddenScale: 0.94
    readonly property int popupEdgeMargin: Theme.s2

    // --- Component: Separator ---
    readonly property int separatorThickness: 2
    readonly property int separatorPadding: 8
    readonly property color separatorColor: "#2f334d"

    // --- Component: Slider ---
    readonly property int sliderHeight: 24
    readonly property int sliderTrackHeight: 6
    readonly property int sliderRadius: 3
    readonly property int sliderHandleSize: 14
    readonly property int sliderHandleRadius: 7
    readonly property int sliderHandleBorderWidth: 2
    readonly property color sliderTrackColor: Qt.rgba(1, 1, 1, 0.1)

    // --- Module: Bar ---
    readonly property int barHeight: 35
    readonly property int barMargin: Theme.s2
    readonly property int barContentPadding: Theme.s3
    readonly property int barSpacing: Theme.s2
    readonly property int barButtonIconSize: 15

    // --- Module: LaunchMenu ---
    readonly property int launchMenuHeight: 425
    readonly property int launchMenuWidth: 700
    readonly property int launchMenuIconSize: 48
    readonly property int launchMenuSearchBarHeight: 27
    readonly property int launchMenuSearchIconSize: 12
    readonly property int launchMenuSearchBorderWidth: 1
    readonly property int launchMenuSearchPadding: 10
    readonly property int launchMenuCellRadius: 10
    readonly property int launchMenuCellMargin: Theme.s1
    readonly property int launchMenuAnimDuration: 150
    readonly property int launchMenuPageAnimDuration: 180
    readonly property real launchMenuCellHoverOpacity: 0.06
    readonly property real launchMenuCellSelectedOpacity: 0.10
    readonly property int launchMenuCellSpacing: 6
    readonly property int launchMenuIconFallbackFontSize: 18
    readonly property int launchMenuGridColumns: 5
    readonly property int launchMenuGridRows: 3
    readonly property int launchMenuListBottomMargin: 24
    readonly property int launchMenuClearIconSize: 10
    readonly property int launchMenuClearMargin: -6

    // --- Component: Indicator ---
    readonly property int indicatorHeight: 6
    readonly property int indicatorWidth: 6
    readonly property int indicatorWidthActive: 18
    readonly property int indicatorRadius: 3
    readonly property int indicatorSpacing: 6
    readonly property int indicatorAnimDuration: 200

    // --- Module: NetworkMenu ---
    readonly property int networkMenuWidth: 340
    readonly property int networkMenuRowHeight: 34
    readonly property int networkMenuRowRadius: 6
    readonly property color networkMenuRowHoverBg: Qt.rgba(1, 1, 1, 0.06)
    readonly property color networkMenuRowActiveBg: Qt.rgba(1, 1, 1, 0.035)
    readonly property int networkMenuRowPadding: 8
    readonly property int networkMenuRowGap: 8
    readonly property int networkMenuCheckmarkWidth: 12
    readonly property int networkMenuExpandMargin: 24
    readonly property int networkMenuExpandRightMargin: 8
    readonly property int networkMenuExpandTopMargin: 4
    readonly property int networkMenuExpandSpacing: 6
    readonly property int networkMenuMaxListHeight: 280
    readonly property int networkMenuPasswordFieldHeight: 32

    // --- Module: PowerMenu ---
    readonly property int powerMenuWidth: 200
    readonly property int powerMenuHeight: 125
    readonly property int powerMenuIconSize: 18

    // --- Module: VolumeMenu ---
    readonly property int volumeMenuWidth: 320
    readonly property int volumeMenuHeight: 450
    readonly property int volumeMenuIconSize: 24
    readonly property int volumeMenuAppIconSize: 32
    readonly property int volumeMenuRowHeight: 40
    readonly property int volumeMenuDividerHeight: 1

    // --- Module: QuickLaunchMenu ---
    readonly property int dockWidth: 300
    readonly property int dockExpandedHeight: 45
    readonly property int dockCollapsedHeight: 6
    readonly property int dockExpandedBottomMargin: 8
    readonly property int dockCollapsedBottomMargin: 2
    readonly property int dockHotPadX: 40
    readonly property int dockHotPadY: 10
    readonly property int dockRadius: 22
    readonly property int dockCollapsedRadius: 2
    readonly property int dockAnimDuration: 240
    readonly property int dockContentPadding: 14
    readonly property int dockIconBaseSize: 36
    readonly property int dockIconActiveSize: 26
    readonly property int dockSpacing: 8
    readonly property int dockCollapseDelay: 180
    readonly property real dockScaleMin: 1.0
    readonly property real dockScaleMax: 1.4

    // --- Module: WorkspaceOverview ---
    readonly property int workspaceOverviewHeight: 120
    readonly property int workspaceOverviewMargin: 8
    readonly property int workspaceOverviewItemWidth: 150
    readonly property int workspaceOverviewItemHeight: 100
    readonly property int workspaceOverviewItemSpacing: 10
    readonly property int workspaceOverviewPadding: 10
    readonly property int workspaceOverviewMinWorkspaces: 2
    readonly property int workspaceOverviewMaxWorkspaces: 10
    readonly property int workspaceOverviewIconSize: 22

    // --- Module: BrightnessMenu ---
    readonly property int brightnessMenuWidth: 340
}
