// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15

Row {
    id: root

    property string controllerStyle: "keyboard"
    property var hints: []
    property real unit: 1
    property string fontFamily: ""

    spacing: 22 * unit

    function gamepadIcon(control) {
        if (control === "horizontal" || control === "vertical" || control === "down")
            return "assets/hints/dpad-" + control + ".svg";
        if (controllerStyle === "playstation")
            return "assets/hints/ps-" + control + ".svg";
        return "assets/hints/xbox-" + control + ".svg";
    }

    Repeater {
        model: root.hints

        delegate: Row {
            spacing: 7 * root.unit

            Image {
                width: 25 * root.unit
                height: 25 * root.unit
                anchors.verticalCenter: parent.verticalCenter
                source: root.controllerStyle === "keyboard" ? "" : root.gamepadIcon(modelData.control)
                sourceSize.width: 50
                sourceSize.height: 50
                fillMode: Image.PreserveAspectFit
                visible: root.controllerStyle !== "keyboard"
            }

            Rectangle {
                height: 25 * root.unit
                width: keyboardLabel.implicitWidth + 12 * root.unit
                anchors.verticalCenter: parent.verticalCenter
                radius: 4 * root.unit
                color: "#5c132536"
                border.color: "#9fb7c8"
                border.width: 1 * root.unit
                visible: root.controllerStyle === "keyboard"

                Text {
                    id: keyboardLabel
                    anchors.centerIn: parent
                    text: modelData.keyboard
                    color: "#d9e6ef"
                    font.family: root.fontFamily
                    font.pixelSize: 12 * root.unit
                    font.weight: Font.DemiBold
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: "#aabccc"
                font.family: root.fontFamily
                font.pixelSize: 14 * root.unit
            }
        }
    }
}
