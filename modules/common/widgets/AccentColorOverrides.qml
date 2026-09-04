import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Per-role accent colour overrides.
 *
 * The scheme picker next to this only chooses how one seed colour is expanded,
 * so the individual accent roles cannot be aimed at a specific colour. This
 * exposes the twelve accent slots directly; anything left unset keeps whatever
 * the generated palette produced.
 */
ContentSubsection {
    id: root

    readonly property real labelColumnWidth: 96
    readonly property real swatchSize: 44
    readonly property real columnSpacing: 12

    title: Translation.tr("Manual accent colors")
    tooltip: Translation.tr("Click a swatch to pick its colour, right click to put it back to the generated one. Unset slots keep following the wallpaper.")

    function openPicker(slotKey, seedColor) {
        picker.editingKey = slotKey;
        picker.loadFrom(seedColor);
        picker.open();
    }

    ColorPickerDialog {
        id: picker
        property string editingKey: ""
        onAccepted: hex => PaletteOverrides.setOverride(picker.editingKey, hex)
        // The shared picker's "from screen" applies to the seed colour, which is
        // not what a single slot wants, so sample straight into the slot instead.
        onPickFromScreen: screenPickProc.running = true
    }

    Process {
        id: screenPickProc
        command: ["hyprpicker", "--no-fancy"]
        stdout: StdioCollector {
            onStreamFinished: {
                const hex = text.trim();
                if (hex.length > 0) PaletteOverrides.setOverride(picker.editingKey, hex);
            }
        }
    }

    component Swatch: Item {
        id: swatch
        required property string slotKey
        required property string slotRole

        implicitWidth: root.swatchSize
        implicitHeight: root.swatchSize

        // Resolved the same way the palette resolves it, so the swatch shows
        // exactly the colour the role ends up with, override or not.
        readonly property color effectiveColor: PaletteOverrides.colorFor(slotKey, slotRole)
        readonly property bool overridden: PaletteOverrides.overrideMap.enable
            && PaletteOverrides.overrideFor(slotKey) !== ""

        Rectangle {
            id: ring
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: Appearance.rounding.small
            color: "transparent"
            border.width: swatch.overridden ? 2 : 0
            border.color: Appearance.colors.colOnLayer0

            Behavior on border.width {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 8
            height: parent.height - 8
            radius: Appearance.rounding.small - 3
            color: swatch.effectiveColor
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
            opacity: mouseArea.containsMouse ? 0.85 : 1

            MaterialSymbol {
                anchors.centerIn: parent
                visible: swatch.overridden
                text: "edit"
                iconSize: Appearance.font.pixelSize.small
                // Pair the marker with the swatch it sits on so it stays readable
                // whatever colour was picked.
                color: ColorUtils.isDark(swatch.effectiveColor) ? "#ffffff" : "#000000"
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: event => {
                if (event.button === Qt.RightButton) {
                    PaletteOverrides.setOverride(swatch.slotKey, "");
                    return;
                }
                root.openPicker(swatch.slotKey, swatch.effectiveColor);
            }
            StyledToolTip {
                // A MouseArea has no `hovered`, which the default condition
                // reads, so drive visibility off containsMouse explicitly.
                extraVisibleCondition: false
                alternativeVisibleCondition: mouseArea.containsMouse
                text: swatch.slotKey + " · " + (swatch.overridden
                    ? PaletteOverrides.overrideFor(swatch.slotKey)
                    : Translation.tr("generated"))
            }
        }
    }

    ConfigSwitch {
        buttonIcon: "colors"
        text: Translation.tr("Use manual accent colors")
        checked: Config.options.appearance.palette.overrides.enable
        onCheckedChanged: {
            Config.options.appearance.palette.overrides.enable = checked;
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 4
        opacity: Config.options.appearance.palette.overrides.enable ? 1 : 0.4

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        RowLayout {
            spacing: root.columnSpacing
            Item { Layout.preferredWidth: root.labelColumnWidth }
            Repeater {
                model: PaletteOverrides.variantLabels
                // The label is wider than the swatch it sits above, so it gets a
                // cell the width of a swatch and a text that is allowed to spill
                // into the gaps and wrap rather than run into its neighbour.
                delegate: Item {
                    required property string modelData
                    Layout.preferredWidth: root.swatchSize
                    Layout.preferredHeight: headerLabel.implicitHeight
                    StyledText {
                        id: headerLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: root.swatchSize + root.columnSpacing
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: Translation.tr(modelData)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        Repeater {
            model: PaletteOverrides.roleGroups
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: root.columnSpacing

                StyledText {
                    Layout.preferredWidth: root.labelColumnWidth
                    text: Translation.tr(modelData.title)
                    color: Appearance.colors.colOnLayer0
                }
                Repeater {
                    model: modelData.slots
                    delegate: Swatch {
                        required property var modelData
                        slotKey: modelData.key
                        slotRole: modelData.role
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }

        RowLayout {
            Layout.topMargin: 4
            Item { Layout.fillWidth: true }
            DialogButton {
                buttonText: Translation.tr("Reset all")
                enabled: PaletteOverrides.hasAnyOverride
                onClicked: PaletteOverrides.clearAll()
            }
        }
    }
}
