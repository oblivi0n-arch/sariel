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
                        .foregroundStyle(Color.red.opacity(0.8))

                    Text("The Tribunal's Verdicts")
                        .font(Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                }

                Text("Review each verdict below. Override it if you disagree, then confirm to seal the record.")
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
                    Text("Confirm and close the Tribunal")
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
        .background(Theme.background)          // było: Theme.fieldBackground
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFulfilled ? Theme.borderStrong : Color.red.opacity(0.5), lineWidth: isFulfilled ? 0.5 : 1)
                // było: Theme.border zamiast Theme.borderStrong
        )
    }

    private func statusToggle(_ verdict: Binding<TribunalVerdict>) -> some View {
        HStack(spacing: 8) {
            statusOption("Fulfilled", isSelected: verdict.wrappedValue.proposedStatus == .fulfilled) {
                verdict.wrappedValue.proposedStatus = .fulfilled
            }
            statusOption("Broken", isSelected: verdict.wrappedValue.proposedStatus == .broken) {
                verdict.wrappedValue.proposedStatus = .broken
            }
        }
    }

    private func statusOption(_ label: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        let isBroken = label == "Broken"

        return Text(label)
            .font(Typography.caption)
            .foregroundStyle(isSelected ? (isBroken ? Color.red.opacity(0.9) : Theme.textPrimary) : Theme.textFaint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected && isBroken ? Color.red.opacity(0.12) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? (isBroken ? Color.red.opacity(0.5) : Theme.borderStrong) : Theme.border, lineWidth: 0.5)
            )
            .contentShape(Capsule())
            .onTapGesture(perform: onTap)
    }
}
