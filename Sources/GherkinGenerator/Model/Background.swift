/// A background block that provides shared precondition steps.
///
/// Background steps run before each scenario in a feature or rule.
/// They avoid repeating the same `Given` steps across multiple scenarios.
///
/// ```swift
/// let background = Background(steps: [
///     Step(keyword: .given, text: "a logged-in user"),
///     Step(keyword: .and, text: "at least one existing order"),
/// ])
/// ```
public struct Background: Sendable, Hashable, Codable {
    /// An optional name for the background.
    public let name: String?

    /// An optional description providing additional context.
    public let description: String?

    /// The steps in this background block.
    public let steps: [Step]

    /// Creates a new background.
    ///
    /// - Parameters:
    ///   - name: An optional name. Defaults to `nil`.
    ///   - description: An optional description. Defaults to `nil`.
    ///   - steps: The background steps.
    public init(name: String? = nil, description: String? = nil, steps: [Step] = []) {
        self.name = name
        self.description = description
        self.steps = steps
    }
}
