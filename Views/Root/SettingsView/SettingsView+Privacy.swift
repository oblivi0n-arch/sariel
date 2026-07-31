import SwiftUI

extension SettingsView {
    var privacySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "lock.shield", title: L10n.Settings.privacySectionTitle) {
                EmptyView()
            }

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
}
