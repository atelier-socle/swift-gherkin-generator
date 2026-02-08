/// A fluent builder for composing Gherkin features.
///
/// `GherkinFeature` provides a chainable API for constructing `.feature` files
/// programmatically. Each method returns a new copy, making the builder
/// immutable and `Sendable`.
///
/// ```swift
/// let feature = GherkinFeature(title: "Shopping Cart")
///     .addScenario("Add a product")
///     .given("an empty cart")
///     .when("I add a product at 29€")
///     .then("the cart contains 1 item")
///     .and("the total is 29€")
///
/// let snapshot = try feature.build()
/// ```
///
/// ## Mass Generation
///
/// Use `var` and reassignment for loop-based generation:
///
/// ```swift
/// var feature = GherkinFeature(title: "API Tests")
/// for endpoint in endpoints {
///     feature = feature
///         .addScenario("GET /\(endpoint)")
///         .given("API running")
///         .then("status 200")
/// }
/// ```
///
/// Or use ``appendScenario(_:)`` for a mutating approach:
///
/// ```swift
/// var feature = GherkinFeature(title: "API Tests")
/// for endpoint in endpoints {
///     feature.appendScenario(
///         Scenario(title: "GET /\(endpoint)", steps: [...])
///     )
/// }
/// ```
public struct GherkinFeature: Sendable, Hashable {

    // MARK: - Feature Metadata

    private var featureTitle: String
    private var featureLanguage: GherkinLanguage
    private var featureTags: [Tag]
    private var featureDescription: String?
    private var featureBackground: Background?
    private var featureComments: [Comment]

    // MARK: - Children

    private var children: [FeatureChild]

    // MARK: - Pending Child (not yet finalized)

    private var pending: PendingChild?

    // MARK: - Init

    /// Creates a new feature builder.
    ///
    /// - Parameters:
    ///   - title: The feature title.
    ///   - language: The language for keyword localization. Defaults to ``GherkinLanguage/english``.
    public init(title: String, language: GherkinLanguage = .english) {
        self.featureTitle = title
        self.featureLanguage = language
        self.featureTags = []
        self.featureDescription = nil
        self.featureBackground = nil
        self.featureComments = []
        self.children = []
        self.pending = nil
    }

    // MARK: - Feature-level Configuration

    /// Adds tags to the feature.
    ///
    /// - Parameter tags: An array of tag strings (with or without `@` prefix).
    /// - Returns: A new builder with the tags applied.
    public func tags(_ tags: [String]) -> GherkinFeature {
        var copy = self
        copy.featureTags = tags.map { Tag($0) }
        return copy
    }

    /// Sets the feature description.
    ///
    /// - Parameter text: Free-form description text.
    /// - Returns: A new builder with the description set.
    public func description(_ text: String) -> GherkinFeature {
        var copy = self
        copy.featureDescription = text
        return copy
    }

    /// Adds a comment to the feature.
    ///
    /// - Parameter text: The comment text.
    /// - Returns: A new builder with the comment added.
    public func comment(_ text: String) -> GherkinFeature {
        var copy = self
        copy.featureComments.append(Comment(text: text))
        return copy
    }

    // MARK: - Background

    /// Defines a background for this feature using a closure.
    ///
    /// The closure receives a ``BackgroundBuilder`` to add steps.
    ///
    /// ```swift
    /// let feature = GherkinFeature(title: "Orders")
    ///     .background {
    ///         $0.given("a logged-in user")
    ///           .and("at least one existing order")
    ///     }
    /// ```
    ///
    /// - Parameter configure: A closure that configures the background.
    /// - Returns: A new builder with the background set.
    public func background(
        _ configure: (BackgroundBuilder) -> BackgroundBuilder
    ) -> GherkinFeature {
        var copy = self
        let builder = configure(BackgroundBuilder())
        copy.featureBackground = builder.build()
        return copy
    }

    /// Sets a pre-built background for this feature.
    ///
    /// - Parameter background: The background to set.
    /// - Returns: A new builder with the background set.
    public func background(_ background: Background) -> GherkinFeature {
        var copy = self
        copy.featureBackground = background
        return copy
    }

    // MARK: - Scenario

