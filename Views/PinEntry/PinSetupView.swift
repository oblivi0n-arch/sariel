import SwiftUI

struct PinSetupView: View {
    let onComplete: () -> Void
    let onCancel: () -> Void

    @State private var firstPin: String?
    @State private var errorMessage: String?
    @State private var isHoveringCancel = false

    var body: some View {
        VStack(spacing: 20) {
            PinEntryView(
                title: firstPin == nil ? L10n.Privacy.enterNewPin : L10n.Privacy.confirmNewPin,
                subtitle: errorMessage,
                onComplete: handleEntry
            )

            Button(L10n.Settings.cancelButton, action: onCancel)
                .buttonStyle(.plain)
                .foregroundStyle(isHoveringCancel ? Theme.textSecondary : Theme.textMuted)
                .trackHover($isHoveringCancel)
        }
    }

    private func handleEntry(_ pin: String) {
        guard let first = firstPin else {
            firstPin = pin
            errorMessage = nil
            return
        }

        if pin == first {
            _ = PinKeychainStore.savePinHash(pin)
            onComplete()
        } else {
            errorMessage = L10n.Privacy.pinMismatch
            firstPin = nil
        }
    }
}

extension L10n {
    enum Privacy {
        static var enterNewPin: String {
            switch L10n.lang {
            case .en: return "Enter new PIN"
            case .pl: return "Wpisz nowy PIN"
            }
        }

        static var confirmNewPin: String {
            switch L10n.lang {
            case .en: return "Confirm new PIN"
            case .pl: return "Powtórz nowy PIN"
            }
        }

        static var pinMismatch: String {
            switch L10n.lang {
            case .en: return "PINs didn't match. Try again."
            case .pl: return "PIN-y się nie zgadzają. Spróbuj ponownie."
            }
        }
    }
}
