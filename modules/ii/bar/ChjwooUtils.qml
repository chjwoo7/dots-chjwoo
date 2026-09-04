import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Custom widget (bukan bagian dari upstream end4-pC). Isinya dua tombol:
//  1. Toggle ideapad_laptop conservation_mode — batasi charge baterai ~60%.
//     Butuh udev rule biar sysfs group-writable oleh `wheel` (60-ideapad-conservation.rules).
//     Hover di tombolnya nampilin popup status On/Off, sama gayanya dgn popup baterai.
//  2. Snip + anotasi pakai satty. Sama persis dgn keybind CTRL+Print.
Item {
    id: root

    readonly property string conservationPath: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

    // Dijaga sinkron dengan keybind CTRL+Print di ~/.config/hypr/custom/keybinds.lua
    readonly property string snipCommand: "grim -g \"$(slurp)\" - | satty -f - --early-exit --actions-on-enter save-to-clipboard --copy-command wl-copy --initial-tool rectangle"

    property bool conservationOn: false
    property bool available: false
    property bool writable: false

    property bool vertical: Config.options.bar.vertical
    property bool isMaterial: Config.options.bar.cornerStyle === 3

    implicitWidth: isMaterial && !root.vertical ? flow.implicitWidth
                 : root.vertical ? Appearance.sizes.verticalBarWidth - 14
                 : flow.implicitWidth + 4
    implicitHeight: isMaterial && root.vertical ? flow.implicitHeight
                  : isMaterial ? 32
                  : root.vertical ? flow.implicitHeight + 4
                  : Appearance.sizes.barHeight

    // --- Baca state dari sysfs -------------------------------------------------
    // sysfs ga bisa diandelin buat inotify, jadi polling. Murah: 1 file 1 byte.
    FileView {
        id: conservationFile
        path: root.conservationPath
        printErrors: false
        onLoaded: {
            const v = text().trim()
            root.available = (v === "0" || v === "1")
            root.conservationOn = (v === "1")
        }
        onLoadFailed: root.available = false
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: conservationFile.reload()
    }

    // Cek sekali apakah file-nya writable, buat nentuin tampilan "terkunci".
    Process {
        id: writableCheck
        running: true
        command: ["test", "-w", root.conservationPath]
        onExited: (exitCode, exitStatus) => root.writable = (exitCode === 0)
    }

    // --- Tulis state ke sysfs --------------------------------------------------
    // Kalau udev rule belum kepasang, write-nya gagal diam-diam dan polling
    // bakal balikin ikon ke state asli. UI ga akan bohong.
    function setConservation(enable) {
        Quickshell.execDetached(["bash", "-c",
            "echo " + (enable ? "1" : "0") + " > '" + root.conservationPath + "'"])
        confirmTimer.restart()
    }

    Timer {
        id: confirmTimer
        interval: 250
        repeat: false
        onTriggered: {
            conservationFile.reload()
            writableCheck.running = true
        }
    }

    function toggle() {
        root.setConservation(!root.conservationOn)
    }

    readonly property string iconName: !root.writable ? "lock"
                                     : root.conservationOn ? "eco"
                                     : "battery_charging_full"

    // --- Tampilan --------------------------------------------------------------
    Flow {
        id: flow
        anchors.centerIn: parent
        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: root.isMaterial ? 2 : 4

        // Tombol 1: toggle conservation mode.
        // Dibungkus Item supaya punya `containsMouse` buat hoverTarget StyledPopup.
        // Hover dibaca lewat HoverHandler, bukan MouseArea pembungkus, biar hover
        // milik tombol di dalamnya (UtilButton/RippleButton) tidak ketelan.
        Item {
            id: conservationButton
            visible: root.available
            implicitWidth: conservationLoader.implicitWidth
            implicitHeight: conservationLoader.implicitHeight

            property bool containsMouse: conservationHover.hovered

            HoverHandler {
                id: conservationHover
                enabled: !Config.options.bar.tooltips.clickToShow
            }

            Loader {
                id: conservationLoader
                active: root.available
                visible: active
                sourceComponent: root.isMaterial ? conservationM3 : legacyConservation
            }

            // Popup status saat hover, gaya sama dengan popup baterai.
            StyledPopup {
                hoverTarget: conservationButton

                ColumnLayout {
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 3
                        spacing: 8

                        MaterialShapeWrappedMaterialSymbol {
                            shape: MaterialShape.Shape.Clover4Leaf
                            text: root.iconName
                            fill: root.conservationOn ? 1 : 0
                            iconSize: Appearance.font.pixelSize.large
                            implicitSize: 36
                            color: root.conservationOn ? Appearance.colors.colPrimaryContainer
                                                       : Appearance.colors.colSecondaryContainer
                            colSymbol: root.conservationOn ? Appearance.colors.colPrimary
                                                           : Appearance.colors.colOnSecondaryContainer
                        }

                        ColumnLayout {
                            spacing: -3

                            StyledText {
                                text: "Conservation Mode"
                                font {
                                    weight: Font.Medium
                                    pixelSize: Appearance.font.pixelSize.normal
                                }
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnSurfaceVariant
                                opacity: 0.6
                                text: {
                                    if (!root.writable)
                                        return "Locked \u00b7 sysfs is not writable"
                                    if (root.conservationOn)
                                        return "Charging stops at ~60% \u00b7 click to turn off"
                                    return "Charging up to 100% \u00b7 click to turn on"
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        StyledText {
                            Layout.rightMargin: 8
                            Layout.leftMargin: 8
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            color: root.conservationOn ? Appearance.colors.colPrimary
                                                       : Appearance.colors.colOnSurfaceVariant
                            text: root.conservationOn ? "On" : "Off"
                        }
                    }
                }
            }
        }

        Component {
            id: conservationM3
            UtilButton {
                iconText: root.iconName
                forceHovered: root.conservationOn
                onClicked: root.toggle()
            }
        }

        Component {
            id: legacyConservation
            CircleUtilButton {
                onClicked: root.toggle()
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: root.conservationOn ? 1 : 0
                    text: root.iconName
                    iconSize: Appearance.font.pixelSize.large
                    color: root.conservationOn ? Appearance.colors.colPrimary
                                               : Appearance.colors.colOnLayer2
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // --- Tombol 2: snip + anotasi (satty) ---
        Loader {
            sourceComponent: root.isMaterial ? snipM3 : legacySnip
        }

        Component {
            id: snipM3
            UtilButton {
                iconText: "screenshot_region"
                onClicked: Quickshell.execDetached(["bash", "-c", root.snipCommand])
            }
        }

        Component {
            id: legacySnip
            CircleUtilButton {
                onClicked: Quickshell.execDetached(["bash", "-c", root.snipCommand])
                MaterialSymbol {
                    horizontalAlignment: Qt.AlignHCenter
                    fill: 0
                    text: "screenshot_region"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }
            }
        }
    }
}