    /// Starts a new scenario.
    ///
    /// Any previously pending scenario or outline is finalized before
    /// starting the new one.
    ///
    /// - Parameter title: The scenario title.
    /// - Returns: A new builder with the scenario started.
    public func addScenario(_ title: String) -> GherkinFeature {
        var copy = finalizePending()
        copy.pending = .scenario(
            title: title,
            tags: [],
            description: nil,
            steps: []
        )
        return copy
    }

    /// Starts a new scenario outline (template with placeholders).
    ///
    /// - Parameter title: The scenario outline title.
    /// - Returns: A new builder with the outline started.
    public func addOutline(_ title: String) -> GherkinFeature {
        var copy = finalizePending()
        copy.pending = .outline(
            title: title,
            tags: [],
            description: nil,
            steps: [],
            examples: []
        )
        return copy
    }

    // MARK: - Steps

    /// Adds a `Given` step to the current scenario or outline.
    ///
    /// - Parameter text: The step text.
    /// - Returns: A new builder with the step added.
    public func given(_ text: String) -> GherkinFeature {
        addStep(keyword: .given, text: text)
    }

    /// Adds a `When` step to the current scenario or outline.
    ///
    /// - Parameter text: The step text.
    /// - Returns: A new builder with the step added.
    public func when(_ text: String) -> GherkinFeature {
        addStep(keyword: .when, text: text)
    }

    /// Adds a `Then` step to the current scenario or outline.
    ///
    /// - Parameter text: The step text.
    /// - Returns: A new builder with the step added.
    public func then(_ text: String) -> GherkinFeature {
        addStep(keyword: .then, text: text)
    }

    /// Adds an `And` continuation step to the current scenario or outline.
    ///
    /// - Parameter text: The step text.
    /// - Returns: A new builder with the step added.
    public func and(_ text: String) -> GherkinFeature {
        addStep(keyword: .and, text: text)
    }

    /// Adds a `But` continuation step to the current scenario or outline.
    ///
    /// - Parameter text: The step text.
    /// - Returns: A new builder with the step added.
    public func but(_ text: String) -> GherkinFeature {
        addStep(keyword: .but, text: text)
    }

    /// Adds a wildcard (`*`) step to the current scenario or outline.
    ///
    /// - Parameter text: The step text.
    /// - Returns: A new builder with the step added.
    public func step(_ text: String) -> GherkinFeature {
        addStep(keyword: .wildcard, text: text)
    }

    // MARK: - Data Table

    /// Attaches a data table to the last step in the current scenario or outline.
    ///
    /// ```swift
    /// .given("the following prices")
    /// .table([
    ///     ["Quantity", "Unit Price"],
    ///     ["1-10", "10€"],
    ///     ["11-50", "8€"],
    /// ])
    /// ```
    ///
    /// - Parameter rows: The table rows, where the first row is the header.
    /// - Returns: A new builder with the table attached.
    public func table(_ rows: [[String]]) -> GherkinFeature {
        var copy = self
        copy.pending = copy.pending?.attachingTable(DataTable(rows: rows))
        return copy
    }

    // MARK: - Doc String

    /// Attaches a doc string to the last step in the current scenario or outline.
    ///
    /// - Parameters:
    ///   - content: The doc string content.
    ///   - mediaType: An optional media type. Defaults to `nil`.
    /// - Returns: A new builder with the doc string attached.
    public func docString(_ content: String, mediaType: String? = nil) -> GherkinFeature {
        var copy = self
        copy.pending = copy.pending?.attachingDocString(
            DocString(content: content, mediaType: mediaType)
        )
        return copy
    }

    // MARK: - Tags on Current Scenario / Outline

    /// Adds tags to the current scenario or outline.
    ///
    /// This must be called after ``addScenario(_:)`` or ``addOutline(_:)``.
    ///
    /// - Parameter tags: An array of tag strings.
    /// - Returns: A new builder with the tags applied.
    public func scenarioTags(_ tags: [String]) -> GherkinFeature {
        var copy = self
        copy.pending = copy.pending?.withTags(tags.map { Tag($0) })
        return copy
    }

    // MARK: - Examples (Outline only)

