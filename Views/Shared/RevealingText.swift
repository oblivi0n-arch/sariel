import SwiftUI

struct RevealingText: View {
    let fullText: String
    let font: Font
    let color: Color
    var charsPerSecond: Double = 40
    var onComplete: (() -> Void)? = nil
    var skipRequested: Binding<Bool> = .constant(false)

    @State private var revealedCount: Int = 0
    @State private var revealTask: Task<Void, Never>?

    var body: some View {
        Text(String(fullText.prefix(revealedCount)))
            .font(font)
            .foregroundStyle(color)
            .onAppear { startRevealing() }
            .onDisappear { revealTask?.cancel() }
            .onChange(of: skipRequested.wrappedValue) { _, newValue in
                if newValue { skipToEnd() }
            }
    }

    private func startRevealing() {
        revealTask?.cancel()
        revealedCount = 0

        revealTask = Task {
            for index in fullText.indices {
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / charsPerSecond))
                guard !Task.isCancelled else { return }
                revealedCount = fullText.distance(from: fullText.startIndex, to: index) + 1
            }
            guard !Task.isCancelled else { return }
            onComplete?()
        }
    }

    private func skipToEnd() {
        guard revealedCount < fullText.count else { return }
        revealTask?.cancel()
        revealedCount = fullText.count
        onComplete?()
    }
}
