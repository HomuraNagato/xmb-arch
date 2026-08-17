// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15

Canvas {
    id: root

    renderTarget: Canvas.FramebufferObject
    renderStrategy: Canvas.Threaded

    property bool reducedMotion: false
    property int preset: 0
    property real phase: 0

    readonly property var colors: [
        ["#65b9e8", "#2873bb"],
        ["#72d0bb", "#277d80"],
        ["#e2a96c", "#aa5548"]
    ]

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const palette = colors[preset % colors.length];

        for (let layer = 0; layer < 3; layer++) {
            const center = height * (0.55 + layer * 0.055);
            const amplitude = height * (0.045 + layer * 0.012);
            const offset = phase * (0.75 + layer * 0.2) + layer * 1.6;
            const gradient = ctx.createLinearGradient(0, 0, width, 0);
            gradient.addColorStop(0, "transparent");
            gradient.addColorStop(0.28, palette[0]);
            gradient.addColorStop(0.72, palette[1]);
            gradient.addColorStop(1, "transparent");

            ctx.beginPath();
            ctx.moveTo(0, center);
            for (let x = 0; x <= width; x += Math.max(8, width / 160)) {
                const y = center
                    + Math.sin((x / width) * Math.PI * 2.2 + offset) * amplitude
                    + Math.sin((x / width) * Math.PI * 4.7 - offset * 0.55) * amplitude * 0.28;
                ctx.lineTo(x, y);
            }
            ctx.strokeStyle = gradient;
            ctx.lineWidth = Math.max(1.5, height * (0.004 - layer * 0.0007));
            ctx.globalAlpha = 0.34 - layer * 0.07;
            ctx.stroke();
        }
    }

    NumberAnimation on phase {
        from: 0
        to: Math.PI * 2
        duration: 26000
        running: root.visible && !root.reducedMotion
        loops: Animation.Infinite
    }

    onPhaseChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPresetChanged: requestPaint()
    onReducedMotionChanged: requestPaint()
    Component.onCompleted: requestPaint()
}
