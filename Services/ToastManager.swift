import Foundation
import Combine

@MainActor
final class ToastManager: ObservableObject {
    @Published var toasts: [Toast] = []

    func show(entry: JournalEntry) {
        show(kind: .journalEntrySaved(entry))
    }

    private func show(kind: ToastKind) {
        let toast = Toast(kind: kind)
        toasts.append(toast)

        Task {
            try? await Task.sleep(nanoseconds: UInt64(toast.duration * 1_000_000_000))
            dismiss(toast)
        }
    }

    func dismiss(_ toast: Toast) {
        toasts.removeAll { $0.id == toast.id }
    }
    
    func showDeclarationLimitBlocked() {
        show(kind: .declarationLimitBlocked)
    }
    
    func showDeclarationRequiresNewMessage() {
        show(kind: .declarationRequiresNewMessage)
    }
    
    func showAchievementUnlocked(_ kind: AchievementKind) {
        show(kind: .achievementUnlocked(kind))
    }
}
