import SwiftUI
import AppKit

struct ClipboardItemView: View {

    let item: ClipboardItem

    let onCopy: () -> Void
    let onRemove: () -> Void

    @State private var isHovering = false

    var body: some View {

        Button {
            onCopy()
        } label: {

            VStack(alignment: .leading, spacing: 8) {

                if item.contentType == .image,
                   let imageData = item.imageData,
                   let image = NSImage(data: imageData) {

                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 200)
                        .background(Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                } else {

                    HStack(spacing: 12) {
                        icon

                        Text(item.previewText)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }

                HStack(spacing: 6) {
                    Text(typeName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("•")

                    Text(relativeDate)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Spacer(minLength: 4)

                    if isHovering {
                        Button {
                            onRemove()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .help("Remove")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(
                    cornerRadius: 10
                )
                .fill(
                    isHovering
                    ? Color.primary.opacity(0.07)
                    : Color.clear
                )
            )
        }
        .buttonStyle(.plain)
        .onHover {
            isHovering = $0
        }
        .contextMenu {
            Button {
                onCopy()
            } label: {
                Label(
                    "Copy Again",
                    systemImage: "doc.on.doc"
                )
            }

            Divider()

            Button(role: .destructive) {
                onRemove()
            } label: {
                Label(
                    "Remove",
                    systemImage: "trash"
                )
            }
        }
    }

    @ViewBuilder
    private var icon: some View {

        if let imageData = item.imageData,
           let image = NSImage(data: imageData) {

            Image(nsImage: image)
                .resizable()
                .aspectRatio(
                    contentMode: .fill
                )
                .frame(
                    width: 48,
                    height: 48
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                )

        } else {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 9
                )
                .fill(iconColor.opacity(0.12))

                Image(systemName: iconName)
                    .font(.system(
                        size: 16,
                        weight: .medium
                    ))
                    .foregroundColor(iconColor)
            }
            .frame(
                width: 40,
                height: 40
            )
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
            .localizedString(
                for: item.createdAt,
                relativeTo: Date()
            )
    }
}
