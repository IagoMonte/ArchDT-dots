import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import '.'

PanelWindow {
    id: root

    // --- SETTINGS ---
    property string layoutAlgorithm: ""
    property string lastLayoutAlgorithm: ""
    property bool liveCapture: false
    property bool moveCursorToActiveWindow: false

    // --- INTERNAL STATE ---
    property bool isActive: false
    property bool specialActive: false
    property bool animateWindows: false
    property var lastPositions: {}



    // --- ALT TAB DT ---
    property bool altHeld: false
    property bool switcherMode: false 

    // NOVO: Rastrear workspaces
    property bool userNavigated: false
    property int currentWorkspaceId: -1
    property int lastWorkspaceId: -1
    property bool justOpened: false
    property var cachedToplevels: []

    onIsActiveChanged: {
        if (isActive) {
            // ADICIONE: Force refresh antes de cachear
            Hyprland.refreshToplevels()
            
            // Aguarda um frame para garantir que refresh completou
            Qt.callLater(function() {
                cachedToplevels = Hyprland.toplevels.values
            })
        }
    }



    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: isActive

    // LayerShell Config
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: isActive ? 1 : 0
    WlrLayershell.namespace: "quickshell:hyprview"

    // --- IPC & EVENTS ---

    GlobalShortcut {
        name: "hyprview"
        description: "Toggle Hyprview window switcher"
        appid: "quickshell"
        
        onPressed: {
            if (!root.isActive) {
                root.userNavigated = false
                root.altHeld = true
                root.switcherMode = true
                root.isActive = true
                root.justOpened = true
                exposeArea.currentIndex = 0
                Hyprland.refreshToplevels()
            }
        }
    }   

    IpcHandler {
        target: "hyprview"
        
        function next() {
            if (root.switcherMode && winRepeater.count > 0) {
                if (root.justOpened) {
                    root.justOpened = false
                    return
                }
                moveToNext()
            }
        }
        
        function prev() {
            if (root.switcherMode && winRepeater.count > 0) {
                moveToPrev()
            }
        }

        function release() {
            if (root.switcherMode) {
                if (!root.userNavigated && root.lastWorkspaceId !== -1 && root.lastWorkspaceId !== root.currentWorkspaceId) {
                    Hyprland.dispatch(`workspace ${root.lastWorkspaceId.toString()}`)
                    root.closeSwitcher()
                } else {
                    root.activateSelectedWindow()
                }
                root.userNavigated = false
            }
    }
    }

    Connections {
        target: Hyprland
        enabled: true
        function onRawEvent(ev) {
            switch (ev.name) {
                case "openwindow":    
                case "closewindow":
                    Hyprland.refreshToplevels()
                    root.cachedToplevels = Hyprland.toplevels.values
                    return
                    
                case "activespecial":
                    var dataStr = String(ev.data)
                    var namePart = dataStr.split(",")[0]
                    root.specialActive = (namePart.length > 0)
                    return
                    
                default:
                    return
            }
        }
    }

    Connections {
        target: Hyprland
        enabled: true
        function onFocusedWorkspaceChanged() {
            var newWorkspaceId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
            
            if (newWorkspaceId !== root.currentWorkspaceId && root.currentWorkspaceId !== -1) {
                root.lastWorkspaceId = root.currentWorkspaceId
            }
            
            root.currentWorkspaceId = newWorkspaceId
        }
    }
    Component.onCompleted: {
        root.currentWorkspaceId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
    }



    function toggleExpose() {
        root.isActive = !root.isActive
        if (!root.isActive) {
            root.animateWindows = false
            root.lastPositions = {}
        }
    }



    function activateSelectedWindow() {
        var item = winRepeater.itemAt(exposeArea.currentIndex)
        if (item && item.activateWindow) {
            item.activateWindow()
        }
        closeSwitcher()
    }


    function closeSwitcher() {
           root.isActive = false

        Qt.callLater(function() {
            root.switcherMode = false
            root.animateWindows = false
            root.lastPositions = {}
            root.cachedToplevels = []
        })
    }   

    function closeWithoutActivating() {
        closeSwitcher()
    }
    
    function moveToNext() {
        const total = winRepeater.count
        if (total <= 0) return

        root.userNavigated = true
        
        var start = exposeArea.currentIndex
        for (var step = 1; step <= total; ++step) {
            var candidate = (start + step) % total
            var it = winRepeater.itemAt(candidate)
            if (it && it.visible) {
                exposeArea.currentIndex = candidate
                return
            }
        }
    }

    function moveToPrev() {
        const total = winRepeater.count
        if (total <= 0) return
        
        root.userNavigated = true

        var start = exposeArea.currentIndex
        for (var step = 1; step <= total; ++step) {
            var candidate = (start - step + total) % total
            var it = winRepeater.itemAt(candidate)
            if (it && it.visible) {
                exposeArea.currentIndex = candidate
                return
            }
        }
    }

    // --- USER INTERFACE ---

    FocusScope {
        id: mainScope
        anchors.fill: parent
        focus: true

        // Keyboard navigation
        Keys.onPressed: (event) => {
            if (!root.isActive && !root.switcherMode) return
            
            if (event.key === Qt.Key_Alt) {
                root.altHeld = true
                event.accepted = true
                return
            }

            

            if (event.key === Qt.Key_Escape) {
                root.toggleExpose()
                event.accepted = true
                return
            }


            const total = winRepeater.count
            if (total <= 0) return

            // Helper for horizontal navigation
            function moveSelectionHorizontal(delta) {
                var start = exposeArea.currentIndex
                for (var step = 1; step <= total; ++step) {
                    var candidate = (start + delta * step + total) % total
                    var it = winRepeater.itemAt(candidate)
                    if (it && it.visible) {
                        exposeArea.currentIndex = candidate
                        return
                    }
                }
            }

            // Helper for vertical navigation
            function moveSelectionVertical(dir) {
                var startIndex = exposeArea.currentIndex
                var currentItem = winRepeater.itemAt(startIndex)

                if (!currentItem || !currentItem.visible) {
                    moveSelectionHorizontal(dir > 0 ? 1 : -1)
                    return
                }

                var curCx = currentItem.x + currentItem.width  / 2
                var curCy = currentItem.y + currentItem.height / 2

                var bestIndex = -1
                var bestDy = 99999999
                var bestDx = 99999999

                for (var i = 0; i < total; ++i) {
                    var it = winRepeater.itemAt(i)
                    if (!it || !it.visible || i === startIndex) continue

                    var cx = it.x + it.width  / 2
                    var cy = it.y + it.height / 2
                    var dy = cy - curCy

                    // Direction filtering
                    if (dir > 0 && dy <= 0) continue
                    if (dir < 0 && dy >= 0) continue

                    var absDy = Math.abs(dy)
                    var absDx = Math.abs(cx - curCx)

                    // Search for nearest thumb (first in vertical, then horizontal distance)
                    if (absDy < bestDy || (absDy === bestDy && absDx < bestDx)) {
                        bestDy = absDy
                        bestDx = absDx
                        bestIndex = i
                    }
                }

                if (bestIndex >= 0) {
                    exposeArea.currentIndex = bestIndex
                }
            }

            if (event.key === Qt.Key_Right) {
                moveSelectionHorizontal(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                moveSelectionHorizontal(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                moveSelectionVertical(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                moveSelectionVertical(-1)
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                var item = winRepeater.itemAt(exposeArea.currentIndex)
                if (item && item.activateWindow) {
                    item.activateWindow()
                    event.accepted = true
                }
            }

            
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: false
            z: -1
            enabled: !root.switcherMode
            onClicked: root.closeSwitcher()
        }

        Item {
            id: layoutContainer
            anchors.fill: parent
            anchors.margins: 32

            Column {
                id: layoutRoot
                anchors.fill: parent
                anchors.margins: 48
                spacing: 20

                // thumbs area
                Item {
                    id: exposeArea
                    width: layoutRoot.width
                    height: layoutRoot.height - layoutRoot.spacing

                    property int currentIndex: 0


                    property string lastLayoutCacheKey: ""
                    property var cachedLayoutData: []
                        ScriptModel {
                            id: windowLayoutModel

                            property int areaW: exposeArea.width
                            property int areaH: exposeArea.height
                            property string algo: root.lastLayoutAlgorithm
                            property var rawToplevels: root.isActive ? Hyprland.toplevels.values : []
                            
                            values: {
                                if (!root.isActive || areaW <= 0 || areaH <= 0) return []

                                var toplevels = rawToplevels.length > 0 ? rawToplevels : root.cachedToplevels
                                
                                var cacheKey = `${areaW}|${areaH}|${algo}|${toplevels?.length || 0}`
                                
                                if (cacheKey === exposeArea.lastLayoutCacheKey && 
                                    exposeArea.cachedLayoutData.length > 0) {
                                    return exposeArea.cachedLayoutData
                                }
                                
                                var windowList = []
                                var idx = 0

                                if (!toplevels || toplevels.length === 0) return []

                                for (var it of toplevels) {
                                    var w = it
                                    var clientInfo = w?.lastIpcObject || {}
                                    var workspace = clientInfo?.workspace || null
                                    var workspaceId = workspace?.id

                                    if (workspaceId === undefined || workspaceId === null) continue
                                    
                                    var size = clientInfo?.size || [0, 0]
                                    var at = clientInfo?.at || [-1000, -1000]
                                    if (at[1] + size[1] <= 0) continue

                                    windowList.push({
                                        win: w,
                                        workspaceId: workspaceId,
                                        width: size[0],
                                        height: size[1],
                                        originalIndex: idx++
                                    })
                                }

                                windowList.sort(function(a, b) {
                                    if (a.workspaceId < b.workspaceId) return -1
                                    if (a.workspaceId > b.workspaceId) return 1
                                    if (a.originalIndex < b.originalIndex) return -1
                                    if (a.originalIndex > b.originalIndex) return 1
                                    return 0
                                })

                                var result = Mylayout.doLayout(windowList, areaW, areaH)
                            
                                Qt.callLater(function() {
                                    exposeArea.lastLayoutCacheKey = cacheKey
                                    exposeArea.cachedLayoutData = result
                                })
                                
                                return result
                            }
                        }
                    Repeater {
                        id: winRepeater
                        model: root.isActive ? windowLayoutModel : null

                        delegate: WindowThumbnail {
                            // Model data
                            hWin: modelData.win
                            wHandle: hWin?.wayland
                            winKey: String(hWin?.address || '')
                            thumbW: modelData.width
                            thumbH: modelData.height
                            clientInfo: hWin?.lastIpcObject

                            // Layout-generated coordinates
                            targetX: modelData.x
                            targetY: modelData.y

                            hovered: visible && (exposeArea.currentIndex === index)
                            moveCursorToActiveWindow: root.moveCursorToActiveWindow

                            Component.onDestruction: {
                                var key = winKey  // Captura antes de qualquer cleanup
                                if (root.lastPositions && key in root.lastPositions) {
                                    delete root.lastPositions[key]
                                }
                            }


                        }
                    }
                }
            }
        }
    }
}
