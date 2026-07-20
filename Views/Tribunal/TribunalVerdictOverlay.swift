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
                Text("The Tribunal's Verdicts")
                    .font(Typography.title)
                    .foregroundStyle(Theme.textPrimary)

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
        VStack(alignment: .leading, spacing: 6) {
            Text(verdict.wrappedValue.commitment.declarationText)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)

            if !verdict.wrappedValue.reasoning.isEmpty {
                Text(verdict.wrappedValue.reasoning)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }

            Picker("", selection: verdict.proposedStatus) {
                Text("Fulfilled").tag(CommitmentStatus.fulfilled)
                Text("Broken").tag(CommitmentStatus.broken)
            }
            .pickerStyle(.segmented)
        }
        .padding(10)
        .background(Theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
