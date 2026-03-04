import AppKit

// Manual entry point — required for SwiftPM executables using AppKit
// (Cannot use @main with NSApplicationDelegate in a SwiftPM executable target)
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
