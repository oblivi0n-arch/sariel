import SwiftUI

struct BurnHoldButton: View {
    let onCommitted: () -> Void

    @State private var holdProgress: Double = 0
    @State private var holdTask: Task<Void, Never>?
    @State private var isPastPointOfNoReturn = false

    private let pointOfNoReturn: Double = 0.7
    private let fillDuration: Double = 1.4

    var body: some View {
        Text(isPastPointOfNoReturn ? "burning" : "hold to burn")
            .font(Typography.label)
            .foregroundStyle(Color.red.opacity(0.9))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(alignment: .leading) {
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.red.opacity(0.25))
                        .frame(width: geo.size.width * holdProgress)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.5), lineWidth: isPastPointOfNoReturn ? 1.5 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(isPastPointOfNoReturn ? 1.03 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isPastPointOfNoReturn)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in startHoldingIfNeeded() }
                    .onEnded { _ in releaseIfBeforePointOfNoReturn() }
            )
    }

    private func startHoldingIfNeeded() {
        guard holdTask == nil else { return }

        holdTask = Task {
            let tickInterval: UInt64 = 16_000_000
            let increment = 1.0 / (fillDuration * 1000 / 16)

            while !Task.isCancelled, holdProgress < 1.0 {
                try? await Task.sleep(nanoseconds: tickInterval)
                guard !Task.isCancelled else { return }

                holdProgress = min(1.0, holdProgress + increment)

                if holdProgress >= pointOfNoReturn, !isPastPointOfNoReturn {
                    isPastPointOfNoReturn = true
                }
            }

            guard !Task.isCancelled else { return }
            onCommitted()
        }
    }

    private func releaseIfBeforePointOfNoReturn() {
        guard !isPastPointOfNoReturn else { return }

        holdTask?.cancel()
        holdTask = nil
        withAnimation(.easeOut(duration: 0.25)) {
            holdProgress = 0
        }
    }
}
