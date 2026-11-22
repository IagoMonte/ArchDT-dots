import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    readonly property bool pomodoroActive: TimerService.pomodoroRunning
    readonly property string pomodoroText: {
        const s = Math.max(0, TimerService.pomodoroSecondsLeft);
        const mm = Math.floor(s / 60);
        const ss = s % 60;
        return `${mm < 10 ? "0" : ""}${mm}:${ss < 10 ? "0" : ""}${ss}`;
    }
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }

        StyledText {
            visible: root.showDate || root.pomodoroActive
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: "•"
        }

        // Pomodoro rodando: o tempo restante ocupa o lugar da data (a data continua no popup)
        RowLayout {
            visible: root.pomodoroActive
            spacing: 2

            MaterialSymbol {
                text: TimerService.pomodoroBreak ? "coffee" : "timer"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: root.pomodoroText
            }
        }

        StyledText {
            visible: root.showDate && !root.pomodoroActive
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: DateTime.longDate
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
