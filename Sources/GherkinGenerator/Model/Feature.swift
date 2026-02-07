/// An immutable representation of a complete Gherkin feature.
///
/// `Feature` is the final, validated snapshot of a Gherkin document.
/// It is produced by the ``GherkinFeature`` builder via ``GherkinFeature/build()``
/// or by the ``GherkinParser`` when importing existing `.feature` files.
///
/// All properties are immutable and the type is `Sendable`, making it
/// safe to pass across concurrency boundaries.
///
/// ```swift
/// let feature = try GherkinFeature(title: "Login")
///     .addScenario("Success")
///     .given("valid credentials")
///     .then("access granted")
///     .build()
///
/// print(feature.title)      // "Login"
/// print(feature.children)   // [.scenario(...)]
/// ```
public struct Feature: Sendable, Hashable, Codable {
    /// The feature title.
    public let title: String

    /// The language of this feature.
    public let language: GherkinLanguage

    /// Tags attached to this feature.
    public let tags: [Tag]

    /// An optional description providing additional context.
    public let description: String?

    /// An optional background for all scenarios in this feature.
    public let background: Background?

    /// The ordered children (scenarios, scenario outlines, and rules).
    public let children: [FeatureChild]

    /// Comments associated with this feature.
    public let comments: [Comment]

    /// Creates a new feature.
    ///
    /// - Parameters:
    ///   - title: The feature title.
    ///   - language: The language. Defaults to ``GherkinLanguage/english``.
    ///   - tags: Tags for this feature. Defaults to empty.
    ///   - description: An optional description. Defaults to `nil`.
    ///   - background: An optional background. Defaults to `nil`.
    ///   - children: The scenarios, outlines, and rules. Defaults to empty.
    ///   - comments: Comments. Defaults to empty.
    public init(
        title: String,
        language: GherkinLanguage = .english,
        tags: [Tag] = [],
        description: String? = nil,
        background: Background? = nil,
        children: [FeatureChild] = [],
        comments: [Comment] = []
    ) {
        self.title = title
        self.language = language
        self.tags = tags
        self.description = description
        self.background = background
        self.children = children
        self.comments = comments
    }

    /// All scenarios in this feature (excluding those inside rules).
    public var scenarios: [Scenario] {
        children.compactMap { child in
            if case .scenario(let scenario) = child { return scenario }
            return nil
        }
    }

    /// All scenario outlines in this feature (excluding those inside rules).
    public var outlines: [ScenarioOutline] {
        children.compactMap { child in
            if case .outline(let outline) = child { return outline }
            return nil
        }
    }

    /// All rules in this feature.
    public var rules: [Rule] {
        children.compactMap { child in
            if case .rule(let rule) = child { return rule }
            return nil
        }
    }
}
