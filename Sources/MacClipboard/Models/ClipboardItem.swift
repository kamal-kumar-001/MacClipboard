import Foundation
import AppKit

enum ClipboardContentType: String, Codable {
    case text
    case url
    case richText
    case html
    case image
    case mixed
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date

    let contentType: ClipboardContentType

    /// Original pasteboard representations.
    /// Examples:
    /// public.utf8-plain-text
    /// public.url
    /// public.rtf
    /// public.html
    /// public.tiff
    var representations: [String: Data]

    /// Human-readable preview used by the UI.
    var previewText: String

    /// Optional image representation.
    var imageData: Data?

    /// Used for duplicate detection.
    let fingerprint: String

    init(
        contentType: ClipboardContentType,
        representations: [String: Data],
        previewText: String,
        imageData: Data?,
        fingerprint: String
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.contentType = contentType
        self.representations = representations
        self.previewText = previewText
        self.imageData = imageData
        self.fingerprint = fingerprint
    }

    static func == (
        lhs: ClipboardItem,
        rhs: ClipboardItem
    ) -> Bool {
        lhs.id == rhs.id
    }
}
