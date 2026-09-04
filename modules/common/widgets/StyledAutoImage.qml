import QtQuick
import qs.modules.common
import qs.modules.common.widgets

/**
 * An image that actually moves when the file is an animated one.
 *
 * QML's Image decodes a single frame, so a GIF renders its first frame and
 * then sits there. AnimatedImage plays them, but it has none of StyledImage's
 * fallback chain or load fade-in, so neither type is right on its own: this
 * picks whichever the source needs and keeps one set of properties for both.
 */
Item {
    id: root

    property string source: ""
    property int fillMode: Image.PreserveAspectCrop
    property bool antialiasing: true
    // Follows Image semantics, so it defaults on. Worth turning off for an
    // animation: it selects QMovie's cache mode, and caching every decoded
    // frame of a 498x498 53-frame GIF measured ~20MB of resident memory.
    property bool cache: true
    property bool playing: true
    // Static path only. An animated source has no second chance to fall back to.
    property list<string> fallbacks: []

    // Extensions Qt can actually animate here: libqgif and libqwebp do, and
    // libqmng is installed. APNG is left out deliberately -- Qt's PNG handler
    // does not animate it, so routing it here would only cost it the fallbacks.
    // Query and fragment are dropped first so a source carrying them still matches.
    readonly property bool animated: /\.(gif|webp|mng)$/i.test(root.source.replace(/[?#].*$/, ""))

    // Decode size for the animated path. Decoding near display size instead of
    // the file's native size measured ~19MB lower on a 498x498 GIF, but every
    // change rebuilds the movie, so it is snapped to a coarse step: a
    // drag-resize then costs one rebuild per step crossed rather than one per
    // frame of the resize animation. Rounding up leaves headroom so a cropped
    // axis is not upscaled.
    readonly property int decodeSize: Math.max(64, Math.ceil(Math.max(root.width, root.height) / 64) * 64)

    Loader {
        anchors.fill: parent
        sourceComponent: root.animated ? animatedComponent : staticComponent
    }

    Component {
        id: staticComponent
        StyledImage {
            source: root.source
            fillMode: root.fillMode
            antialiasing: root.antialiasing
            cache: root.cache
            fallbacks: root.fallbacks
            sourceSize.width: root.width
            sourceSize.height: root.height
        }
    }

    Component {
        id: animatedComponent
        AnimatedImage {
            source: root.source
            fillMode: root.fillMode
            antialiasing: root.antialiasing
            asynchronous: true
            cache: root.cache
            // Frames only need to advance while something can see them, and an
            // invisible widget that keeps decoding is pure waste. `visible` is
            // the effective one, so a hidden ancestor stops it too.
            playing: root.playing && root.visible
            sourceSize.width: root.decodeSize
            sourceSize.height: root.decodeSize

            // Match the static path's load fade instead of popping in.
            opacity: (status === Image.Ready) ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
        }
    }
}
