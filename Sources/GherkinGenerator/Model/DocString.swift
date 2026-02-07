/// A doc string block attached to a Gherkin step.
///
/// Doc strings allow multi-line text to be passed to a step,
/// delimited by triple quotes (`"""`). An optional media type
/// can be specified on the opening delimiter line.
///
/// ```swift
/// let doc = DocString(content: "{\"key\": \"value\"}", mediaType: "application/json")
/// ```
public struct DocString: Sendable, Hashable, Codable {
    /// The content of the doc string.
    public let content: String

    /// An optional media type (e.g., `"application/json"`, `"text/xml"`).
    public let mediaType: String?

    /// Creates a new doc string.
    ///
    /// - Parameters:
    ///   - content: The multi-line text content.
    ///   - mediaType: An optional media type hint. Defaults to `nil`.
    public init(content: String, mediaType: String? = nil) {
        self.content = content
        self.mediaType = mediaType
    }
}
