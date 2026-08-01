import SwiftUI

struct TribunalVerdictOverlay: View {
    @Binding var verdicts: [TribunalVerdict]
    let onConfirm: ([TribunalVerdict]) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.tribunalAccent.opacity(0.8))

                    Text(L10n.TribunalVerdictOverlay.title)
                        .font(Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                }

                Text(L10n.TribunalVerdictOverlay.subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach($verdicts) { $verdict in
                            verdictRow($verdict)
                        }
                    }
                }
                .frame(maxHeight: 320)

                Button(action: { onConfirm(verdicts) }) {
                    Text(L10n.TribunalVerdictOverlay.confirmButton)
                        .font(Typography.label)
                        .foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .frame(maxWidth: 420)
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 0.5))
            .shadow(color: .black.opacity(0.6), radius: 40, y: 12)
            .onTapGesture {}
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func verdictRow(_ verdict: Binding<TribunalVerdict>) -> some View {
        let isFulfilled = verdict.wrappedValue.proposedStatus == .fulfilled

        return VStack(alignment: .leading, spacing: 8) {
            Text(verdict.wrappedValue.commitment.declarationText)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)

            if !verdict.wrappedValue.reasoning.isEmpty {
                Text(verdict.wrappedValue.reasoning)
                    .font(Theme.voiceFont)
                    .foregroundStyle(Theme.textSecondary)
            }

            statusToggle(verdict)
        }
        .padding(10)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFulfilled ? Theme.borderStrong : Theme.tribunalAccent.opacity(0.5), lineWidth: isFulfilled ? 0.5 : 1)
        )
    }

    private func statusToggle(_ verdict: Binding<TribunalVerdict>) -> some View {
        HStack(spacing: 8) {
            statusOption(L10n.TribunalVerdictOverlay.fulfilled, isBroken: false, isSelected: verdict.wrappedValue.proposedStatus == .fulfilled) {
                verdict.wrappedValue.proposedStatus = .fulfilled
            }
            statusOption(L10n.TribunalVerdictOverlay.broken, isBroken: true, isSelected: verdict.wrappedValue.proposedStatus == .broken) {
                verdict.wrappedValue.proposedStatus = .broken
            }
        }
    }

    private func statusOption(_ label: String, isBroken: Bool, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Text(label)
            .font(Typography.caption)
            .foregroundStyle(isSelected ? (isBroken ? Theme.tribunalAccent.opacity(0.9) : Theme.textPrimary) : Theme.textFaint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected && isBroken ? Theme.tribunalAccent.opacity(0.12) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? (isBroken ? Theme.tribunalAccent.opacity(0.5) : Theme.borderStrong) : Theme.border, lineWidth: 0.5)
            )
            .contentShape(Capsule())
            .onTapGesture(perform: onTap)
    }
}

extension L10n {
    enum TribunalVerdictOverlay {
        static var title: String {
            switch lang {
            case .en: return "The Tribunal's Verdicts"
            case .pl: return "Wyroki Trybunału"
            }
        }

        static var subtitle: String {
            switch lang {
            case .en: return "Review each verdict below. Override it if you disagree, then confirm to seal the record."
            case .pl: return "Przejrzyj poniższe wyroki. Zmień, jeśli się nie zgadzasz, a potem potwierdź, by zapieczętować rozliczenie."
            }
        }

        static var confirmButton: String {
            switch lang {
            case .en: return "Confirm and close the Tribunal"
            case .pl: return "Potwierdź i zamknij Trybunał"
            }
        }

        static var fulfilled: String {
            switch lang {
            case .en: return "Fulfilled"
            case .pl: return "Dotrzymano"
            }
        }

        static var broken: String {
            switch lang {
            case .en: return "Broken"
            case .pl: return "Złamano"
            }
        }
    }
}
