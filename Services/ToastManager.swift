import Foundation
import Combine

@MainActor
final class ToastManager: ObservableObject {
    @Published var toasts: [Toast] = []

    func show(entry: JournalEntry) {
        let toast = Toast(entry: entry)
        toasts.append(toast)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            dismiss(toast)
        }
    }

    func dismiss(_ toast: Toast) {
        toasts.removeAll { $0.id == toast.id }
    }
}

