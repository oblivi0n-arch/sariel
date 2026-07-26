import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataTransferAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

extension SettingsView {
    var dataTransferSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "arrow.up.arrow.down.square", title: L10n.Settings.dataTransferTitle) {
                EmptyView()
            }

            HStack(spacing: 10) {
                Button(action: exportData) {
                    Text(L10n.Settings.exportButton)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: { showImportPanel() }) {
                    Text(L10n.Settings.importButton)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Text(L10n.Settings.dataTransferDescription)
                .font(Typography.caption)
                .foregroundStyle(Theme.textFaint)
        }
        .confirmationDialog(
            L10n.Settings.importConfirmTitle,
            isPresented: $showImportConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.Settings.importConfirmButton, role: .destructive) {
                performImport()
            }
            Button(L10n.Settings.cancelButton, role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text(L10n.Settings.importConfirmMessage)
        }
        .alert(item: $dataTransferAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func exportData() {
        do {
            let export = try DataExportService.exportAllData(modelContext: modelContext)
            let data = try DataExportService.encodeToJSON(export)
            guard let url = DataExportService.presentSavePanel() else { return }
            try data.write(to: url)
            dataTransferAlert = DataTransferAlert(
                title: L10n.Settings.exportSuccessTitle,
                message: L10n.Settings.exportSuccessMessage
            )
        } catch {
            dataTransferAlert = DataTransferAlert(
                title: L10n.Settings.exportErrorTitle,
                message: error.localizedDescription
            )
        }
    }

    func showImportPanel() {
        guard let url = DataExportService.presentOpenPanel() else { return }
        pendingImportURL = url
        showImportConfirmation = true
    }

    func performImport() {
        guard let url = pendingImportURL else { return }
        pendingImportURL = nil
        do {
            let data = try Data(contentsOf: url)
            let export = try DataExportService.decodeFromJSON(data)
            try DataExportService.importAllData(export, modelContext: modelContext)
            dataTransferAlert = DataTransferAlert(
                title: L10n.Settings.importSuccessTitle,
                message: L10n.Settings.importSuccessMessage
            )
        } catch {
            dataTransferAlert = DataTransferAlert(
                title: L10n.Settings.importErrorTitle,
                message: error.localizedDescription
            )
        }
    }
}

extension L10n.Settings {
    static var dataTransferTitle: String {
        switch L10n.lang {
        case .en: return "DATA"
        case .pl: return "DANE"
        }
    }

    static var exportButton: String {
        switch L10n.lang {
        case .en: return "Export"
        case .pl: return "Eksportuj"
        }
    }

    static var importButton: String {
        switch L10n.lang {
        case .en: return "Import"
        case .pl: return "Importuj"
        }
    }

    static var dataTransferDescription: String {
        switch L10n.lang {
        case .en: return "Export all your data to a JSON file, or import a previously exported file. Importing replaces everything currently in the app."
        case .pl: return "Wyeksportuj wszystkie swoje dane do pliku JSON albo zaimportuj wcześniej wyeksportowany plik. Import zastępuje wszystkie dane obecnie znajdujące się w aplikacji."
        }
    }

    static var exportPanelTitle: String {
        switch L10n.lang {
        case .en: return "Export Sariel Data"
        case .pl: return "Eksportuj dane Sariel"
        }
    }

    static var importPanelTitle: String {
        switch L10n.lang {
        case .en: return "Import Sariel Data"
        case .pl: return "Importuj dane Sariel"
        }
    }

    static var exportSuccessTitle: String {
        switch L10n.lang {
        case .en: return "Export complete"
        case .pl: return "Eksport zakończony"
        }
    }

    static var exportSuccessMessage: String {
        switch L10n.lang {
        case .en: return "Your data was saved successfully."
        case .pl: return "Twoje dane zostały pomyślnie zapisane."
        }
    }

    static var exportErrorTitle: String {
        switch L10n.lang {
        case .en: return "Export failed"
        case .pl: return "Eksport nieudany"
        }
    }

    static var importSuccessTitle: String {
        switch L10n.lang {
        case .en: return "Import complete"
        case .pl: return "Import zakończony"
        }
    }

    static var importSuccessMessage: String {
        switch L10n.lang {
        case .en: return "Your data was imported successfully."
        case .pl: return "Twoje dane zostały pomyślnie zaimportowane."
        }
    }

    static var importErrorTitle: String {
        switch L10n.lang {
        case .en: return "Import failed"
        case .pl: return "Import nieudany"
        }
    }

    static var importConfirmTitle: String {
        switch L10n.lang {
        case .en: return "Import data?"
        case .pl: return "Zaimportować dane?"
        }
    }

    static var importConfirmButton: String {
        switch L10n.lang {
        case .en: return "Import and replace everything"
        case .pl: return "Importuj i zastąp wszystko"
        }
    }

    static var importConfirmMessage: String {
        switch L10n.lang {
        case .en: return "This will permanently delete everything currently in the app and replace it with the contents of the selected file. This cannot be undone."
        case .pl: return "Ta operacja bezpowrotnie usunie wszystko, co obecnie znajduje się w aplikacji, i zastąpi to zawartością wybranego pliku. Tej operacji nie da się cofnąć."
        }
    }
}
