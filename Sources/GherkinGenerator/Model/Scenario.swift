/// A Gherkin scenario describing a single test case.
///
/// A scenario contains a sequence of steps (`Given`, `When`, `Then`)
/// that describe a specific behavior to test.
///
/// ```swift
/// let scenario = Scenario(
///     title: "Successful login",
///     tags: ["@smoke"],
///     steps: [
///         Step(keyword: .given, text: "a valid account"),
///         Step(keyword: .when, text: "the user logs in"),
///         Step(keyword: .then, text: "the dashboard is displayed"),
///     ]
/// )
/// ```
public struct Scenario: Sendable, Hashable, Codable {
    /// The scenario title.
    public let title: String

    /// Tags attached to this scenario.
    public let tags: [Tag]

    /// An optional description providing additional context.
    public let description: String?

    /// The steps in this scenario.
    public let steps: [Step]

    /// Creates a new scenario.
    ///
    /// - Parameters:
    ///   - title: The scenario title.
    ///   - tags: Tags for this scenario. Defaults to empty.
    ///   - description: An optional description. Defaults to `nil`.
    ///   - steps: The scenario steps. Defaults to empty.
    public init(
        title: String,
        tags: [Tag] = [],
        description: String? = nil,
        steps: [Step] = []
    ) {
        self.title = title
        self.tags = tags
        self.description = description
        self.steps = steps
    }
}

/// A Gherkin Scenario Outline (template with placeholders).
///
/// Scenario Outlines define a parameterized scenario using `<placeholder>`
/// syntax in steps, with concrete values provided in ``Examples`` blocks.
///
/// ```swift
/// let outline = ScenarioOutline(
///     title: "Email validation",
///     steps: [
///         Step(keyword: .given, text: "the email <email>"),
///         Step(keyword: .when, text: "I validate the format"),
///         Step(keyword: .then, text: "the result is <valid>"),
///     ],
///     examples: [
///         Examples(table: DataTable(rows: [
///             ["email", "valid"],
///             ["test@example.com", "true"],
///             ["invalid", "false"],
///         ]))
///     ]
/// )
/// ```
public struct ScenarioOutline: Sendable, Hashable, Codable {
    /// The scenario outline title.
    public let title: String

    /// Tags attached to this scenario outline.
    public let tags: [Tag]

    /// An optional description providing additional context.
    public let description: String?

    /// The template steps containing `<placeholder>` references.
    public let steps: [Step]

    /// The examples blocks providing concrete values for placeholders.
    public let examples: [Examples]

    /// Creates a new scenario outline.
    ///
    /// - Parameters:
    ///   - title: The scenario outline title.
    ///   - tags: Tags for this outline. Defaults to empty.
    ///   - description: An optional description. Defaults to `nil`.
    ///   - steps: The template steps. Defaults to empty.
    ///   - examples: The examples blocks. Defaults to empty.
    public init(
        title: String,
        tags: [Tag] = [],
        description: String? = nil,
        steps: [Step] = [],
        examples: [Examples] = []
    ) {
        self.title = title
        self.tags = tags
        self.description = description
        self.steps = steps
        self.examples = examples
    }
}

/// A child element of a feature or rule, preserving declaration order.
///
/// Features and rules can contain scenarios, scenario outlines, and
/// (at feature level) rules, interleaved in any order. This enum
/// preserves the original ordering.
public enum FeatureChild: Sendable, Hashable, Codable {
    /// A standard scenario.
    case scenario(Scenario)

    /// A parameterized scenario outline.
    case outline(ScenarioOutline)

    /// A rule grouping related scenarios (Gherkin 6+).
    case rule(Rule)
}
