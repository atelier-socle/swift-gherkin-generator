import Foundation

#if canImport(FoundationXML)
    import FoundationXML
#endif

/// Configuration for Excel (.xlsx) import, mapping column headers to Gherkin step types.
///
/// ```swift
/// let config = ExcelImportConfiguration(
///     scenarioColumn: "Scenario",
///     givenColumn: "Given",
///     whenColumn: "When",
///     thenColumn: "Then"
/// )
/// let parser = ExcelParser(configuration: config)
/// let feature = try parser.parse(xlsxData, featureTitle: "My Feature")
/// ```
public struct ExcelImportConfiguration: Sendable, Hashable {
    /// The column header name containing scenario titles.
    public let scenarioColumn: String

    /// The column header name containing `Given` step text.
    public let givenColumn: String

    /// The column header name containing `When` step text.
    public let whenColumn: String

    /// The column header name containing `Then` step text.
    public let thenColumn: String

    /// An optional column header name containing tags (space or comma separated).
    public let tagColumn: String?

    /// The zero-based worksheet index to read. Defaults to `0` (first sheet).
    public let sheetIndex: Int

    /// Creates an Excel import configuration.
    ///
    /// - Parameters:
    ///   - scenarioColumn: The column header for scenario titles.
    ///   - givenColumn: The column header for Given steps.
    ///   - whenColumn: The column header for When steps.
    ///   - thenColumn: The column header for Then steps.
    ///   - tagColumn: An optional column header for tags. Defaults to `nil`.
    ///   - sheetIndex: The zero-based worksheet index. Defaults to `0`.
    public init(
        scenarioColumn: String,
        givenColumn: String,
        whenColumn: String,
        thenColumn: String,
        tagColumn: String? = nil,
        sheetIndex: Int = 0
    ) {
        self.scenarioColumn = scenarioColumn
        self.givenColumn = givenColumn
        self.whenColumn = whenColumn
        self.thenColumn = thenColumn
        self.tagColumn = tagColumn
        self.sheetIndex = sheetIndex
    }
}

/// A parser that imports Gherkin features from Excel `.xlsx` files.
///
/// Excel files are OOXML archives containing XML worksheets and a shared
/// string table. This parser reads the ZIP structure, extracts the shared
/// strings and the target worksheet, then maps columns to Gherkin steps
/// using ``ExcelImportConfiguration``.
///
/// ```swift
/// let config = ExcelImportConfiguration(
///     scenarioColumn: "Scenario",
///     givenColumn: "Given",
///     whenColumn: "When",
///     thenColumn: "Then"
/// )
/// let data = try Data(contentsOf: URL(fileURLWithPath: "tests.xlsx"))
/// let feature = try ExcelParser(configuration: config).parse(data, featureTitle: "Auth")
/// ```
public struct ExcelParser: Sendable {
    /// The import configuration.
    public let configuration: ExcelImportConfiguration

    /// Creates an Excel parser with the given configuration.
    ///
    /// - Parameter configuration: The column mapping configuration.
    public init(configuration: ExcelImportConfiguration) {
        self.configuration = configuration
    }

    /// Parses an Excel `.xlsx` file into a ``Feature``.
    ///
    /// - Parameters:
    ///   - data: The raw `.xlsx` file data.
    ///   - featureTitle: The title for the generated feature.
    /// - Returns: The parsed feature.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if the file cannot be parsed.
    public func parse(_ data: Data, featureTitle: String) throws -> Feature {
        let zip: ZIPReader
        do {
            zip = try ZIPReader(data)
        } catch {
            throw GherkinError.importFailed(path: "", reason: "Invalid xlsx archive: \(error)")
        }

        let sharedStrings = try parseSharedStrings(from: zip)
        let rows = try parseWorksheet(from: zip, sharedStrings: sharedStrings)

        guard let headers = rows.first, !headers.isEmpty else {
            throw GherkinError.importFailed(path: "", reason: "Excel file has no header row")
        }

        let indices = try resolveColumnIndices(headers: headers)
        let children = parseDataRows(Array(rows.dropFirst()), indices: indices)

        return Feature(title: featureTitle, children: children)
    }

    // MARK: - Shared Strings

    private func parseSharedStrings(from zip: ZIPReader) throws -> [String] {
        let path = "xl/sharedStrings.xml"
        guard zip.filenames.contains(path) else {
            return []
        }
        let xmlData: Data
        do {
            xmlData = try zip.extract(filename: path)
        } catch {
            throw GherkinError.importFailed(
                path: path, reason: "Cannot extract shared strings: \(error)"
            )
        }
        let delegate = SharedStringsParserDelegate()
        let parser = XMLParser(data: xmlData)
        parser.delegate = delegate
        guard parser.parse() else {
            throw GherkinError.importFailed(
                path: path, reason: "Failed to parse shared strings XML"
            )
        }
        return delegate.strings
    }

    // MARK: - Worksheet

    private func parseWorksheet(
        from zip: ZIPReader,
        sharedStrings: [String]
    ) throws -> [[String]] {
        let sheetPath = resolveSheetPath(from: zip)
        guard let path = sheetPath else {
            throw GherkinError.importFailed(
                path: "",
                reason: "Worksheet at index \(configuration.sheetIndex) not found"
            )
        }
        let xmlData: Data
        do {
            xmlData = try zip.extract(filename: path)
        } catch {
            throw GherkinError.importFailed(
                path: path, reason: "Cannot extract worksheet: \(error)"
            )
        }
        let delegate = WorksheetParserDelegate(sharedStrings: sharedStrings)
        let parser = XMLParser(data: xmlData)
        parser.delegate = delegate
        guard parser.parse() else {
            throw GherkinError.importFailed(
                path: path, reason: "Failed to parse worksheet XML"
            )
        }
        return delegate.rows
    }

