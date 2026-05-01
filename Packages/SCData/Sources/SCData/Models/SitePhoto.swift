import Foundation
import SwiftData

/// A photo associated with a Supercharger site.
@Model
public final class SitePhoto {
    public var id: String
    public var url: String
    public var caption: String?
    public var takenAt: Date?

    public init(id: String, url: String, caption: String? = nil, takenAt: Date? = nil) {
        self.id = id
        self.url = url
        self.caption = caption
        self.takenAt = takenAt
    }
}
