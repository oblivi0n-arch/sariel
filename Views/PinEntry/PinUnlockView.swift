import SwiftUI

struct PinUnlockView: View {
    var title: String = L10n.Privacy.unlockTitle
    let onUnlock: () -> Void

    @AppStorage("appLockUseBiometrics") private var useBiometrics: Bool = true
    @State private var errorMessage: String?
    @State private var isAttemptingBiometrics = false
    @State private var isHoveringTouchID = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.textMuted)

                PinEntryView(
                    title: title,
                    subtitle: errorMessage,
                    onComplete: handlePinEntry
                )

                if useBiometrics && BiometricAuth.isAvailable {
                    Button(action: attemptBiometrics) {
                        Label(L10n.Privacy.useTouchID, systemImage: "touchid")
                            .font(Typography.label)
                            .foregroundStyle(isHoveringTouchID ? Theme.textSecondary : Theme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .trackHover($isHoveringTouchID)
                }
            }
        }
        .task {
            if useBiometrics && BiometricAuth.isAvailable {
                attemptBiometrics()
            }
        }
    }

    private func attemptBiometrics() {
        guard !isAttemptingBiometrics else { return }
        isAttemptingBiometrics = true

        Task {
            let success = await BiometricAuth.authenticate(reason: L10n.Privacy.unlockReason)
            isAttemptingBiometrics = false
            if success {
                onUnlock()
            }
        }
    }

    private func handlePinEntry(_ pin: String) {
        if PinKeychainStore.verifyPin(pin) {
            onUnlock()
        } else {
            errorMessage = L10n.Privacy.wrongPin
        }
    }
}

extension L10n.Privacy {
    static var unlockTitle: String {
        switch L10n.lang {
        case .en: return "Enter your PIN"
        case .pl: return "Wpisz swój PIN"
        }
    }
    
    static var confirmCurrentPin: String {
        switch L10n.lang {
        case .en: return "Confirm your current PIN"
        case .pl: return "Potwierdź obecny PIN"
        }
    }

    static var useTouchID: String {
        switch L10n.lang {
        case .en: return "Use Touch ID"
        case .pl: return "Użyj Touch ID"
        }
    }

    static var unlockReason: String {
        switch L10n.lang {
        case .en: return "Unlock Sariel"
        case .pl: return "Odblokuj Sariel"
        }
    }

    static var wrongPin: String {
        switch L10n.lang {
        case .en: return "Wrong PIN. Try again."
        case .pl: return "Nieprawidłowy PIN. Spróbuj ponownie."
        }
    }
}
