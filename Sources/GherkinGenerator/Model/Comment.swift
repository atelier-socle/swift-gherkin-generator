import Foundation

/// A comment line in a Gherkin document.
///
/// Comments start with `#` and can appear on their own line.
/// They are preserved during parsing and formatting.
///
/// ```swift
/// let comment = Comment(text: "This scenario covers the happy path")
/// ```
public struct Comment: Sendable, Hashable, Codable {
    /// The comment text without the `#` prefix.
    public let text: String

    /// Creates a new comment.
    ///
    /// If the provided text starts with `#`, the prefix is stripped automatically.
    ///
    /// - Parameter text: The comment text, with or without `#` prefix.
    public init(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("#") {
            self.text = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        } else {
            self.text = trimmed
        }
    }
}

extension Comment: CustomStringConvertible {
    public var description: String { "# \(text)" }
}
