import SwiftUI
import AppKit

@MainActor
struct ClipboardPopover: View {

    @ObservedObject
    private var store = ClipboardStore.shared

    let onClose: () -> Void
    let onCopy: @MainActor () -> Void
    let onQuit: @MainActor () -> Void

    var body: some View {

        VStack(spacing: 0) {

            header

            Divider()
                .opacity(0.5)

            content

            Divider()
                .opacity(0.5)

            footer
        }
        .frame(
            width: 380,
            height: 520
        )
        .background(
            VisualEffectView(
                material: .popover,
                blendingMode: .behindWindow
            )
        )
    }

    private var header: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text("Clipboard")
                    .font(.system(
                        size: 18,
                        weight: .semibold
                    ))

                Text(
                    "\(store.items.count) of 10 items"
                )
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                store.clear()
            } label: {

                Image(systemName: "trash")
                    .font(.system(
                        size: 12,
                        weight: .medium
                    ))
                    .frame(
                        width: 30,
                        height: 30
                    )
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Clear All")
            .disabled(store.items.isEmpty)

            Button {
                onClose()
            } label: {

                Image(systemName: "xmark")
                    .font(.system(
                        size: 11,
                        weight: .semibold
                    ))
                    .frame(
                        width: 30,
                        height: 30
                    )
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var content: some View {

        if store.items.isEmpty {

            EmptyStateView()

        } else {

            ScrollView {

                LazyVStack(
                    spacing: 2
                ) {

                    ForEach(store.items) { item in

                        ClipboardItemView(
                            item: item,
                            onCopy: {
                                copy(item)
                            },
                            onRemove: {
                                withAnimation(
                                    .easeOut(duration: 0.18)
                                ) {
                                    store.remove(item)
                                }
                            }
                        )
                    }
                }
                .padding(8)
            }
        }
    }

    private var footer: some View {

        HStack {

            Image(
                systemName: "command"
            )
            .font(.system(size: 10))

            Text("Click an item to copy it again")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Spacer()

            Text("⌘")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text("Clipboard")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Button {
                onQuit()
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 32, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            .help("Quit MacClipboard")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func copy(
        _ item: ClipboardItem
    ) {

        onCopy()

        let pasteboard =
            NSPasteboard.general

        pasteboard.clearContents()

        let pasteboardItem =
            NSPasteboardItem()

        for (
            typeString,
            data
        ) in item.representations {

            let type =
                NSPasteboard.PasteboardType(
                    typeString
                )

            pasteboardItem.setData(
                data,
                forType: type
            )
        }

        pasteboard.writeObjects(
            [pasteboardItem]
        )

        onClose()
    }
}
struct VisualEffectView: NSViewRepresentable {

    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(
        context: Context
    ) -> NSVisualEffectView {

        let view =
            NSVisualEffectView()

        view.material = material
        view.blendingMode = blendingMode
        view.state = .active

        return view
    }

    func updateNSView(
        _ nsView: NSVisualEffectView,
        context: Context
    ) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
