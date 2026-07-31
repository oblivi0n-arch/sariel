import SwiftUI

struct PinEntryView: View {
    let title: String
    let subtitle: String?
    let onComplete: (String) -> Void

    @State private var pin: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(Typography.subsectionTitle)
                .foregroundStyle(Theme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textFaint)
            }

            dots
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }

            TextField("", text: $pin)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: pin) { _, newValue in
                    let filtered = String(newValue.filter(\.isNumber).prefix(AppLimits.pinLength))
                    if filtered != pin {
                        pin = filtered
                    }
                    if filtered.count == AppLimits.pinLength {
                        onComplete(filtered)
                        pin = ""
                    }
                }
        }
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }

    private var dots: some View {
        HStack(spacing: 14) {
            ForEach(0..<AppLimits.pinLength, id: \.self) { index in
                Circle()
                    .fill(index < pin.count ? Theme.textPrimary : Color.clear)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Theme.border, lineWidth: 1))
            }
        }
    }
}

#Preview("Pusty PIN") {
    PinEntryView(
        title: "Wpisz PIN",
        subtitle: "Odblokuj Sariel",
        onComplete: { _ in }
    )
    .padding(40)
    .frame(width: 320, height: 260)
    .background(Theme.background)
}

#Preview("Bez podtytułu") {
    PinEntryView(
        title: "Ustaw nowy PIN",
        subtitle: nil,
        onComplete: { _ in }
    )
    .padding(40)
    .frame(width: 320, height: 260)
    .background(Theme.background)
}
