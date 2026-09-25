import SwiftUI
import AppKit

struct ClipboardItemView: View {

    let item: ClipboardItem
    let index: Int
    let isSelected: Bool

    let onCopyAndPaste: (Bool) -> Void
    let onRemove: () -> Void

    @State private var isHovering = false

    private var badgeNumber: String? {
        if index < 9 {
            return "\(index + 1)"
        } else if index == 9 {
            return "0"
        } else {
            return nil
        }
    }

    var body: some View {
        Button {
            onCopyAndPaste(true)
        } label: {
            HStack(alignment: .center, spacing: 10) {

                // Number shortcut badge (1..9, 0)
                if let badge = badgeNumber {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(isSelected ? Color.white.opacity(0.25) : Color.primary.opacity(0.08))
                        )
                }

                // Thumbnail or type icon
                icon

                // Text or Image Content Preview
                VStack(alignment: .leading, spacing: 3) {
                    if item.contentType == .image,
                       let imageData = item.imageData,
                       let image = NSImage(data: imageData) {

                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 110)
                            .background(Color.black.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                    } else {
                        Text(item.previewText)
                            .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                            .foregroundColor(isSelected ? .white : .primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    HStack(spacing: 6) {
                        Text(typeName)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(isSelected ? .white.opacity(0.85) : iconColor)

                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)

                        Text(relativeDate)
                            .font(.system(size: 9))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                }

                Spacer(minLength: 4)

                // Delete button on hover
                if isHovering {
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Remove")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover {
            isHovering = $0
        }
        .contextMenu {
            Button {
                onCopyAndPaste(true)
            } label: {
                Label("Paste at Input", systemImage: "arrow.right.doc.on.clipboard")
            }

            Button {
                onCopyAndPaste(false)
            } label: {
                Label("Copy to Clipboard Only", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var backgroundFill: Color {
        if isSelected {
            return Color.accentColor
        } else if isHovering {
            return Color.primary.opacity(0.06)
        } else {
            return Color.clear
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let imageData = item.imageData,
           let image = NSImage(data: imageData) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.white.opacity(0.2) : iconColor.opacity(0.14))

                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : iconColor)
            }
            .frame(width: 28, height: 28)
        }
    }

    private var iconName: String {
        switch item.contentType {
        case .text:
            return "text.alignleft"
        case .url:
            return "link"
        case .richText:
            return "textformat"
        case .html:
            return "chevron.left.forwardslash.chevron.right"
        case .image:
            return "photo"
        case .mixed:
            return "doc.on.clipboard"
        }
    }

    private var iconColor: Color {
        switch item.contentType {
        case .text:
            return .blue
        case .url:
            return .purple
        case .richText:
            return .orange
        case .html:
            return .pink
        case .image:
            return .green
        case .mixed:
            return .gray
        }
    }

    private var typeName: String {
        switch item.contentType {
        case .text:
            return "TEXT"
        case .url:
            return "URL"
        case .richText:
            return "RICH TEXT"
        case .html:
            return "HTML"
        case .image:
            return "IMAGE"
        case .mixed:
            return "CLIPBOARD"
        }
    }

    private var relativeDate: String {
        RelativeDateTimeFormatter()
            .localizedString(for: item.createdAt, relativeTo: Date())
    }
}