    /// Adds an examples block to the current scenario outline.
    ///
    /// ```swift
    /// .addOutline("Email validation")
    /// .given("the email <email>")
    /// .then("the result is <valid>")
    /// .examples([
    ///     ["email", "valid"],
    ///     ["test@example.com", "true"],
    ///     ["invalid", "false"],
    /// ])
    /// ```
    ///
    /// - Parameter rows: The examples table, where the first row is the header.
    /// - Returns: A new builder with the examples added.
    public func examples(_ rows: [[String]]) -> GherkinFeature {
        var copy = self
        let table = DataTable(rows: rows)
        copy.pending = copy.pending?.addingExamples(
            Examples(table: table)
        )
        return copy
    }

    /// Adds a tagged examples block to the current scenario outline.
    ///
    /// - Parameters:
    ///   - rows: The examples table.
    ///   - name: An optional name for the examples block.
    ///   - tags: Tags for this examples block.
    /// - Returns: A new builder with the tagged examples added.
    public func examples(
        _ rows: [[String]],
        name: String? = nil,
        tags: [String] = []
    ) -> GherkinFeature {
        var copy = self
        let table = DataTable(rows: rows)
        copy.pending = copy.pending?.addingExamples(
            Examples(name: name, tags: tags.map { Tag($0) }, table: table)
        )
        return copy
    }

    // MARK: - Rule

    /// Adds a pre-built rule to the feature.
    ///
    /// - Parameter rule: The rule to add.
    /// - Returns: A new builder with the rule added.
    public func addRule(_ rule: Rule) -> GherkinFeature {
        var copy = finalizePending()
        copy.children.append(.rule(rule))
        return copy
    }

    // MARK: - Mutating API (for loop-based generation)

    /// Appends a pre-built scenario to the feature (mutating).
    ///
    /// Use this for loop-based mass generation.
    ///
    /// - Parameter scenario: The scenario to append.
    public mutating func appendScenario(_ scenario: Scenario) {
        self = finalizePending()
        children.append(.scenario(scenario))
    }

    /// Appends a pre-built scenario outline to the feature (mutating).
    ///
    /// - Parameter outline: The outline to append.
    public mutating func appendOutline(_ outline: ScenarioOutline) {
        self = finalizePending()
        children.append(.outline(outline))
    }

    // MARK: - Build

    /// Builds the immutable ``Feature`` snapshot.
    ///
    /// Finalizes any pending scenario or outline and produces
    /// a complete, immutable `Feature` value.
    ///
    /// - Returns: The immutable feature.
    /// - Throws: ``GherkinError/emptyTitle`` if the title is empty.
    public func build() throws -> Feature {
        guard !featureTitle.isEmpty else {
            throw GherkinError.emptyTitle
        }

        let finalized = finalizePending()

        return Feature(
            title: finalized.featureTitle,
            language: finalized.featureLanguage,
            tags: finalized.featureTags,
            description: finalized.featureDescription,
            background: finalized.featureBackground,
            children: finalized.children,
            comments: finalized.featureComments
        )
    }

    // MARK: - Convenience Export

    /// Validates and exports the feature to a `.feature` file.
    ///
    /// This is a convenience method combining ``build()``, validation,
    /// and export in a single call.
    ///
    /// - Parameter path: The output file path.
    /// - Throws: ``GherkinError`` if validation or export fails.
    public func export(to path: String) async throws {
        let feature = try build()
        let validator = GherkinValidator()
        try validator.validate(feature)
        let exporter = GherkinExporter()
        try await exporter.export(feature, to: path)
    }

    /// Validates the current feature builder state.
    ///
    /// - Throws: ``GherkinError`` if validation fails.
    public func validate() throws {
        let feature = try build()
        let validator = GherkinValidator()
        try validator.validate(feature)
    }

    // MARK: - Internal Helpers

    private func addStep(keyword: StepKeyword, text: String) -> GherkinFeature {
        var copy = self
        copy.pending = copy.pending?.addingStep(
            Step(keyword: keyword, text: text)
        )
        return copy
    }

