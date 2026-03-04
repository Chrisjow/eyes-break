import SwiftUI
import AppKit

struct SettingsView: View {

    @ObservedObject var settings: SettingsManager
    @ObservedObject var timerManager: TimerManager

    @State private var showResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Break interval
            SettingRow(label: "Break every", icon: "clock", unit: "min") {
                NumberStepperField(
                    value: $settings.breakInterval,
                    range: 1...120,
                    step: 1
                )
            }

            // Break duration
            SettingRow(label: "Break lasts", icon: "timer", unit: "sec") {
                NumberStepperField(
                    value: $settings.breakDuration,
                    range: 5...300,
                    step: 5
                )
            }

            Divider()

            // Apply button
            HStack {
                Spacer()
                Button("Apply & Reset Timer") {
                    // Resign first responder synchronously so any focused text field
                    // commits its current value before resetInterval() reads it.
                    NSApp.keyWindow?.makeFirstResponder(nil)
                    timerManager.resetInterval()
                    showResetConfirmation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showResetConfirmation = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                if showResetConfirmation {
                    Label("Timer reset!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                        .transition(.opacity)
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.2), value: showResetConfirmation)
        }
        .padding(24)
        .frame(width: 340)
    }
}

// MARK: - SettingRow

/// A label on the left, a control + unit label on the right.
private struct SettingRow<Control: View>: View {
    let label: String
    let icon: String
    let unit: String
    @ViewBuilder let control: () -> Control

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .frame(width: 130, alignment: .leading)
            Spacer()
            control()
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(width: 26, alignment: .leading)
        }
    }
}

// MARK: - NumberStepperField

/// A numeric text field + stepper arrows. Uses NSViewRepresentable so that
/// `controlTextDidEndEditing` fires reliably on ANY focus change on macOS —
/// unlike SwiftUI's @FocusState which misses many cases (clicking another
/// window, pressing Tab, clicking the Apply button, etc.).
private struct NumberStepperField: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    @State private var text: String = ""

    var body: some View {
        HStack(spacing: 4) {
            CommitTextField(text: $text, onCommit: commit)
                .frame(width: 46, height: 21)
                .onAppear { text = formatted(value) }

            Stepper("", value: $value, in: range, step: step)
                .labelsHidden()
                // onChange on the Stepper itself fires reliably when arrows are clicked
                .onChange(of: value) { newValue in
                    text = formatted(newValue)
                }
        }
    }

    private func commit() {
        let parsed = Double(text.trimmingCharacters(in: .whitespaces)) ?? value
        let clamped = min(range.upperBound, max(range.lowerBound, parsed))
        let stepped = (clamped / step).rounded() * step
        value = min(range.upperBound, max(range.lowerBound, stepped))
        text = formatted(value)
    }

    private func formatted(_ v: Double) -> String { String(Int(v)) }
}

// MARK: - CommitTextField

/// NSTextField wrapper that calls `onCommit` on Return key AND on any focus loss.
/// This is more reliable than SwiftUI's TextField + @FocusState on macOS.
private struct CommitTextField: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.delegate = context.coordinator
        field.alignment = .right
        field.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        field.bezelStyle = .squareBezel
        field.isBordered = true
        field.isBezeled = true
        field.isEditable = true
        field.isSelectable = true
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // controlTextDidChange keeps `text` in sync with user keystrokes, so
        // nsView.stringValue == text while editing. The check avoids a no-op
        // write; it is safe to always update when they differ.
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: CommitTextField
        init(_ parent: CommitTextField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        // Fires when focus leaves the field for any reason (Return, Tab, click elsewhere)
        func controlTextDidEndEditing(_ obj: Notification) {
            parent.onCommit()
        }
    }
}
