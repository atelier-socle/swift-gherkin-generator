/// A Gherkin tag attached to features, rules, scenarios, or examples.
///
/// Tags in Gherkin start with `@` and are used for filtering and organization.
/// The `Tag` type stores the name without the `@` prefix and provides
/// the full representation via ``rawValue``.
///
/// ```swift
/// let tag = Tag("smoke")
/// print(tag.rawValue) // "@smoke"
/// ```
public struct Tag: Sendable, Hashable, Codable {
    /// The tag name without the `@` prefix.
    public let name: String

    /// The full tag string including the `@` prefix.
    public var rawValue: String { "@\(name)" }

    /// Creates a new tag.
    ///
    /// If the provided name starts with `@`, the prefix is stripped automatically.
    ///
    /// - Parameter name: The tag name, with or without the `@` prefix.
    public init(_ name: String) {
        if name.hasPrefix("@") {
            self.name = String(name.dropFirst())
        } else {
            self.name = name
        }
    }
}

extension Tag: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension Tag: CustomStringConvertible {
    public var description: String { rawValue }
}
