import SwiftUI

enum PendingPinAction {
    case change
    case remove
}

extension SettingsView {
    var privacySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "lock.shield", title: L10n.Settings.privacySectionTitle) {
                EmptyView()
            }
            
            appLockRow
            
            Divider().overlay(Theme.border).padding(.vertical, 4)
            
            autoDeleteRow
        }
    }
    
    private var appLockRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $appLockEnabled) {
                Text(L10n.Settings.appLockToggle)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(Theme.textPrimary)
            .disabled(!hasPinSet)
            
            if BiometricAuth.isAvailable {
                Toggle(isOn: $appLockUseBiometrics) {
                    Text(L10n.Settings.appLockBiometricsToggle)
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textPrimary)
                }
                .toggleStyle(.switch)
                .tint(Theme.textPrimary)
                .disabled(!appLockEnabled)
            }
            
            HStack(spacing: 10) {
                Button(action: {
                    if hasPinSet {
                        pendingPinAction = .change
                    } else {
                        isPinSetupShown = true
                    }
                }) {
                    Text(hasPinSet ? L10n.Settings.changePinButton : L10n.Settings.setPinButton)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Theme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                if hasPinSet {
                    Button(action: { pendingPinAction = .remove }) {
                        Text(L10n.Settings.removePinButton)
                            .font(Typography.label)
                            .foregroundStyle(Color.red.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(hasPinSet ? L10n.Settings.appLockDescription : L10n.Settings.appLockNoPinDescription)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }
    
    private var autoDeleteRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $autoDeleteEnabled) {
                Text(L10n.Settings.autoDeleteToggle)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
            }
            .toggleStyle(.switch)
            .tint(Theme.textPrimary)
            
            if autoDeleteEnabled {
                Picker(L10n.Settings.autoDeleteThresholdLabel, selection: $autoDeleteThresholdDays) {
                    ForEach(AppLimits.autoDeleteThresholdOptions, id: \.self) { days in
                        Text(L10n.Settings.autoDeleteThresholdOption(days: days))
                            .tag(days)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Text(L10n.Settings.autoDeleteDescription)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }
    
    private func removePin() {
        PinKeychainStore.removePin()
        appLockEnabled = false
        hasPinSet = false
    }
    
    @ViewBuilder
    var pinVerificationOverlayContent: some View {
        if let action = pendingPinAction {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { pendingPinAction = nil }
            
            PinUnlockView(title: L10n.Privacy.confirmCurrentPin) {
                pendingPinAction = nil
                switch action {
                case .change:
                    isPinSetupShown = true
                case .remove:
                    removePin()
                }
            }
            .padding(24)
            .frame(width: 280)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
        }
    }
}

extension L10n.Settings {
    static var privacySectionTitle: String {
        switch L10n.lang {
        case .en: return "PRIVACY"
        case .pl: return "PRYWATNOŚĆ"
        }
    }
    
    static var autoDeleteToggle: String {
        switch L10n.lang {
        case .en: return "Auto-delete after inactivity"
        case .pl: return "Auto-usuwanie po nieaktywności"
        }
    }
    
    static var autoDeleteThresholdLabel: String {
        switch L10n.lang {
        case .en: return "After"
        case .pl: return "Po"
        }
    }
    
    static func autoDeleteThresholdOption(days: Int) -> String {
        switch L10n.lang {
        case .en: return "\(days) days"
        case .pl: return "\(days) dniach"
        }
    }
    
    static var autoDeleteDescription: String {
        switch L10n.lang {
        case .en: return "If Sariel isn't opened for this long, all data and settings are permanently wiped, as if reset from scratch."
        case .pl: return "Jeśli Sariel nie zostanie otwarty przez tak długi czas, wszystkie dane i ustawienia zostaną trwale usunięte, tak jakby zresetowano aplikację od nowa."
        }
    }
    
    static var appLockToggle: String {
        switch L10n.lang {
        case .en: return "Lock app with PIN"
        case .pl: return "Zablokuj aplikację PIN-em"
        }
    }
    
    static var appLockBiometricsToggle: String {
        switch L10n.lang {
        case .en: return "Allow Touch ID"
        case .pl: return "Zezwól na Touch ID"
        }
    }
    
    static var setPinButton: String {
        switch L10n.lang {
        case .en: return "Set PIN"
        case .pl: return "Ustaw PIN"
        }
    }
    
    static var changePinButton: String {
        switch L10n.lang {
        case .en: return "Change PIN"
        case .pl: return "Zmień PIN"
        }
    }
    
    static var removePinButton: String {
        switch L10n.lang {
        case .en: return "Remove PIN"
        case .pl: return "Usuń PIN"
        }
    }
    
    static var appLockDescription: String {
        switch L10n.lang {
        case .en: return "Sariel will ask for your PIN or Touch ID each time the app starts."
        case .pl: return "Sariel będzie prosić o Twój PIN lub Touch ID przy każdym uruchomieniu aplikacji."
        }
    }
    
    static var appLockNoPinDescription: String {
        switch L10n.lang {
        case .en: return "Set a PIN to enable locking the app on launch."
        case .pl: return "Ustaw PIN, żeby móc włączyć blokadę aplikacji przy starcie."
        }
    }
}
