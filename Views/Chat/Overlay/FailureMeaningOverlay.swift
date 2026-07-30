import SwiftUI

struct FailureMeaningOverlay: View {
    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    @State private var answer: String = ""
    @FocusState private var isFocused: Bool

    private var hasAnswer: Bool {
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func submit() {
        onSubmit(answer.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onCancel)

            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.FailureMeaning.question)
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

                Text(L10n.FailureMeaning.subtitle)
                    .font(Typography.label)
                    .foregroundStyle(Theme.textMuted)

                TextField(L10n.FailureMeaning.placeholder, text: $answer, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Theme.uiFont)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.red.opacity(0.45), lineWidth: 1)
                    )
                    .focused($isFocused)
                    .lineLimit(1...4)
                    .onKeyPress(phases: .down) { press in
                        guard press.key == .return else { return .ignored }
                        submit()
                        return .handled
                    }

                HStack {
                    Button(L10n.FailureMeaning.cancel, role: .cancel, action: onCancel)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textMuted)
                        .buttonStyle(.plain)
                        .hoverScale()

                    Spacer()

                    Button(hasAnswer ? L10n.FailureMeaning.sealIt : L10n.FailureMeaning.skip, action: submit)
                        .font(Typography.subsectionTitle)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.85))
                        .clipShape(Capsule())
                        .buttonStyle(.plain)
                        .hoverScale()
                }
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
            .onTapGesture {}
            .onAppear { isFocused = true }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

extension L10n {
    enum FailureMeaning {
        static var question: String {
            switch lang {
            case .en: return "What would it mean about you if you failed?"
            case .pl: return "Co by to oznaczało o Tobie, gdybyś zawiódł?"
            }
        }

        static var subtitle: String {
            switch lang {
            case .en: return "Before this is sealed. Answer honestly — you'll be shown this again if you break it."
            case .pl: return "Zanim to zostanie zapieczętowane. Odpowiedz szczerze — zobaczysz to ponownie, jeśli złamiesz obietnicę."
            }
        }

        static var placeholder: String {
            switch lang {
            case .en: return "It would mean..."
            case .pl: return "Oznaczałoby to..."
            }
        }

        static var cancel: String {
            switch lang {
            case .en: return "cancel"
            case .pl: return "anuluj"
            }
        }

        static var sealIt: String {
            switch lang {
            case .en: return "seal it"
            case .pl: return "zapieczętuj"
            }
        }
        
        static var skip: String {
            switch lang {
            case .en: return "skip"
            case .pl: return "pomiń"
            }
        }
    }
}
