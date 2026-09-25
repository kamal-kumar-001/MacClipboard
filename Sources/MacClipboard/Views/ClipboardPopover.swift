import SwiftUI
import AppKit
import Carbon.HIToolbox
import ApplicationServices

@MainActor
final class ClipboardViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: CategoryFilter = .all
    @Published var selectedIndex: Int = 0

    enum CategoryFilter: String, CaseIterable {
        case all = "All"
        case text = "Text"
        case link = "Links"
        case image = "Images"

        var iconName: String {
            switch self {
            case .all: return "clock"
            case .text: return "text.alignleft"
            case .link: return "link"
            case .image: return "photo"
            }
        }
    }

    func reset() {
        searchText = ""
        selectedIndex = 0
    }

    func filteredItems(from items: [ClipboardItem]) -> [ClipboardItem] {
        let categoryFiltered = items.filter { item in
            switch selectedCategory {
            case .all:
                return true
            case .text:
                return item.contentType == .text || item.contentType == .richText
            case .link:
                return item.contentType == .url
            case .image:
                return item.contentType == .image
            }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return categoryFiltered
        }

        return categoryFiltered.filter { item in
            item.previewText.localizedCaseInsensitiveContains(query)
        }
    }

    func moveSelection(delta: Int, maxCount: Int) {
        guard maxCount > 0 else {
            selectedIndex = 0
            return
        }
        selectedIndex = max(0, min(maxCount - 1, selectedIndex + delta))
    }
}

@MainActor
struct ClipboardPopover: View {

    @ObservedObject
    private var store = ClipboardStore.shared

    @StateObject
    private var viewModel = ClipboardViewModel()

    @FocusState
    private var isSearchFocused: Bool

    @State
    private var keyMonitor: Any?

    let onClose: () -> Void
    let onCopyAndPaste: @MainActor (ClipboardItem, Bool) -> Void
    let onQuit: @MainActor () -> Void

    var body: some View {
        let items = viewModel.filteredItems(from: store.items)

        VStack(spacing: 0) {
            // Search Bar at Top (like screenshot)
            searchBar

            Divider()
                .opacity(0.3)

            // Section Header
            sectionHeader(itemsCount: items.count)

            // Content List
            content(items: items)

            Divider()
                .opacity(0.3)

            // Bottom Category Filter Bar (like screenshot)
            bottomCategoryBar
        }
        .frame(width: 360, height: 470)
        .background(
            VisualEffectView(
                material: .popover,
                blendingMode: .behindWindow
            )
        )
        .onAppear {
            viewModel.reset()
            isSearchFocused = true
            setupKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .onChange(of: viewModel.searchText) { _ in
            viewModel.selectedIndex = 0
        }
        .onChange(of: viewModel.selectedCategory) { _ in
            viewModel.selectedIndex = 0
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFocused)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }

            Image(systemName: "command")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSearchFocused ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func sectionHeader(itemsCount: Int) -> some View {
        HStack {
            Text(headerTitle)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)

            Spacer()

            Text("\(itemsCount) items")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var headerTitle: String {
        if !viewModel.searchText.isEmpty {
            return "SEARCH RESULTS"
        }

        switch viewModel.selectedCategory {
        case .all:
            return "RECENT COPIES"
        case .text:
            return "TEXT & CODE"
        case .link:
            return "LINKS & URLS"
        case .image:
            return "IMAGES"
        }
    }

    @ViewBuilder
    private func content(items: [ClipboardItem]) -> some View {
        if items.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: viewModel.searchText.isEmpty ? "clipboard" : "magnifyingglass")
                    .font(.system(size: 30))
                    .foregroundColor(.secondary.opacity(0.6))
                Text(viewModel.searchText.isEmpty ? "Clipboard is empty" : "No results for \"\(viewModel.searchText)\"")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    // Standard non-lazy VStack to avoid cell reuse/stale previewText bugs
                    VStack(spacing: 4) {
                        ForEach(items) { item in
                            let index = items.firstIndex(where: { $0.id == item.id }) ?? 0
                            ClipboardItemView(
                                item: item,
                                index: index,
                                isSelected: index == viewModel.selectedIndex,
                                onCopyAndPaste: { pasteImmediately in
                                    onCopyAndPaste(item, pasteImmediately)
                                },
                                onRemove: {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        store.remove(item)
                                    }
                                }
                            )
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .onChange(of: viewModel.selectedIndex) { newIndex in
                    if items.indices.contains(newIndex) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            proxy.scrollTo(items[newIndex].id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var bottomCategoryBar: some View {
        HStack(spacing: 10) {
            // Category navigation matching reference image bottom bar
            ForEach(ClipboardViewModel.CategoryFilter.allCases, id: \.self) { cat in
                Button {
                    viewModel.selectedCategory = cat
                } label: {
                    ZStack {
                        if viewModel.selectedCategory == cat {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 1.5)
                                .frame(width: 24, height: 24)
                        }

                        Image(systemName: cat.iconName)
                            .font(.system(size: 12, weight: viewModel.selectedCategory == cat ? .semibold : .regular))
                            .foregroundColor(viewModel.selectedCategory == cat ? .accentColor : .secondary)
                    }
                    .frame(width: 26, height: 26)
                }
                .buttonStyle(.plain)
                .help(cat.rawValue)
            }

            Spacer()

            // Navigation hints
            Text("1-9,0 or ↵ to paste")
                .font(.system(size: 9))
                .foregroundColor(.secondary.opacity(0.7))

            // Clear All
            Button {
                store.clear()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Clear History")
            .disabled(store.items.isEmpty)

            // Quit
            Button {
                onQuit()
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Quit MacClipboard")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private func setupKeyboardMonitor() {
        removeKeyboardMonitor()

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak viewModel] event in
            guard let viewModel = viewModel else { return event }
            let filtered = viewModel.filteredItems(from: self.store.items)

            switch Int(event.keyCode) {
            case kVK_Escape:
                self.onClose()
                return nil

            case kVK_DownArrow:
                viewModel.moveSelection(delta: 1, maxCount: filtered.count)
                return nil

            case kVK_UpArrow:
                viewModel.moveSelection(delta: -1, maxCount: filtered.count)
                return nil

            case kVK_Return:
                if filtered.indices.contains(viewModel.selectedIndex) {
                    let item = filtered[viewModel.selectedIndex]
                    let pasteImmediately = !event.modifierFlags.contains(.option)
                    self.onCopyAndPaste(item, pasteImmediately)
                    return nil
                }
                return event

            default:
                // Direct number key press: 1..9, 0 (with or without Command)
                if let chars = event.charactersIgnoringModifiers,
                   let firstChar = chars.first,
                   firstChar.isNumber {
                    let targetIdx: Int
                    if firstChar == "0" {
                        targetIdx = 9
                    } else if let digit = firstChar.wholeNumberValue {
                        targetIdx = digit - 1
                    } else {
                        targetIdx = -1
                    }

                    if filtered.indices.contains(targetIdx) {
                        let item = filtered[targetIdx]
                        let pasteImmediately = !event.modifierFlags.contains(.option)
                        self.onCopyAndPaste(item, pasteImmediately)
                        return nil
                    }
                }

                return event
            }
        }
    }

    private func removeKeyboardMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
