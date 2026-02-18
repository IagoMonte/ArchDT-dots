//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the shell smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1


import qs.modules.common
import qs.modules.bar
import qs.modules.notificationPopup
import qs.modules.cheatsheet
// import qs.modules.dock
import qs.modules.mediaControls
import qs.modules.onScreenDisplay
import qs.modules.overview
import qs.modules.hyprview
import qs.modules.regionSelector
import qs.modules.sidebarRight

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

ShellRoot {
    id: root

    // Force initialization of some singletons
    Component.onCompleted: {
        Cliphist.refresh()
    }

    // Load enabled stuff
    // Well, these loaders only *allow* them to be loaded, to always load or not is defined in each component
    // The media controls for example is not loaded if it's not opened
    PanelLoader { identifier: "iiBar"; component: Bar {} } //essa é a barra que eu quero
    PanelLoader { identifier: "iiCheatsheet"; component: Cheatsheet {} } //tem que dar um talento mas os comando é legal.
    PanelLoader { identifier: "iiMediaControls"; component: MediaControls {} } //gostamos media control
    PanelLoader { identifier: "iiNotificationPopup"; component: NotificationPopup {} } // prefiro minha notifipopup
    PanelLoader { identifier: "iiOnScreenDisplay"; component: OnScreenDisplay {} }
    PanelLoader { identifier: "iiOverview"; component: Overview {} } // laucher muito pika PONTO.DOT
    Hyprview {liveCapture: false; moveCursorToActiveWindow: false}
    PanelLoader { identifier: "iiRegionSelector"; component: RegionSelector {} } //print legalzao pprt
    PanelLoader { identifier: "iiSidebarRight"; component: SidebarRight {} }

    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && Config.options.enabledPanels.includes(identifier) && extraCondition
    }

    // Panel families
    property list<string> families: ["ii", "waffle"]
    property var panelFamilies: ({
        "ii": ["iiBar", "iiBackground", "iiCheatsheet", "iiDock", "iiLock", "iiMediaControls", "iiNotificationPopup", "iiOnScreenDisplay", "iiOnScreenKeyboard", "iiOverlay", "iiOverview", "iiPolkit", "iiRegionSelector", "iiScreenCorners", "iiSessionScreen", "iiSidebarLeft", "iiSidebarRight", "iiVerticalBar", "iiWallpaperSelector","hyprview"],
        "waffle": ["wActionCenter", "wBar", "wBackground", "wNotificationCenter", "wOnScreenDisplay", "wStartMenu", "iiCheatsheet", "iiLock", "iiNotificationPopup", "iiOnScreenKeyboard", "iiOverlay", "iiPolkit", "iiRegionSelector", "iiSessionScreen", "iiWallpaperSelector"],
    })
    function cyclePanelFamily() {
        const currentIndex = families.indexOf(Config.options.panelFamily)
        const nextIndex = (currentIndex + 1) % families.length
        Config.options.panelFamily = families[nextIndex]
        Config.options.enabledPanels = panelFamilies[Config.options.panelFamily]
    }

    IpcHandler {
        target: "panelFamily"

        function cycle(): void {
            root.cyclePanelFamily()
        }
    }

    GlobalShortcut {
        name: "panelFamilyCycle"
        description: "Cycles panel family"

        onPressed: root.cyclePanelFamily()
    }
}

