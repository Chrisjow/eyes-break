import SwiftUI

struct BreakOverlayView: View {

    @ObservedObject var timerManager: TimerManager

    var body: some View {
        ZStack {
            // Semi-transparent dark tint on top of the blur provided by NSVisualEffectView
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Eye icon
                Image(systemName: "eye")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)

                // Title
                Text("Eye Break")
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                // Instruction
                Text("Look at something 20 feet away")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))

                // Countdown
                Text(formatCountdown(timerManager.breakTimeRemaining))
                    .font(.system(size: 80, weight: .thin, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: timerManager.breakTimeRemaining)
                    .padding(.top, 8)

                // Skip button
                Button {
                    timerManager.skipBreak()
                } label: {
                    Text("Skip Break")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 9)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let m = s / 60
        let rem = s % 60
        if m > 0 {
            return String(format: "%d:%02d", m, rem)
        }
        return String(format: "0:%02d", rem)
    }
}
