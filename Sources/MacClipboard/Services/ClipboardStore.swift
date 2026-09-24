import Foundation

@MainActor
final class ClipboardStore: ObservableObject {

    static let shared = ClipboardStore()

    @Published private(set) var items: [ClipboardItem] = []

    private let maximumItems = 10

    private let fileURL: URL

    private init() {
        let applicationSupport =
            FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]

        let directory =
            applicationSupport.appendingPathComponent(
                "MacClipboard",
                isDirectory: true
            )

        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        fileURL =
            directory.appendingPathComponent("clipboard-history.json")

        load()
    }

    func add(_ item: ClipboardItem) {
        // Don't keep the same clipboard entry twice.
        items.removeAll {
            $0.fingerprint == item.fingerprint
        }

        items.insert(item, at: 0)

        if items.count > maximumItems {
            items = Array(items.prefix(maximumItems))
        }

        save()
    }

    func remove(_ item: ClipboardItem) {
        items.removeAll {
            $0.id == item.id
        }

        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode(
                [ClipboardItem].self,
                from: data
            )
        else {
            return
        }

        items = Array(decoded.prefix(maximumItems))
    }

    private func save() {
        guard
            let data = try? JSONEncoder().encode(items)
        else {
            return
        }

        try? data.write(
            to: fileURL,
            options: .atomic
        )
    }
}
