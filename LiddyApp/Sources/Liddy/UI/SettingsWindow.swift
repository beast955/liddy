import AppKit
import SwiftUI

/// The Settings window, owned by AppKit so any part of the app can open it.
@MainActor
final class SettingsWindow: NSObject, NSWindowDelegate {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    func show() {
        if window == nil {
            let host = NSHostingController(rootView: SettingsView().environment(AppModel.shared))
            let w = NSWindow(contentViewController: host)
            w.title = "Liddy"
            w.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            w.titlebarAppearsTransparent = true
            w.toolbarStyle = .unified
            w.appearance = NSAppearance(named: .darkAqua)
            w.backgroundColor = NSColor(calibratedRed: 0.025, green: 0.035, blue: 0.060, alpha: 1)
            w.setContentSize(NSSize(width: 1080, height: 760))
            w.contentMinSize = NSSize(width: 940, height: 660)
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            window = w
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
