import SwiftUI

// MARK: - History Row View (inline row, placed inside a card container)
struct HistoryRowView: View {
    let item: HistoryItem
    var isLast: Bool = false
    let onTap: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            rowContent
        }
        .buttonStyle(PressableStyle(scale: 0.99))
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
            .tint(Color.accentPrimary)
        }
    }

    // MARK: - Row Content
    private var rowContent: some View {
        HStack(spacing: 13) {
            qrThumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text("\(item.displayTypeName) · \(item.shortFormattedDate)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ink3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.ink3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color.surface)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)
                    .padding(.leading, 76)
            }
        }
    }

    // MARK: - QR Thumbnail
    private var qrThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.surface2)
                .frame(width: 38, height: 38)

            if item.isBarcode {
                // A 1D barcode is unreadable at 28pt, so show a clear glyph.
                Image(systemName: "barcode")
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color.textPrimary)
            } else if let thumbnailImage = item.thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                QRCodePreview(
                    content: item.content.isEmpty ? "QR" : item.content,
                    size: 28,
                    foregroundColor: .textPrimary,
                    backgroundColor: .clear,
                    shape: .squares,
                    logoImage: nil,
                    isGlowing: false
                )
            }
        }
    }
}

// MARK: - Compact History Row (kept for compatibility)
struct HistoryRowCompact: View {
    let item: HistoryItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surface2)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: item.typeIcon)
                            .font(.system(size: 16))
                            .foregroundStyle(Color.textPrimary)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayTitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Text(item.shortFormattedDate)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.ink3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.ink3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.lineColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
