import AppKit
import SwiftUI

// A behind-window NSVisualEffectView — the ONLY way to show whatever is behind
// the *window* (desktop, other apps' windows, text) through a region. SwiftUI's
// `.glassEffect` only frosts in-app content, so it can't do this. `.behindWindow`
// blending samples the live backdrop and frosts it; `.underWindowBackground` is
// Apple's most transparent material, so the content behind stays clearly visible.
struct BehindWindowGlass: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = .behindWindow
        nsView.state = .active
    }
}

// Styles any shape as a Liquid-Glass surface: the behind-window frost keeps the
// content behind the window showing through, while a faint white tint + a top
// sheen + a bright top edge (fading downward) give it the specular highlights
// that read as "glass" even over a dark or empty background.
struct LiquidGlassSurface<S: InsettableShape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    BehindWindowGlass()
                        .clipShape(shape)

                    // Just a faint frost tint so it reads as glass (not a hole)
                    // over dark grounds — no broad sheen gradient, which looked
                    // artificial over real wallpapers.
                    shape.fill(.white.opacity(0.05))
                }
            }
            .overlay {
                // Subtle glass rim: a soft top highlight fading to almost nothing
                // at the bottom — the edge that makes it look like glass.
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.35),
                            .white.opacity(0.10),
                            .white.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
    }
}

extension View {
    func liquidGlass<S: InsettableShape>(in shape: S) -> some View {
        modifier(LiquidGlassSurface(shape: shape))
    }
}

// Reaches up to the hosting NSWindow and forces it fully transparent on EVERY
// SwiftUI update. This is the crucial bit: SwiftUI's WindowGroup keeps resetting
// `isOpaque`/`backgroundColor` back to opaque after launch (first render, resize,
// focus changes). A one-shot fix in the AppDelegate races against that and loses,
// which is why the window only looked "barely" transparent. Running on every
// `updateNSView` wins the race permanently, so the desktop shows straight through.
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.hasShadow = true

        // Let the SwiftUI content draw all the way up behind the title bar /
        // traffic lights, otherwise the title-bar strip stays transparent and
        // shows the desktop instead of the opaque panel.
        window.styleMask.insert(.fullSizeContentView)
        window.titleVisibility = .hidden

        // With a fully transparent fill there's no opaque view to "catch" drags,
        // so SwiftUI's windowBackgroundDragBehavior stops working. Enable the
        // AppKit-level move-by-background, which drags the window from anywhere
        // on its content regardless of what's painted.
        window.isMovableByWindowBackground = true

        // Kill any opaque backing the SwiftUI hosting view may have painted.
        if let contentView = window.contentView {
            contentView.wantsLayer = true
            contentView.layer?.backgroundColor = .clear
        }
    }
}
