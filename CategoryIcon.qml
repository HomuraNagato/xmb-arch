// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtGraphicalEffects 1.0

Item {
    id: root

    property string iconName: "generic"
    property int iconStyle: 0
    property color accentColor: "#b9e7ff"
    property bool focused: false
    property bool selected: false

    readonly property string variant: iconStyle === 2 ? "solid" : "outline"
    readonly property color iconColor: iconStyle === 1 ? accentColor : "#e9f7ff"

    Image {
        id: sourceIcon
        anchors.fill: parent
        source: "assets/categories/" + root.iconName + "-" + root.variant + ".svg"
        sourceSize.width: 128
        sourceSize.height: 128
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    Glow {
        anchors.fill: tintedIcon
        source: tintedIcon
        radius: 13
        samples: 25
        spread: 0.18
        color: "#8ad9ff"
        cached: true
        visible: root.focused
    }

    ColorOverlay {
        id: tintedIcon
        anchors.fill: parent
        source: sourceIcon
        color: root.iconStyle === 2 ? "white" : root.iconColor
        cached: true
    }
}
