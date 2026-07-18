import SwiftUI

struct SettingsView: View {
    @AppStorage("ollamaHost") private var host: String = "http://localhost:11434"
    @AppStorage("ollamaModel") private var model: String = "gemma3:12b"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings")
                .font(Typography.caption)
                .foregroundStyle(Theme.textMuted)

            VStack(alignment: .leading, spacing: 10) {
                Text("OLLAMA CLIENT")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)

                labeledField(title: "Host", text: $host)
                labeledField(title: "Model", text: $model)
            }

            Spacer()
        }
        .padding(20)
    }

    private func labeledField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Typography.label)
                .foregroundStyle(Theme.textMuted)

            TextField(title, text: text)
                .textFieldStyle(.plain)
                .font(Theme.uiFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 0.5))
        }
    }
}
