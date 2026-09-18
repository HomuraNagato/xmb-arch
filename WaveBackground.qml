// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15

ShaderEffect {
    id: root

    property bool reducedMotion: false
    property int preset: 0
    property real effectStrength: 1.0
    property real phase: 0.0

    readonly property var colors: [
        ["#65b9e8", "#2873bb"],
        ["#72d0bb", "#277d80"],
        ["#e2a96c", "#aa5548"]
    ]
    property color colorA: colors[preset % colors.length][0]
    property color colorB: colors[preset % colors.length][1]

    blending: true

    vertexShader: "
        uniform highp mat4 qt_Matrix;
        attribute highp vec4 qt_Vertex;
        attribute highp vec2 qt_MultiTexCoord0;
        varying highp vec2 coord;

        void main() {
            coord = qt_MultiTexCoord0;
            gl_Position = qt_Matrix * qt_Vertex;
        }
    "

    fragmentShader: "
        varying highp vec2 coord;
        uniform lowp float qt_Opacity;
        uniform highp float phase;
        uniform highp float effectStrength;
        uniform lowp vec4 colorA;
        uniform lowp vec4 colorB;

        highp float strand(highp float y, highp float center, highp float width) {
            return 1.0 - smoothstep(width, width * 3.1, abs(y - center));
        }

        void main() {
            highp float x = coord.x;
            highp float y = coord.y;
            highp float tau = 6.28318530718;

            highp float broadA = 0.600
                + sin(x * tau * 0.60 - phase * 0.42) * 0.060
                + sin(x * tau * 1.22 + phase * 0.18) * 0.012;
            highp float broadB = 0.605
                + sin(x * tau * 0.66 - phase * 0.35 + 0.62) * 0.047
                + sin(x * tau * 1.48 - phase * 0.22) * 0.010;
            highp float bodyA = 1.0 - smoothstep(0.006, 0.060, abs(y - broadA));
            highp float bodyB = 1.0 - smoothstep(0.008, 0.052, abs(y - broadB));
            highp float body = bodyA * 0.090 + bodyB * 0.065;

            highp float line0 = broadA - 0.036
                + sin(x * tau * 0.88 + phase * 0.18 + 0.20) * 0.018;
            highp float line1 = broadA - 0.023
                + sin(x * tau * 0.96 - phase * 0.16 + 1.05) * 0.021;
            highp float line2 = broadA - 0.011
                + sin(x * tau * 1.08 + phase * 0.21 + 2.10) * 0.017;
            highp float line3 = broadA
                + sin(x * tau * 1.18 - phase * 0.19 + 2.85) * 0.020;
            highp float line4 = broadB
                + sin(x * tau * 1.02 + phase * 0.17 + 3.55) * 0.019;
            highp float line5 = broadB + 0.013
                + sin(x * tau * 0.92 - phase * 0.20 + 4.15) * 0.022;
            highp float line6 = broadB + 0.026
                + sin(x * tau * 1.12 + phase * 0.15 + 5.00) * 0.018;
            highp float line7 = broadB + 0.039
                + sin(x * tau * 0.84 - phase * 0.18 + 5.72) * 0.020;

            highp float lines = 0.0;
            lines += strand(y, line0, 0.0010) * 0.110;
            lines += strand(y, line1, 0.0011) * 0.135;
            lines += strand(y, line2, 0.0012) * 0.155;
            lines += strand(y, line3, 0.0013) * 0.180;
            lines += strand(y, line4, 0.0013) * 0.165;
            lines += strand(y, line5, 0.0012) * 0.145;
            lines += strand(y, line6, 0.0011) * 0.125;
            lines += strand(y, line7, 0.0010) * 0.100;

            highp float edgeFade = smoothstep(0.0, 0.045, x)
                * (1.0 - smoothstep(0.955, 1.0, x));
            highp float alpha = (body + lines) * edgeFade * effectStrength;

            lowp vec3 palette = mix(colorA.rgb, colorB.rgb, smoothstep(0.02, 0.98, x));
            lowp vec3 tint = mix(palette, vec3(0.78, 0.91, 1.0), 0.52);
            tint = mix(tint, vec3(0.94, 0.98, 1.0), min(1.0, lines * 3.2));

            gl_FragColor = vec4(tint * alpha, alpha) * qt_Opacity;
        }
    "

    NumberAnimation on phase {
        from: 0.0
        to: Math.PI * 2.0
        duration: 36000
        running: root.visible && !root.reducedMotion
        loops: Animation.Infinite
    }
}
