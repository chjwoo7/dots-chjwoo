import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

/**
 * A visual colour picker for choosing the shell accent colour by hand.
 *
 * The stock shell can only take an accent colour from the wallpaper or from
 * hyprpicker, which means a colour that is not already on screen cannot be
 * chosen without looking its hex up elsewhere first. This fills that gap.
 *
 * Emits `accepted(hex)` with a "#rrggbb" string. It does not apply anything
 * itself; the caller decides what to do with the value.
 */
Popup {
    id: root

    property color selectedColor: "#7c9a6d"
    signal accepted(string hex)
    signal pickFromScreen()

    // Hue is kept separately from selectedColor: a fully desaturated or black
    // colour has no meaningful hue, and reading it back would snap the picker
    // to red and lose where the user was.
    property real hue: 0
    property real sat: 1
    property real val: 1
    property bool updatingFromHex: false

    function toHex(c) {
        const p = (x) => Math.round(x * 255).toString(16).padStart(2, '0');
        return "#" + p(c.r) + p(c.g) + p(c.b);
    }

    function loadFrom(hexString) {
        const c = Qt.color(hexString);
        if (!c.valid ?? false) return;
        if (c.hsvHue >= 0) root.hue = c.hsvHue;
        root.sat = c.hsvSaturation;
        root.val = c.hsvValue;
        root.syncColor();
    }

    function syncColor() {
        root.selectedColor = Qt.hsva(root.hue, root.sat, root.val, 1);
        if (!root.updatingFromHex) hexField.text = root.toHex(root.selectedColor);
    }

    onHueChanged: root.syncColor()
    onSatChanged: root.syncColor()
    onValChanged: root.syncColor()

    modal: true
    dim: true
    anchors.centerIn: Overlay.overlay
    padding: 20
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Item {
        // The shadow anchors onto its target, so it has to be a sibling drawn
        // before the panel rather than a child of it.
        StyledRectangularShadow { target: panelBackground }

        Rectangle {
            id: panelBackground
            anchors.fill: parent
            // m3colors is the opaque palette; Appearance.colors folds in
            // contentTransparency and would let the desktop show through.
            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: Appearance.rounding.large
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
        }
    }

    contentItem: ColumnLayout {
        spacing: 14

        StyledText {
            text: Translation.tr("Pick accent colour")
            font.pixelSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer0
        }

        // --- Saturation / value field -------------------------------------
        // Hue underneath, white washed in from the left, black from the bottom.
        Rectangle {
            id: svArea
            Layout.preferredWidth: 280
            Layout.preferredHeight: 170
            radius: Appearance.rounding.small
            clip: true
            color: Qt.hsva(root.hue, 1, 1, 1)

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ffffffff" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00000000" }
                    GradientStop { position: 1.0; color: "#ff000000" }
                }
            }

            Rectangle { // crosshair
                width: 16; height: 16; radius: 8
                border.width: 2
                border.color: root.val > 0.5 ? "#000000" : "#ffffff"
                color: "transparent"
                x: root.sat * svArea.width - width / 2
                y: (1 - root.val) * svArea.height - height / 2
            }

            MouseArea {
                anchors.fill: parent
                function apply(mx, my) {
                    root.sat = Math.max(0, Math.min(1, mx / width));
                    root.val = Math.max(0, Math.min(1, 1 - my / height));
                }
                onPressed: (e) => apply(e.x, e.y)
                onPositionChanged: (e) => { if (pressed) apply(e.x, e.y) }
            }
        }

        // --- Hue slider ----------------------------------------------------
        Rectangle {
            id: hueBar
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.000; color: "#ff0000" }
                GradientStop { position: 0.167; color: "#ffff00" }
                GradientStop { position: 0.333; color: "#00ff00" }
                GradientStop { position: 0.500; color: "#00ffff" }
                GradientStop { position: 0.667; color: "#0000ff" }
                GradientStop { position: 0.833; color: "#ff00ff" }
                GradientStop { position: 1.000; color: "#ff0000" }
            }

            Rectangle { // handle
                width: 8
                height: parent.height + 6
                radius: 4
                y: -3
                x: root.hue * (hueBar.width - width)
                color: Appearance.colors.colOnLayer0
                border.width: 2
                border.color: Appearance.colors.colSurfaceContainerHigh
            }

            MouseArea {
                anchors.fill: parent
                function apply(mx) { root.hue = Math.max(0, Math.min(1, mx / width)) }
                onPressed: (e) => apply(e.x)
                onPositionChanged: (e) => { if (pressed) apply(e.x) }
            }
        }

        // --- Hex field and preview -----------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: Appearance.rounding.small
                color: root.selectedColor
                border.width: 1
                border.color: Appearance.m3colors.m3outlineVariant
            }

            MaterialTextField {
                id: hexField
                Layout.fillWidth: true
                placeholderText: "#rrggbb"
                text: root.toHex(root.selectedColor)
                inputMethodHints: Qt.ImhNoAutoUppercase
                onTextEdited: {
                    if (!/^#?[0-9A-Fa-f]{6}$/.test(text)) return;
                    root.updatingFromHex = true;
                    root.loadFrom(text.startsWith("#") ? text : "#" + text);
                    root.updatingFromHex = false;
                }
            }
        }

        // --- Buttons ---------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 6

            DialogButton {
                buttonText: Translation.tr("From screen")
                onClicked: {
                    root.pickFromScreen();
                    root.close();
                }
            }

            Item { Layout.fillWidth: true }

            DialogButton {
                buttonText: Translation.tr("Cancel")
                onClicked: root.close()
            }
            DialogButton {
                buttonText: Translation.tr("Apply")
                onClicked: {
                    root.accepted(root.toHex(root.selectedColor));
                    root.close();
                }
            }
        }
    }
}
