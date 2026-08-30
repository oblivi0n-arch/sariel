import SwiftUI

struct PinUnlockView: View {
    var title: String = L10n.Privacy.unlockTitle
    var showsBackground: Bool = true
    let onUnlock: () -> Void
    
    @AppStorage("appLockUseBiometrics") private var useBiometrics: Bool = true
    @State private var errorMessage: String?
    @State private var isAttemptingBiometrics = false
    @State private var isHoveringTouchID = false
    @State private var remainingLockout: TimeInterval = 0
    
    private var isLockedOut: Bool { remainingLockout > 0 }
    
    var body: some View {
        ZStack {
            if showsBackground {
                Theme.background.ignoresSafeArea()
            }
            
            VStack(spacing: 20) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.textMuted)
                
                if isLockedOut {
                    VStack(spacing: 6) {
                        Text(L10n.Privacy.lockedOutTitle)
                            .font(Typography.subsectionTitle)
                            .foregroundStyle(Theme.textPrimary)
                        
                        Text(L10n.Privacy.lockedOutSubtitle(remaining: remainingLockout))
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textFaint)
                            .monospacedDigit()
                    }
                } else {
                    PinEntryView(
                        title: title,
                        subtitle: errorMessage,
                        onComplete: handlePinEntry
                    )
                }
                
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
        .task {
            while !Task.isCancelled {
                remainingLockout = PinAttemptStore.remainingLockout
                try? await Task.sleep(for: .seconds(1))
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
                PinAttemptStore.reset()
                onUnlock()
            }
        }
    }
    
    private func handlePinEntry(_ pin: String) {
        guard !isLockedOut else { return }
        
        if PinKeychainStore.verifyPin(pin) {
            PinAttemptStore.reset()
            errorMessage = nil
            onUnlock()
        } else {
            PinAttemptStore.recordFailure()
            remainingLockout = PinAttemptStore.remainingLockout
            errorMessage = isLockedOut ? nil : L10n.Privacy.wrongPin
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
    
    static var lockedOutTitle: String {
        switch L10n.lang {
        case .en: return "Too many attempts"
        case .pl: return "Za dużo prób"
        }
    }
    
    static func lockedOutSubtitle(remaining: TimeInterval) -> String {
        let total = Int(remaining.rounded(.up))
        let time = String(format: "%d:%02d", total / 60, total % 60)
        switch L10n.lang {
        case .en: return "Try again in \(time)"
        case .pl: return "Spróbuj ponownie za \(time)"
        }
    }
}
