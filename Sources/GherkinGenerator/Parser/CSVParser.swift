import Foundation

/// Configuration for CSV import, mapping column names to Gherkin step types.
///
/// ```swift
/// let config = CSVImportConfiguration(
///     scenarioColumn: "Scenario",
///     givenColumn: "Given",
///     whenColumn: "When",
///     thenColumn: "Then"
/// )
/// let parser = CSVParser(configuration: config)
/// let feature = try parser.parse(csvString, featureTitle: "My Feature")
/// ```
public struct CSVImportConfiguration: Sendable, Hashable {
    /// The delimiter character separating columns.
    public let delimiter: Character

    /// The column name containing scenario titles.
    public let scenarioColumn: String

    /// The column name containing `Given` step text.
    public let givenColumn: String

    /// The column name containing `When` step text.
    public let whenColumn: String

    /// The column name containing `Then` step text.
    public let thenColumn: String

    /// An optional column name containing tags (space or comma separated).
    public let tagColumn: String?

    /// Creates a CSV import configuration.
    ///
    /// - Parameters:
    ///   - delimiter: The delimiter character. Defaults to `,`.
    ///   - scenarioColumn: The column name for scenario titles.
    ///   - givenColumn: The column name for Given steps.
    ///   - whenColumn: The column name for When steps.
    ///   - thenColumn: The column name for Then steps.
    ///   - tagColumn: An optional column name for tags. Defaults to `nil`.
    public init(
        delimiter: Character = ",",
        scenarioColumn: String,
        givenColumn: String,
        whenColumn: String,
        thenColumn: String,
        tagColumn: String? = nil
    ) {
        self.delimiter = delimiter
        self.scenarioColumn = scenarioColumn
        self.givenColumn = givenColumn
        self.whenColumn = whenColumn
        self.thenColumn = thenColumn
        self.tagColumn = tagColumn
    }
}

/// A parser that imports Gherkin features from CSV data.
///
/// Each row in the CSV represents a scenario with columns mapped to
/// Given, When, and Then steps via ``CSVImportConfiguration``.
///
/// ```swift
/// let csv = """
/// Scenario,Given,When,Then
/// Login,valid credentials,user logs in,dashboard shown
/// """
/// let config = CSVImportConfiguration(
///     scenarioColumn: "Scenario",
///     givenColumn: "Given",
///     whenColumn: "When",
///     thenColumn: "Then"
/// )
/// let feature = try CSVParser(configuration: config).parse(csv, featureTitle: "Auth")
/// ```
public struct CSVParser: Sendable {
    /// The import configuration.
    public let configuration: CSVImportConfiguration

    /// Creates a CSV parser with the given configuration.
    ///
    /// - Parameter configuration: The column mapping configuration.
    public init(configuration: CSVImportConfiguration) {
        self.configuration = configuration
    }

    /// Parses CSV text into a ``Feature``.
    ///
    /// - Parameters:
    ///   - source: The CSV source string.
    ///   - featureTitle: The title for the generated feature.
    /// - Returns: The parsed feature.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if required columns are missing.
    public func parse(_ source: String, featureTitle: String) throws -> Feature {
        let lines = source.components(separatedBy: .newlines)
        guard let headerLine = lines.first, !headerLine.isEmpty else {
            throw GherkinError.importFailed(path: "", reason: "CSV is empty or has no header row")
        }

        let headers = splitCSVRow(headerLine)
        let indices = try resolveColumnIndices(headers: headers)
        let children = parseDataRows(Array(lines.dropFirst()), indices: indices)

        return Feature(title: featureTitle, children: children)
    }

    // MARK: - Private Helpers

    private struct ColumnIndices {
        let scenario: Int
        let given: Int
        let when: Int
        let then: Int
        let tag: Int?
    }

    private func resolveColumnIndices(headers: [String]) throws -> ColumnIndices {
        let columnMap = buildColumnMap(headers: headers)

        guard let scenarioIndex = columnMap[configuration.scenarioColumn] else {
            throw GherkinError.importFailed(
                path: "", reason: "Missing required column '\(configuration.scenarioColumn)'"
            )
        }
        guard let givenIndex = columnMap[configuration.givenColumn] else {
            throw GherkinError.importFailed(
                path: "", reason: "Missing required column '\(configuration.givenColumn)'"
            )
        }
        guard let whenIndex = columnMap[configuration.whenColumn] else {
            throw GherkinError.importFailed(
                path: "", reason: "Missing required column '\(configuration.whenColumn)'"
            )
        }
        guard let thenIndex = columnMap[configuration.thenColumn] else {
            throw GherkinError.importFailed(
                path: "", reason: "Missing required column '\(configuration.thenColumn)'"
            )
        }
        let tagIndex = configuration.tagColumn.flatMap { columnMap[$0] }

        return ColumnIndices(
            scenario: scenarioIndex, given: givenIndex,
            when: whenIndex, then: thenIndex, tag: tagIndex
        )
    }

    private func parseDataRows(_ lines: [String], indices: ColumnIndices) -> [FeatureChild] {
        var children: [FeatureChild] = []

        for dataLine in lines {
            let trimmed = dataLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let cells = splitCSVRow(trimmed)
            let title = cellValue(cells, at: indices.scenario)
            guard !title.isEmpty else { continue }

            let steps = buildSteps(from: cells, indices: indices)
            let tags = buildTags(from: cells, tagIndex: indices.tag)
            children.append(.scenario(Scenario(title: title, tags: tags, steps: steps)))
        }

        return children
    }

    private func buildSteps(from cells: [String], indices: ColumnIndices) -> [Step] {
        var steps: [Step] = []
        let stepMappings: [(Int, StepKeyword)] = [
            (indices.given, .given),
            (indices.when, .when),
            (indices.then, .then)
        ]
        for (index, keyword) in stepMappings {
            let text = cellValue(cells, at: index)
            if !text.isEmpty {
                steps.append(Step(keyword: keyword, text: text))
            }
        }
        return steps
    }

    private func buildTags(from cells: [String], tagIndex: Int?) -> [Tag] {
        guard let tagIdx = tagIndex else { return [] }
        let tagText = cellValue(cells, at: tagIdx)
        guard !tagText.isEmpty else { return [] }
        return parseTags(tagText)
    }

    // MARK: - Private Helpers

    private func splitCSVRow(_ line: String) -> [String] {
        var cells: [String] = []
        var current = ""
        var inQuotes = false

        for character in line {
            if character == "\"" {
                inQuotes.toggle()
            } else if character == configuration.delimiter, !inQuotes {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
        }

        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }

    private func buildColumnMap(headers: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            map[header] = index
        }
        return map
    }

    private func cellValue(_ cells: [String], at index: Int) -> String {
        guard index < cells.count else { return "" }
        return cells[index]
    }

    private func parseTags(_ text: String) -> [Tag] {
        let separators = CharacterSet.whitespaces.union(CharacterSet(charactersIn: ","))
        return text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { Tag($0) }
    }
}
