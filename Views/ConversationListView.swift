import SwiftUI

struct ConversationListView: View {
    let conversations: [Conversation]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("rozmowy")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textMuted)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(conversations) { conversation in
                        Text(conversation.title)
                            .font(Theme.uiFont)
                            .foregroundStyle(Theme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 220)
        .frame(maxHeight: .infinity)
        .background(Theme.surface)
        .overlay(alignment: .trailing) {
            Rectangle().fill(Theme.border).frame(width: 0.5)
        }
    }
}