    private func finalizePending() -> GherkinFeature {
        var copy = self
        guard let pending = copy.pending else { return copy }

        switch pending {
        case .scenario(let title, let tags, let description, let steps):
            copy.children.append(
                .scenario(
                    Scenario(title: title, tags: tags, description: description, steps: steps)
                ))
        case .outline(let title, let tags, let description, let steps, let examples):
            copy.children.append(
                .outline(
                    ScenarioOutline(
                        title: title,
                        tags: tags,
                        description: description,
                        steps: steps,
                        examples: examples
                    )
                ))
        }

        copy.pending = nil
        return copy
    }
}

// MARK: - PendingChild

extension GherkinFeature {
    /// Internal state for a scenario or outline being built.
    enum PendingChild: Sendable, Hashable {
        case scenario(title: String, tags: [Tag], description: String?, steps: [Step])
        case outline(
            title: String,
            tags: [Tag],
            description: String?,
            steps: [Step],
            examples: [Examples]
        )

        func addingStep(_ step: Step) -> PendingChild {
            switch self {
            case .scenario(let title, let tags, let desc, var steps):
                steps.append(step)
                return .scenario(title: title, tags: tags, description: desc, steps: steps)
            case .outline(let title, let tags, let desc, var steps, let examples):
                steps.append(step)
                return .outline(
                    title: title, tags: tags, description: desc,
                    steps: steps, examples: examples
                )
            }
        }

        func attachingTable(_ table: DataTable) -> PendingChild {
            switch self {
            case .scenario(let title, let tags, let desc, var steps):
                guard let last = steps.popLast() else { return self }
                steps.append(last.withTable(table))
                return .scenario(title: title, tags: tags, description: desc, steps: steps)
            case .outline(let title, let tags, let desc, var steps, let examples):
                guard let last = steps.popLast() else { return self }
                steps.append(last.withTable(table))
                return .outline(
                    title: title, tags: tags, description: desc,
                    steps: steps, examples: examples
                )
            }
        }

        func attachingDocString(_ docString: DocString) -> PendingChild {
            switch self {
            case .scenario(let title, let tags, let desc, var steps):
                guard let last = steps.popLast() else { return self }
                steps.append(last.withDocString(docString))
                return .scenario(title: title, tags: tags, description: desc, steps: steps)
            case .outline(let title, let tags, let desc, var steps, let examples):
                guard let last = steps.popLast() else { return self }
                steps.append(last.withDocString(docString))
                return .outline(
                    title: title, tags: tags, description: desc,
                    steps: steps, examples: examples
                )
            }
        }

        func withTags(_ tags: [Tag]) -> PendingChild {
            switch self {
            case .scenario(let title, _, let desc, let steps):
                return .scenario(title: title, tags: tags, description: desc, steps: steps)
            case .outline(let title, _, let desc, let steps, let examples):
                return .outline(
                    title: title, tags: tags, description: desc,
                    steps: steps, examples: examples
                )
            }
        }

        func addingExamples(_ examples: Examples) -> PendingChild {
            switch self {
            case .scenario:
                return self  // No-op: examples on a regular scenario
            case .outline(let title, let tags, let desc, let steps, var existing):
                existing.append(examples)
                return .outline(
                    title: title, tags: tags, description: desc,
                    steps: steps, examples: existing
                )
            }
        }
    }
}

// MARK: - BackgroundBuilder

/// A builder for constructing background steps.
///
/// Used within the ``GherkinFeature/background(_:)-((BackgroundBuilder)->BackgroundBuilder)`` closure.
public struct BackgroundBuilder: Sendable {
    private var steps: [Step]

    /// Creates an empty background builder.
    public init() {
        self.steps = []
    }

    /// Adds a `Given` step.
    public func given(_ text: String) -> BackgroundBuilder {
        var copy = self
        copy.steps.append(Step(keyword: .given, text: text))
        return copy
    }

    /// Adds an `And` continuation step.
    public func and(_ text: String) -> BackgroundBuilder {
        var copy = self
        copy.steps.append(Step(keyword: .and, text: text))
        return copy
    }

    /// Adds a `But` continuation step.
    public func but(_ text: String) -> BackgroundBuilder {
        var copy = self
        copy.steps.append(Step(keyword: .but, text: text))
        return copy
    }

    /// Builds the background from accumulated steps.
    internal func build() -> Background {
        Background(steps: steps)
    }
}
