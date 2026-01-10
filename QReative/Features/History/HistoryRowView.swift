import SwiftUI

// MARK: - History Row View

struct HistoryRowView: View {
    let item: HistoryItem
    let onTap: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            onTap()
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(Theme.animation.springQuick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            .tint(Color.danger)

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(Color(hex: "2196F3"))
        }
    }

    // MARK: - Row Content

    private var rowContent: some View {
        HStack(spacing: 12) {
            // QR Thumbnail
            qrThumbnail

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                // Type indicator + Title
                HStack(spacing: 6) {
                    Image(systemName: item.typeIcon)
                        .font(.system(size: 10))
                        .foregroundStyle(item.accentColor)

                    Text(item.displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                // Date
                Text(item.formattedDate)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - QR Thumbnail

    private var qrThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white)
                .frame(width: 50, height: 50)

            if let thumbnailImage = item.thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                // Generate mini QR preview
                QRCodePreview(
                    content: item.content.isEmpty ? "QR" : item.content,
                    size: 42,
                    foregroundColor: item.accentColor,
                    backgroundColor: .white,
                    shape: .squares,
                    logoImage: nil,
                    isGlowing: false
                )
            }
        }
    }
}

// MARK: - Compact History Row

struct HistoryRowCompact: View {
    let item: HistoryItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(item.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: item.typeIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(item.accentColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(item.shortFormattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.backgroundPrimary
            .ignoresSafeArea()

        VStack(spacing: 12) {
            ForEach(HistoryItem.samples.prefix(3)) { item in
                HistoryRowView(
                    item: item,
                    onTap: { print("Tapped: \(item.displayTitle)") },
                    onDelete: { print("Delete: \(item.id)") },
                    onShare: { print("Share: \(item.content)") }
                )
            }

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)

            Text("Compact Version")
                .typography(.caption1, color: .textTertiary)

            ForEach(HistoryItem.samples.prefix(2)) { item in
                HistoryRowCompact(item: item) {
                    print("Compact tapped: \(item.displayTitle)")
                }
            }
        }
        .padding(20)
    }
}
