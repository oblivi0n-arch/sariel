import SwiftUI

struct ToastView: View {
    let toast: Toast
    let onTap: () -> Void

    @State private var progress: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "book.closed")
                    .font(Typography.iconSmall)
                    .foregroundStyle(Theme.textPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(toast.entry.title)
                        .font(Typography.label)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("entry saved")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            GeometryReader { geo in
                Rectangle()
                    .fill(Theme.textPrimary)
                    .frame(width: geo.size.width * progress, height: 2)
            }
            .frame(height: 2)
        }
        .frame(width: 220)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.border, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.5), radius: 20, y: 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(.linear(duration: toast.duration)) {
                progress = 0
            }
        }
    }
}
