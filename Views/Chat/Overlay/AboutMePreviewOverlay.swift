import SwiftUI

struct AboutMePreviewOverlay: View {
    let draftText: String
    let existingAboutMe: String
    let isRegenerating: Bool
    let onAccept: () -> Void
    let onRetry: () -> Void
    let onSkip: () -> Void
    
    @State private var isHoveringSkip = false
    
    private var trimmedExistingAboutMe: String {
        existingAboutMe.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.AboutMePreview.title)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)
                
                Text(L10n.AboutMePreview.subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
                
                if !trimmedExistingAboutMe.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.AboutMePreview.currentLabel)
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textFaint)
                        
                        ScrollView {
                            Text(trimmedExistingAboutMe)
                                .font(Typography.label)
                                .foregroundStyle(Theme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .frame(maxHeight: 70)
                        .background(Theme.fieldBackground.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                    }
                    
                    Text(L10n.AboutMePreview.draftLabel)
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textFaint)
                }
                
                ScrollView {
                    Text(draftText)
                        .font(Theme.uiFont)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .frame(maxHeight: 180)
                .background(Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                .opacity(isRegenerating ? 0.4 : 1)
                .overlay(alignment: .top) {
                    if isRegenerating {
                        PulsingLoadingBar()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                HStack(spacing: 10) {
                    Button(action: onAccept) {
                        Text(L10n.AboutMePreview.accept)
                            .font(Typography.label)
                            .foregroundStyle(Theme.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .hoverScale()
                    .disabled(isRegenerating)
                    
                    Button(action: onRetry) {
                        Text(L10n.AboutMePreview.retry)
                            .font(Typography.label)
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
                            .hoverBorder(cornerRadius: 8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRegenerating)
                }
                
                Button(action: onSkip) {
                    Text(L10n.AboutMePreview.skip)
                        .font(Typography.caption)
                        .foregroundStyle(isHoveringSkip ? Theme.textSecondary : Theme.textMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
                .trackHover($isHoveringSkip)
                .disabled(isRegenerating)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

extension L10n {
    enum AboutMePreview {
        static var title: String {
            switch lang {
            case .en: return "Here's what Sariel will remember"
            case .pl: return "Oto co Sariel zapamięta"
            }
        }
        
        static var subtitle: String {
            switch lang {
            case .en: return "Review it before it's saved to your profile."
            case .pl: return "Sprawdź, zanim zapiszemy to w Twoim profilu."
            }
        }
        
        static var currentLabel: String {
            switch lang {
            case .en: return "Currently saved"
            case .pl: return "Obecnie zapisane"
            }
        }
        
        static var draftLabel: String {
            switch lang {
            case .en: return "New proposal"
            case .pl: return "Nowa propozycja"
            }
        }
        
        static var accept: String {
            switch lang {
            case .en: return "Accept"
            case .pl: return "Akceptuj"
            }
        }
        
        static var retry: String {
            switch lang {
            case .en: return "Try again"
            case .pl: return "Spróbuj ponownie"
            }
        }
        
        static var skip: String {
            switch lang {
            case .en: return "Keep my previous about me"
            case .pl: return "Zachowaj poprzednie „o mnie”"
            }
        }
    }
}

#Preview("Pierwsza rozmowa (brak starego)") {
    AboutMePreviewOverlay(
        draftText: "Jest ambitną osobą, która często odkłada trudne rozmowy na później, tłumacząc to brakiem czasu. W ostatnich tygodniach pracuje nad projektem dyplomowym i przyznaje, że bywa dla siebie zbyt surowa.",
        existingAboutMe: "",
        isRegenerating: false,
        onAccept: {},
        onRetry: {},
        onSkip: {}
    )
    .frame(width: 500, height: 500)
    .background(Theme.background)
}

#Preview("Aktualizacja istniejącego") {
    AboutMePreviewOverlay(
        draftText: "Jest ambitną osobą, która ostatnio zaczęła częściej dotrzymywać deklaracji. Wciąż jednak unika trudnych rozmów, tłumacząc to brakiem czasu.",
        existingAboutMe: "Jest ambitną osobą, która często odkłada trudne rozmowy na później, tłumacząc to brakiem czasu.",
        isRegenerating: false,
        onAccept: {},
        onRetry: {},
        onSkip: {}
    )
    .frame(width: 500, height: 500)
    .background(Theme.background)
}

#Preview("Generowanie ponownie") {
    AboutMePreviewOverlay(
        draftText: "Jest ambitną osobą, która często odkłada trudne rozmowy na później, tłumacząc to brakiem czasu.",
        existingAboutMe: "Jest ambitną osobą, która często odkłada trudne rozmowy na później.",
        isRegenerating: true,
        onAccept: {},
        onRetry: {},
        onSkip: {}
    )
    .frame(width: 500, height: 500)
    .background(Theme.background)
}
