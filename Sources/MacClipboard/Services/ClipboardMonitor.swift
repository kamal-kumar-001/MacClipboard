import AppKit
import CryptoKit

@MainActor
final class ClipboardMonitor {

    private let pasteboard = NSPasteboard.general

    private var timer: Timer?

    private var lastChangeCount: Int

    private var ignoreNextChange = false

    private let store: ClipboardStore

    init(store: ClipboardStore) {
        self.store = store
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        stop()

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.25,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkClipboard()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func ignoreNextClipboardChange() {
        ignoreNextChange = true
    }

    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        if ignoreNextChange {
            ignoreNextChange = false
            return
        }

        guard
            let item = readClipboard()
        else {
            return
        }

        store.add(item)
    }

    private func readClipboard() -> ClipboardItem? {

        guard let pasteboardItems = pasteboard.pasteboardItems,
              !pasteboardItems.isEmpty else {
            return nil
        }

        var representations: [String: Data] = [:]

        var detectedType: ClipboardContentType = .text

        var previewText = ""
        var imageData: Data?

        for pasteboardItem in pasteboardItems {

            if let tiffData = pasteboardItem.data(forType: .tiff) {
                imageData = tiffData
                detectedType = .image
            }

            for type in pasteboardItem.types {

                guard let data = pasteboardItem.data(
                    forType: type
                ) else {
                    continue
                }

                let typeString = type.rawValue

                representations[typeString] = data

                if type == .png {
                    imageData = data
                    detectedType = .image
                }

                if type == .tiff,
                   imageData == nil {
                    imageData = data
                    detectedType = .image
                }

                if type == .rtf {
                    detectedType = .richText

                    if previewText.isEmpty {
                        previewText =
                            makePlainTextFromRTF(data)
                    }
                }

                if type == .html {
                    if detectedType != .richText {
                        detectedType = .html
                    }

                    if previewText.isEmpty {
                        previewText =
                            makePlainTextFromHTML(data)
                    }
                }

                if type == .URL {
                    detectedType = .url

                    if let string =
                        String(data: data, encoding: .utf8) {

                        previewText = string
                    }
                }

                     if type == .string {

                    if let string =
                        String(data: data, encoding: .utf8) {

                        if previewText.isEmpty {
                            previewText = string
                        }
                    }
                }
            }
        }

        guard !representations.isEmpty else {
            return nil
        }

        if imageData != nil {
            detectedType = .image
        }

        if previewText.isEmpty,
           detectedType == .image {
            previewText = "Image"
        }

        if previewText.isEmpty {
            previewText = "Clipboard item"
        }

        previewText = previewText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let fingerprint =
            makeFingerprint(representations)

        return ClipboardItem(
            contentType: detectedType,
            representations: representations,
            previewText: previewText,
            imageData: imageData,
            fingerprint: fingerprint
        )
    }

    private func makeFingerprint(
        _ representations: [String: Data]
    ) -> String {

        var combined = Data()

        for key in representations.keys.sorted() {

            guard let data = representations[key] else {
                continue
            }

            combined.append(
                key.data(using: .utf8) ?? Data()
            )

            combined.append(data)
        }

        let hash = SHA256.hash(data: combined)

        return hash
            .map {
                String(format: "%02x", $0)
            }
            .joined()
    }

    private func makePlainTextFromRTF(
        _ data: Data
    ) -> String {

        guard
            let attributedString = try? NSAttributedString(
                data: data,
                options: [
                    .documentType:
                        NSAttributedString.DocumentType.rtf
                ],
                documentAttributes: nil
            )
        else {
            return "Rich text"
        }

        return attributedString.string
    }

    private func makePlainTextFromHTML(
        _ data: Data
    ) -> String {

        guard
            let attributedString = try? NSAttributedString(
                data: data,
                options: [
                    .documentType:
                        NSAttributedString.DocumentType.html
                ],
                documentAttributes: nil
            )
        else {
            return "HTML"
        }

        return attributedString.string
    }
}
