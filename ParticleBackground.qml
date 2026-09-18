// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.15
import QtQuick.Particles 2.0

Item {
    id: root

    property bool reducedMotion: false
    property int preset: 0
    property real effectStrength: 1.0

    readonly property real unit: height / 720
    readonly property var colors: ["#91d8ff", "#99e7d2", "#f1c58c"]

    opacity: reducedMotion ? 0.0 : effectStrength * 0.48
    Behavior on opacity { NumberAnimation { duration: reducedMotion ? 0 : 450 } }

    ParticleSystem {
        id: particleSystem
        running: root.visible
        paused: root.reducedMotion
    }

    ImageParticle {
        system: particleSystem
        source: "assets/particle.svg"
        color: root.colors[root.preset % root.colors.length]
        colorVariation: 0.10
        alpha: 0.38
        alphaVariation: 0.34
        entryEffect: ImageParticle.Fade
    }

    Emitter {
        id: emitter
        x: 0
        y: root.height * 0.34
        width: root.width
        height: root.height * 0.43
        system: particleSystem
        emitRate: Math.min(13.0, Math.max(7.0, root.width / 170))
        lifeSpan: 24000
        lifeSpanVariation: 7000
        size: Math.max(1.0, 1.7 * root.unit)
        sizeVariation: Math.max(0.8, 2.8 * root.unit)

        velocity: AngleDirection {
            angle: 180
            angleVariation: 12
            magnitude: 5.5 * root.unit
            magnitudeVariation: 4.0 * root.unit
        }

        Component.onCompleted: if (!root.reducedMotion) burst(170)
    }

    Wander {
        anchors.fill: parent
        system: particleSystem
        xVariance: 10 * root.unit
        yVariance: 9 * root.unit
        pace: 7
    }

    onReducedMotionChanged: {
        if (!reducedMotion) emitter.burst(120)
    }
}
