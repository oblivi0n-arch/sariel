import SwiftUI

struct SettingsView: View {
    @AppStorage("ollamaHost") private var host: String = "http://localhost:11434"
    @AppStorage("ollamaModel") private var model: String = "gemma3:12b"
    
    private var isHostValid: Bool {
        guard let url = URL(string: host), let scheme = url.scheme else { return false }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("settings")
                .font(Typography.caption)
                .foregroundStyle(Theme.textMuted)

            VStack(alignment: .leading, spacing: 10) {
                Text("OLLAMA CLIENT")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)

                labeledField(
                    title: "Host",
                    text: $host,
                    isValid: host.isEmpty || isHostValid,
                    errorMessage: "Enter a valid URL, e.g. http://localhost:11434"
                )
                labeledField(title: "Model", text: $model)
            }

            Spacer()
        }
        .padding(20)
    }

    private func labeledField(title: String, text: Binding<String>, isValid: Bool = true, errorMessage: String? = nil) -> some View {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValid ? Theme.border : Color.red.opacity(0.6), lineWidth: isValid ? 0.5 : 1)
                )

            if !isValid, let errorMessage {
                Text(errorMessage)
                    .font(Typography.caption)
                    .foregroundStyle(Color.red.opacity(0.8))
            }
        }
    }
}
