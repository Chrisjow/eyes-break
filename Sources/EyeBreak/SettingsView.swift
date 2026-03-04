import SwiftUI

struct SettingsView: View {

    @ObservedObject var settings: SettingsManager
    @ObservedObject var timerManager: TimerManager

    @State private var showResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // Break interval
            HStack {
                Label("Break every", systemImage: "clock")
                    .frame(width: 130, alignment: .leading)
                Stepper(
                    value: $settings.breakInterval,
                    in: 1...120,
                    step: 1
                ) {
                    Text("\(Int(settings.breakInterval)) min")
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }
            }

            // Break duration
            HStack {
                Label("Break lasts", systemImage: "timer")
                    .frame(width: 130, alignment: .leading)
                Stepper(
                    value: $settings.breakDuration,
                    in: 5...300,
                    step: 5
                ) {
                    Text("\(Int(settings.breakDuration)) sec")
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }
            }

            Divider()

            // Apply button
            HStack {
                Spacer()
                Button("Apply & Reset Timer") {
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
        .frame(width: 320)
    }
}
