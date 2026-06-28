import SwiftUI

struct DigitalClockView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            DigitalFace(date: timeline.date)
        }
    }
}

private struct DigitalFace: View {
    let date: Date

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d. MMMM"
        f.locale = Locale(identifier: "de_DE")
        return f
    }()

    var body: some View {
        VStack(spacing: 5) {
            Text(Self.timeFormatter.string(from: date))
                .font(.system(size: 38, weight: .thin, design: .monospaced))
                .foregroundStyle(.white.opacity(0.92))
                .monospacedDigit()

            Text(Self.dateFormatter.string(from: date))
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .kerning(0.5)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .frame(width: 288)
    }
}
