import AppKit
import SwiftUI

/// A borderless, full-screen window that sits above all other content (including the Dock
/// and menu bar) to present the eye-break overlay. One instance is created per screen.
final class BreakOverlayWindow: NSWindow {

    init(screen: NSScreen, timerManager: TimerManager) {
        // Use the full screen frame (includes menu bar area)
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        // Place above the screen saver so nothing shows through
        level = .screenSaver

        // Appear in every Space and alongside fullscreen apps
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        isOpaque = false
        backgroundColor = .clear
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        ignoresMouseEvents = false

        setupContent(timerManager: timerManager, screenSize: screen.frame.size)
    }

    private func setupContent(timerManager: TimerManager, screenSize: NSSize) {
        let bounds = NSRect(origin: .zero, size: screenSize)

        // NSVisualEffectView provides the frosted-glass blur behind our overlay
        let blur = NSVisualEffectView(frame: bounds)
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.material = .fullScreenUI
        blur.autoresizingMask = [.width, .height]

        // SwiftUI overlay with countdown and skip button
        let overlayView = BreakOverlayView(timerManager: timerManager)
        let hosting = NSHostingView(rootView: overlayView)
        hosting.frame = bounds
        hosting.autoresizingMask = [.width, .height]

        blur.addSubview(hosting)
        contentView = blur
    }

    // Must be true so the window can receive keyboard/mouse events for the Skip button
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