    private func resolveSheetPath(from zip: ZIPReader) -> String? {
        let standardPath = "xl/worksheets/sheet\(configuration.sheetIndex + 1).xml"
        if zip.filenames.contains(standardPath) {
            return standardPath
        }
        let worksheets = zip.filenames
            .filter { $0.hasPrefix("xl/worksheets/") && $0.hasSuffix(".xml") }
            .sorted()
        guard configuration.sheetIndex < worksheets.count else { return nil }
        return worksheets[configuration.sheetIndex]
    }

    // MARK: - Column Resolution

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

    // MARK: - Row Parsing

    private func parseDataRows(
        _ rows: [[String]],
        indices: ColumnIndices
    ) -> [FeatureChild] {
        var children: [FeatureChild] = []

        for row in rows {
            let title = cellValue(row, at: indices.scenario)
            guard !title.isEmpty else { continue }

            let steps = buildSteps(from: row, indices: indices)
            let tags = buildTags(from: row, tagIndex: indices.tag)
            children.append(.scenario(Scenario(title: title, tags: tags, steps: steps)))
        }

        return children
    }

    private func buildSteps(from row: [String], indices: ColumnIndices) -> [Step] {
        var steps: [Step] = []
        let mappings: [(Int, StepKeyword)] = [
            (indices.given, .given),
            (indices.when, .when),
            (indices.then, .then)
        ]
        for (index, keyword) in mappings {
            let text = cellValue(row, at: index)
            if !text.isEmpty {
                steps.append(Step(keyword: keyword, text: text))
            }
        }
        return steps
    }

    private func buildTags(from row: [String], tagIndex: Int?) -> [Tag] {
        guard let tagIdx = tagIndex else { return [] }
        let tagText = cellValue(row, at: tagIdx)
        guard !tagText.isEmpty else { return [] }
        let separators = CharacterSet.whitespaces.union(CharacterSet(charactersIn: ","))
        return tagText.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { Tag($0) }
    }

    // MARK: - Helpers

    private func buildColumnMap(headers: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (index, header) in headers.enumerated() {
            let trimmed = header.trimmingCharacters(in: .whitespacesAndNewlines)
            map[trimmed] = index
        }
        return map
    }

    private func cellValue(_ row: [String], at index: Int) -> String {
        guard index < row.count else { return "" }
        return row[index]
    }
}

// MARK: - SharedStringsParserDelegate

/// SAX parser delegate for OOXML `sharedStrings.xml`.
private final class SharedStringsParserDelegate: NSObject, XMLParserDelegate {
    var strings: [String] = []
    private var currentText = ""
    private var insideSI = false
    private var insideT = false

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        switch elementName {
        case "si":
            insideSI = true
            currentText = ""
        case "t" where insideSI:
            insideT = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideT {
            currentText += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        switch elementName {
        case "t":
            insideT = false
        case "si":
            strings.append(currentText)
            insideSI = false
        default:
            break
        }
    }
}

// MARK: - WorksheetParserDelegate

/// SAX parser delegate for OOXML worksheet XML.
private final class WorksheetParserDelegate: NSObject, XMLParserDelegate {
    var rows: [[String]] = []
    private let sharedStrings: [String]
    private var currentRow: [String] = []
    private var currentCellColumn = 0
    private var currentCellType = ""
    private var currentValue = ""
    private var insideValue = false
    private var insideInlineString = false
    private var insideText = false
    private var insideSheetData = false

    init(sharedStrings: [String]) {
        self.sharedStrings = sharedStrings
        super.init()
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        guard insideSheetData || elementName == "sheetData" else { return }

        switch elementName {
        case "sheetData":
            insideSheetData = true
        case "row":
            currentRow = []
        case "c":
            currentCellType = attributes["t"] ?? ""
            currentCellColumn = Self.columnIndex(from: attributes["r"] ?? "A1")
            currentValue = ""
        case "v":
            insideValue = true
            currentValue = ""
        case "is":
            insideInlineString = true
        case "t" where insideInlineString:
            insideText = true
            currentValue = ""
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideValue || insideText {
            currentValue += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        switch elementName {
        case "sheetData":
            insideSheetData = false
        case "v":
            insideValue = false
        case "t":
            insideText = false
        case "is":
            insideInlineString = false
        case "c" where insideSheetData:
            let resolvedValue = resolveValue()
            while currentRow.count <= currentCellColumn {
                currentRow.append("")
            }
            currentRow[currentCellColumn] = resolvedValue
        case "row" where insideSheetData:
            if !currentRow.isEmpty {
                rows.append(currentRow)
            }
        default:
            break
        }
    }

    private func resolveValue() -> String {
        if currentCellType == "s" {
            guard let index = Int(currentValue), index < sharedStrings.count else { return "" }
            return sharedStrings[index]
        }
        return currentValue
    }

    /// Converts an Excel cell reference (e.g. "B3") to a zero-based column index.
    static func columnIndex(from reference: String) -> Int {
        let letters = reference.prefix(while: { $0.isLetter })
        var index = 0
        for char in letters.uppercased() {
            guard let scalar = char.unicodeScalars.first else { continue }
            let letterValue = Int(scalar.value) - 65
            index = index * 26 + letterValue + 1
        }
        return index - 1
    }
}
