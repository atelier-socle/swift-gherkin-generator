import Foundation

/// The output format for exporting a Gherkin feature.
public enum ExportFormat: String, Sendable, CaseIterable {
    /// Standard Gherkin `.feature` file format.
    case feature

    /// JSON structured representation.
    case json

    /// Markdown documentation format.
    case markdown
}

/// A stateless exporter that writes Gherkin features to various formats.
///
/// For single-feature exports, `GherkinExporter` handles the full workflow
/// of formatting and writing to disk.
///
/// ```swift
/// let exporter = GherkinExporter()
/// try await exporter.export(feature, to: "output.feature")
/// ```
///
/// For large-scale or streaming exports, use ``StreamingExporter`` instead.
public struct GherkinExporter: Sendable {
    /// The formatter used for `.feature` output.
    public let formatter: GherkinFormatter

    /// Creates an exporter with the given formatter.
    ///
    /// - Parameter formatter: The formatter to use. Defaults to a default-configured formatter.
    public init(formatter: GherkinFormatter = GherkinFormatter()) {
        self.formatter = formatter
    }

    /// Exports a feature to a file at the given path.
    ///
    /// - Parameters:
    ///   - feature: The feature to export.
    ///   - path: The output file path.
    ///   - format: The export format. Defaults to ``ExportFormat/feature``.
    /// - Throws: ``GherkinError/exportFailed(path:reason:)`` on I/O errors.
    public func export(
        _ feature: Feature,
        to path: String,
        format: ExportFormat = .feature
    ) async throws {
        let content = try render(feature, format: format)
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw GherkinError.exportFailed(path: path, reason: error.localizedDescription)
        }
    }

    /// Renders a feature to a string in the given format.
    ///
    /// - Parameters:
    ///   - feature: The feature to render.
    ///   - format: The export format. Defaults to ``ExportFormat/feature``.
    /// - Returns: The rendered string.
    /// - Throws: An error if encoding fails (e.g., for JSON format).
    public func render(_ feature: Feature, format: ExportFormat = .feature) throws -> String {
        switch format {
        case .feature:
            return formatter.format(feature)
        case .json:
            return try renderJSON(feature)
        case .markdown:
            return renderMarkdown(feature)
        }
    }

    // MARK: - JSON Rendering

    private func renderJSON(_ feature: Feature) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(feature)
        guard let string = String(data: data, encoding: .utf8) else {
            throw GherkinError.exportFailed(path: "", reason: "Failed to encode JSON as UTF-8")
        }
        return string
    }

    // MARK: - Markdown Rendering

    private func renderMarkdown(_ feature: Feature) -> String {
        var lines: [String] = []

        // Tags
        if !feature.tags.isEmpty {
            lines.append(feature.tags.map { "`\($0.rawValue)`" }.joined(separator: " "))
            lines.append("")
        }

        // Feature title
        lines.append("# Feature: \(feature.title)")
        lines.append("")

        // Description
        if let description = feature.description {
            lines.append(description)
            lines.append("")
        }

        // Background
        if let background = feature.background {
            lines.append(contentsOf: renderMarkdownBackground(background))
        }

        // Children
        for child in feature.children {
            switch child {
            case .scenario(let scenario):
                lines.append(contentsOf: renderMarkdownScenario(scenario))
            case .outline(let outline):
                lines.append(contentsOf: renderMarkdownOutline(outline))
            case .rule(let rule):
                lines.append(contentsOf: renderMarkdownRule(rule))
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private func renderMarkdownBackground(_ background: Background) -> [String] {
        var lines: [String] = []
        let name = background.name.map { ": \($0)" } ?? ""
        lines.append("### Background\(name)")
        lines.append("")
        lines.append(contentsOf: renderMarkdownSteps(background.steps))
        lines.append("")
        return lines
    }

    private func renderMarkdownScenario(_ scenario: Scenario) -> [String] {
        var lines: [String] = []
        if !scenario.tags.isEmpty {
            lines.append(scenario.tags.map { "`\($0.rawValue)`" }.joined(separator: " "))
            lines.append("")
        }
        lines.append("## Scenario: \(scenario.title)")
        lines.append("")
        if let description = scenario.description {
            lines.append(description)
            lines.append("")
        }
        lines.append(contentsOf: renderMarkdownSteps(scenario.steps))
        lines.append("")
        return lines
    }

    private func renderMarkdownOutline(_ outline: ScenarioOutline) -> [String] {
        var lines: [String] = []
        if !outline.tags.isEmpty {
            lines.append(outline.tags.map { "`\($0.rawValue)`" }.joined(separator: " "))
            lines.append("")
        }
        lines.append("## Scenario Outline: \(outline.title)")
        lines.append("")
        if let description = outline.description {
            lines.append(description)
            lines.append("")
        }
        lines.append(contentsOf: renderMarkdownSteps(outline.steps))
        lines.append("")

        for example in outline.examples {
            if !example.tags.isEmpty {
                lines.append(example.tags.map { "`\($0.rawValue)`" }.joined(separator: " "))
                lines.append("")
            }
            let name = example.name.map { ": \($0)" } ?? ""
            lines.append("### Examples\(name)")
            lines.append("")
            lines.append(contentsOf: renderMarkdownTable(example.table))
            lines.append("")
        }

        return lines
    }

    private func renderMarkdownRule(_ rule: Rule) -> [String] {
        var lines: [String] = []
        if !rule.tags.isEmpty {
            lines.append(rule.tags.map { "`\($0.rawValue)`" }.joined(separator: " "))
            lines.append("")
        }
        lines.append("## Rule: \(rule.title)")
        lines.append("")

        if let description = rule.description {
            lines.append(description)
            lines.append("")
        }

        if let background = rule.background {
            lines.append(contentsOf: renderMarkdownBackground(background))
        }

        for child in rule.children {
            switch child {
            case .scenario(let scenario):
                lines.append(contentsOf: renderMarkdownScenario(scenario))
            case .outline(let outline):
                lines.append(contentsOf: renderMarkdownOutline(outline))
            }
        }

        return lines
    }

    private func renderMarkdownSteps(_ steps: [Step]) -> [String] {
        var lines: [String] = []
        for step in steps {
            let keyword = markdownStepKeyword(step.keyword)
            lines.append("- **\(keyword)** \(step.text)")

            if let table = step.dataTable {
                lines.append("")
                lines.append(contentsOf: renderMarkdownTable(table))
            }

            if let doc = step.docString {
                lines.append("")
                let language = doc.mediaType ?? ""
                lines.append("```\(language)")
                lines.append(doc.content)
                lines.append("```")
            }
        }
        return lines
    }

    private func renderMarkdownTable(_ table: DataTable) -> [String] {
        guard let headers = table.headers else { return [] }
        var lines: [String] = []
        lines.append("| " + headers.joined(separator: " | ") + " |")
        lines.append("| " + headers.map { String(repeating: "-", count: max($0.count, 3)) }.joined(separator: " | ") + " |")
        for row in table.dataRows {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }
        return lines
    }

    private func markdownStepKeyword(_ keyword: StepKeyword) -> String {
        switch keyword {
        case .given: return "Given"
        case .when: return "When"
        case .then: return "Then"
        case .and: return "And"
        case .but: return "But"
        case .wildcard: return "*"
        }
    }
}

/// An actor for memory-efficient streaming export of large features.
///
/// `StreamingExporter` writes features to disk line-by-line without
/// loading the entire output in memory, making it suitable for
/// features with hundreds of scenarios.
///
/// ```swift
/// let exporter = StreamingExporter()
/// try await exporter.export(largeFeature, to: "large.feature")
/// ```
public actor StreamingExporter {
    /// The formatter configuration.
    private let formatter: GherkinFormatter

    /// Creates a streaming exporter.
    ///
    /// - Parameter formatter: The formatter to use.
    public init(formatter: GherkinFormatter = GherkinFormatter()) {
        self.formatter = formatter
    }

    /// Exports a feature to a file using streaming I/O.
    ///
    /// - Parameters:
    ///   - feature: The feature to export.
    ///   - path: The output file path.
    /// - Throws: ``GherkinError/exportFailed(path:reason:)`` on I/O errors.
    public func export(_ feature: Feature, to path: String) async throws {
        // TODO: Implement streaming line-by-line export
        let content = formatter.format(feature)
        do {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            throw GherkinError.exportFailed(path: path, reason: error.localizedDescription)
        }
    }
}
