import SwiftUI

struct JournalView: View {
    @State private var isPlusHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("journal")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)

                Spacer()

                Button(action: createNewEntry) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isPlusHovering ? Theme.border : .clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isPlusHovering = hovering
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }

    private func createNewEntry() {

    }
}

#Preview {
    JournalView()
        .frame(width: 500, height: 500)
        .background(Theme.background)
}
