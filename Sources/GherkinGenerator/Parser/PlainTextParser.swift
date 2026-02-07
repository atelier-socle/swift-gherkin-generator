import Foundation

/// Configuration for plain text import, defining the prefixes that
/// identify step keywords and scenario boundaries.
///
/// ```swift
/// let config = PlainTextImportConfiguration(
///     givenPrefix: "Given ",
///     whenPrefix: "When ",
///     thenPrefix: "Then "
/// )
/// ```
public struct PlainTextImportConfiguration: Sendable, Hashable {
    /// The prefix identifying `Given` steps.
    public let givenPrefix: String

    /// The prefix identifying `When` steps.
    public let whenPrefix: String

    /// The prefix identifying `Then` steps.
    public let thenPrefix: String

    /// The prefix identifying `And` steps.
    public let andPrefix: String

    /// The prefix identifying `But` steps.
    public let butPrefix: String

    /// A separator line that delimits scenarios (e.g., `"---"`).
    public let scenarioSeparator: String

    /// Creates a plain text import configuration.
    ///
    /// - Parameters:
    ///   - givenPrefix: The Given step prefix. Defaults to `"Given "`.
    ///   - whenPrefix: The When step prefix. Defaults to `"When "`.
    ///   - thenPrefix: The Then step prefix. Defaults to `"Then "`.
    ///   - andPrefix: The And step prefix. Defaults to `"And "`.
    ///   - butPrefix: The But step prefix. Defaults to `"But "`.
    ///   - scenarioSeparator: The scenario separator. Defaults to `"---"`.
    public init(
        givenPrefix: String = "Given ",
        whenPrefix: String = "When ",
        thenPrefix: String = "Then ",
        andPrefix: String = "And ",
        butPrefix: String = "But ",
        scenarioSeparator: String = "---"
    ) {
        self.givenPrefix = givenPrefix
        self.whenPrefix = whenPrefix
        self.thenPrefix = thenPrefix
        self.andPrefix = andPrefix
        self.butPrefix = butPrefix
        self.scenarioSeparator = scenarioSeparator
    }
}

/// A parser that imports Gherkin features from plain text.
///
/// Plain text is parsed using configurable prefixes to identify
/// step keywords. Scenarios are separated by a configurable separator
/// line (default `"---"`) or by blank lines between step groups.
///
/// ```swift
/// let text = """
/// Shopping Cart
/// Add a product
/// Given an empty cart
/// When I add a product
/// Then the cart has 1 item
/// ---
/// Remove a product
/// Given a cart with 1 item
/// When I remove the product
/// Then the cart is empty
/// """
/// let feature = try PlainTextParser().parse(text)
/// ```
public struct PlainTextParser: Sendable {
    /// The import configuration.
    public let configuration: PlainTextImportConfiguration

    /// Creates a plain text parser with the given configuration.
    ///
    /// - Parameter configuration: The prefix configuration. Defaults to standard English prefixes.
    public init(configuration: PlainTextImportConfiguration = .init()) {
        self.configuration = configuration
    }

    /// Parses plain text into a ``Feature``.
    ///
    /// - Parameters:
    ///   - source: The plain text source.
    ///   - featureTitle: An optional override for the feature title.
    ///     If `nil`, the first non-empty line is used.
    /// - Returns: The parsed feature.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if the text is empty.
    public func parse(_ source: String, featureTitle: String? = nil) throws -> Feature {
        let allLines = source.components(separatedBy: .newlines)
        var lineIndex = skipLeadingBlanks(in: allLines)

        guard lineIndex < allLines.count else {
            throw GherkinError.importFailed(path: "", reason: "Plain text source is empty")
        }

        let title = resolveTitle(allLines: allLines, lineIndex: &lineIndex, override: featureTitle)
        let children = parseScenarios(from: allLines, startingAt: lineIndex)

        return Feature(title: title, children: children)
    }

    // MARK: - Private Helpers

    private func skipLeadingBlanks(in lines: [String]) -> Int {
        var index = 0
        while index < lines.count, lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
            index += 1
        }
        return index
    }

    private func resolveTitle(
        allLines: [String], lineIndex: inout Int, override: String?
    ) -> String {
        if let provided = override {
            return provided
        }
        let firstLine = allLines[lineIndex].trimmingCharacters(in: .whitespaces)
        if isStepLine(firstLine) {
            return "Untitled Feature"
        }
        lineIndex += 1
        return firstLine
    }

    private func parseScenarios(from allLines: [String], startingAt start: Int) -> [FeatureChild] {
        var children: [FeatureChild] = []
        var currentTitle: String?
        var currentSteps: [Step] = []

        for index in start..<allLines.count {
            let trimmed = allLines[index].trimmingCharacters(in: .whitespaces)

            if trimmed == configuration.scenarioSeparator {
                finalizeScenario(title: &currentTitle, steps: &currentSteps, into: &children)
                continue
            }

            if trimmed.isEmpty {
                if !currentSteps.isEmpty {
                    finalizeScenario(title: &currentTitle, steps: &currentSteps, into: &children)
                }
                continue
            }

            if let step = matchStep(trimmed) {
                if currentTitle == nil { currentTitle = "Untitled Scenario" }
                currentSteps.append(step)
                continue
            }

            if !currentSteps.isEmpty {
                finalizeScenario(title: &currentTitle, steps: &currentSteps, into: &children)
            }
            currentTitle = trimmed
        }

        finalizeScenario(title: &currentTitle, steps: &currentSteps, into: &children)
        return children
    }

    private func finalizeScenario(
        title: inout String?, steps: inout [Step], into children: inout [FeatureChild]
    ) {
        guard let scenarioTitle = title, !steps.isEmpty else {
            title = nil
            steps = []
            return
        }
        children.append(.scenario(Scenario(title: scenarioTitle, steps: steps)))
        title = nil
        steps = []
    }

    // MARK: - Private Helpers

    private func isStepLine(_ line: String) -> Bool {
        matchStep(line) != nil
    }

    private func matchStep(_ line: String) -> Step? {
        let prefixMap: [(String, StepKeyword)] = [
            (configuration.givenPrefix, .given),
            (configuration.whenPrefix, .when),
            (configuration.thenPrefix, .then),
            (configuration.andPrefix, .and),
            (configuration.butPrefix, .but)
        ]

        if let (prefix, keyword) = prefixMap.first(where: { line.hasPrefix($0.0) }) {
            return Step(keyword: keyword, text: String(line.dropFirst(prefix.count)))
        }

        if line.hasPrefix("* ") {
            return Step(keyword: .wildcard, text: String(line.dropFirst(2)))
        }

        return nil
    }
}
