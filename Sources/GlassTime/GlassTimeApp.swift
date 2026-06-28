import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // First pass — windows may already exist
        makeWindowsTransparent()

        // Second pass after 200 ms — SwiftUI sometimes creates/resizes windows
        // after the launch notification, which resets opacity
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            makeWindowsTransparent()
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func makeWindowsTransparent() {
        for window in NSApplication.shared.windows {
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.hasShadow = true

            // The SwiftUI NSHostingView also needs a transparent layer —
            // without this the hosting view renders an opaque background
            // that blocks the NSVisualEffectView behind it.
            if let contentView = window.contentView {
                contentView.wantsLayer = true
                contentView.layer?.backgroundColor = CGColor.clear
            }
        }
    }
}

@main
struct GlassTimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        // .contentMinSize lets the window grow past the content's minimum size
        // (up to the full screen) while the ContentView scales to fill it.
        .windowResizability(.contentMinSize)
        .defaultSize(width: 420, height: 580)
        .windowBackgroundDragBehavior(.enabled)
    }
}
