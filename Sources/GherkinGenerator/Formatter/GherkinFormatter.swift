/// A configurable formatter for producing human-readable Gherkin output.
///
/// `GherkinFormatter` converts a ``Feature`` into a properly formatted
/// Gherkin string with consistent indentation, aligned tables,
/// and configurable spacing.
///
/// ```swift
/// let formatter = GherkinFormatter(configuration: .default)
/// let output = formatter.format(feature)
/// print(output)
/// ```
public struct GherkinFormatter: Sendable {
    /// The formatting configuration.
    public let configuration: FormatterConfiguration

    /// Creates a formatter with the given configuration.
    ///
    /// - Parameter configuration: The formatting options. Defaults to ``FormatterConfiguration/default``.
    public init(configuration: FormatterConfiguration = .default) {
        self.configuration = configuration
    }

    /// Formats a feature into a Gherkin string.
    ///
    /// - Parameter feature: The feature to format.
    /// - Returns: A properly formatted Gherkin string.
    public func format(_ feature: Feature) -> String {
        // TODO: Implement full formatting
        var lines: [String] = []

        // Language header (if not English)
        if feature.language != .english {
            lines.append("# language: \(feature.language.code)")
            lines.append("")
        }

        // Tags
        if !feature.tags.isEmpty {
            lines.append(feature.tags.map(\.rawValue).joined(separator: " "))
        }

        // Feature line
        let featureKeyword = feature.language.keywords.feature[0]
        lines.append("\(featureKeyword): \(feature.title)")

        // Description
        if let description = feature.description {
            lines.append(indent(description, level: 1))
            lines.append("")
        }

        // Background
        if let background = feature.background {
            lines.append("")
            lines.append(contentsOf: formatBackground(background, language: feature.language))
        }

        // Children
        for child in feature.children {
            lines.append("")
            switch child {
            case .scenario(let scenario):
                lines.append(contentsOf: formatScenario(scenario, language: feature.language))
            case .outline(let outline):
                lines.append(contentsOf: formatOutline(outline, language: feature.language))
            case .rule(let rule):
                lines.append(contentsOf: formatRule(rule, language: feature.language))
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - Internal Formatting

    private func formatBackground(_ background: Background, language: GherkinLanguage) -> [String] {
        var lines: [String] = []
        let keyword = language.keywords.background[0]
        let name = background.name.map { " \($0)" } ?? ""
        lines.append(indent("\(keyword):\(name)", level: 1))
        lines.append(contentsOf: formatSteps(background.steps, language: language, level: 2))
        return lines
    }

    private func formatScenario(_ scenario: Scenario, language: GherkinLanguage) -> [String] {
        var lines: [String] = []
        if !scenario.tags.isEmpty {
            lines.append(indent(scenario.tags.map(\.rawValue).joined(separator: " "), level: 1))
        }
        let keyword = language.keywords.scenario[0]
        lines.append(indent("\(keyword): \(scenario.title)", level: 1))
        lines.append(contentsOf: formatSteps(scenario.steps, language: language, level: 2))
        return lines
    }

    private func formatOutline(_ outline: ScenarioOutline, language: GherkinLanguage) -> [String] {
        var lines: [String] = []
        if !outline.tags.isEmpty {
            lines.append(indent(outline.tags.map(\.rawValue).joined(separator: " "), level: 1))
        }
        let keyword = language.keywords.scenarioOutline[0]
        lines.append(indent("\(keyword): \(outline.title)", level: 1))
        lines.append(contentsOf: formatSteps(outline.steps, language: language, level: 2))

        for example in outline.examples {
            lines.append("")
            let exKeyword = language.keywords.examples[0]
            let name = example.name.map { ": \($0)" } ?? ""
            if !example.tags.isEmpty {
                lines.append(indent(example.tags.map(\.rawValue).joined(separator: " "), level: 2))
            }
            lines.append(indent("\(exKeyword)\(name):", level: 2))
            lines.append(contentsOf: formatDataTable(example.table, level: 3))
        }

        return lines
    }

    private func formatRule(_ rule: Rule, language: GherkinLanguage) -> [String] {
        var lines: [String] = []
        if !rule.tags.isEmpty {
            lines.append(indent(rule.tags.map(\.rawValue).joined(separator: " "), level: 1))
        }
        let keyword = language.keywords.rule[0]
        lines.append(indent("\(keyword): \(rule.title)", level: 1))

        if let description = rule.description {
            lines.append(indent(description, level: 2))
            lines.append("")
        }

        if let background = rule.background {
            lines.append("")
            let bgKeyword = language.keywords.background[0]
            let name = background.name.map { " \($0)" } ?? ""
            lines.append(indent("\(bgKeyword):\(name)", level: 2))
            lines.append(contentsOf: formatSteps(background.steps, language: language, level: 3))
        }

        for child in rule.children {
            lines.append("")
            switch child {
            case .scenario(let scenario):
                lines.append(contentsOf: formatRuleScenario(scenario, language: language))
            case .outline(let outline):
                lines.append(contentsOf: formatRuleOutline(outline, language: language))
            }
        }

        return lines
    }

    private func formatRuleScenario(
        _ scenario: Scenario, language: GherkinLanguage
    ) -> [String] {
        var lines: [String] = []
        if !scenario.tags.isEmpty {
            lines.append(indent(scenario.tags.map(\.rawValue).joined(separator: " "), level: 2))
        }
        let keyword = language.keywords.scenario[0]
        lines.append(indent("\(keyword): \(scenario.title)", level: 2))
        lines.append(contentsOf: formatSteps(scenario.steps, language: language, level: 3))
        return lines
    }

    private func formatRuleOutline(
        _ outline: ScenarioOutline, language: GherkinLanguage
    ) -> [String] {
        var lines: [String] = []
        if !outline.tags.isEmpty {
            lines.append(indent(outline.tags.map(\.rawValue).joined(separator: " "), level: 2))
        }
        let keyword = language.keywords.scenarioOutline[0]
        lines.append(indent("\(keyword): \(outline.title)", level: 2))
        lines.append(contentsOf: formatSteps(outline.steps, language: language, level: 3))

        for example in outline.examples {
            lines.append("")
            let exKeyword = language.keywords.examples[0]
            let name = example.name.map { ": \($0)" } ?? ""
            if !example.tags.isEmpty {
                lines.append(
                    indent(example.tags.map(\.rawValue).joined(separator: " "), level: 3))
            }
            lines.append(indent("\(exKeyword)\(name):", level: 3))
            lines.append(contentsOf: formatDataTable(example.table, level: 4))
        }

        return lines
    }

    private func formatSteps(_ steps: [Step], language: GherkinLanguage, level: Int) -> [String] {
        var lines: [String] = []
        for step in steps {
            let keyword = stepKeywordString(step.keyword, language: language)
            lines.append(indent("\(keyword)\(step.text)", level: level))

            if let table = step.dataTable {
                lines.append(contentsOf: formatDataTable(table, level: level + 1))
            }

            if let doc = step.docString {
                let mediaType = doc.mediaType ?? ""
                lines.append(indent("\"\"\"\(mediaType)", level: level + 1))
                for line in doc.content.split(separator: "\n", omittingEmptySubsequences: false) {
                    lines.append(indent(String(line), level: level + 1))
                }
                lines.append(indent("\"\"\"", level: level + 1))
            }
        }
        return lines
    }

    private func formatDataTable(_ table: DataTable, level: Int) -> [String] {
        guard !table.rows.isEmpty else { return [] }

        // Calculate max width per column for alignment
        let columnCount = table.columnCount
        var maxWidths = Array(repeating: 0, count: columnCount)
        for row in table.rows {
            for (index, cell) in row.enumerated() where index < columnCount {
                maxWidths[index] = max(maxWidths[index], cell.count)
            }
        }

        return table.rows.map { row in
            let cells = (0..<columnCount).map { index in
                let cell = index < row.count ? row[index] : ""
                return " " + cell.padding(toLength: maxWidths[index], withPad: " ", startingAt: 0) + " "
            }
            return indent("|\(cells.joined(separator: "|"))|", level: level)
        }
    }

    private func stepKeywordString(_ keyword: StepKeyword, language: GherkinLanguage) -> String {
        let kw = language.keywords
        switch keyword {
        case .given: return kw.given[0]
        case .when: return kw.when[0]
        case .then: return kw.then[0]
        case .and: return kw.and[0]
        case .but: return kw.but[0]
        case .wildcard: return "* "
        }
    }

    private func indent(_ text: String, level: Int) -> String {
        let prefix = String(
            repeating: configuration.indentCharacter,
            count: level * configuration.indentWidth
        )
        return prefix + text
    }
}

/// Configuration options for the Gherkin formatter.
public struct FormatterConfiguration: Sendable, Hashable {
    /// The character used for indentation.
    public let indentCharacter: Character

    /// The number of indent characters per level.
    public let indentWidth: Int

    /// Whether to use compact mode (fewer blank lines).
    public let compact: Bool

    /// Creates a formatter configuration.
    ///
    /// - Parameters:
    ///   - indentCharacter: The indent character. Defaults to space.
    ///   - indentWidth: Characters per indent level. Defaults to `2`.
    ///   - compact: Whether to use compact mode. Defaults to `false`.
    public init(
        indentCharacter: Character = " ",
        indentWidth: Int = 2,
        compact: Bool = false
    ) {
        self.indentCharacter = indentCharacter
        self.indentWidth = indentWidth
        self.compact = compact
    }

    /// The default formatting configuration (2-space indent, non-compact).
    public static let `default` = FormatterConfiguration()

    /// A compact configuration with minimal whitespace.
    public static let compact = FormatterConfiguration(compact: true)

    /// A tab-based indentation configuration.
    public static let tabs = FormatterConfiguration(indentCharacter: "\t", indentWidth: 1)
}
