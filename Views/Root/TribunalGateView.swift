import SwiftUI

struct TribunalGateView: View {
    let pendingCount: Int
    let onFaceTribunal: () -> Void
    let onDismiss: () -> Void

    @State private var isDismissHovering = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "seal")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.red.opacity(0.85))

                Text("The Tribunal is ready for you.")
                    .font(Theme.voiceFont)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("\(pendingCount) commitment\(pendingCount == 1 ? "" : "s") await\(pendingCount == 1 ? "s" : "") trial. It will not go away on its own.")
                    .font(Typography.label)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)

                Button(action: onFaceTribunal) {
                    Text("Face the Tribunal")
                        .font(Typography.label)
                        .foregroundStyle(Color.red.opacity(0.9))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)

                Text("i'll avoid this a little longer")
                    .font(Typography.label)
                    .foregroundStyle(isDismissHovering ? Theme.textPrimary : Theme.textMuted)
                    .onTapGesture(perform: onDismiss)
                    .onHover { hovering in isDismissHovering = hovering }
            }
            .frame(maxWidth: 380)
        }
    }
}
