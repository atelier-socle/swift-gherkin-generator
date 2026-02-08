import ArgumentParser
import Foundation
import GherkinGenerator

/// Converts CSV, JSON, TXT, or XLSX files to `.feature` format.
struct ConvertCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert a CSV, JSON, TXT, or XLSX file to .feature format."
    )

    @Argument(help: "Path to a .csv, .json, .txt, or .xlsx file.")
    var path: String

    @Option(name: .long, help: "Feature title (required for CSV and TXT).")
    var title: String?

    @Option(name: .long, help: "Output file path. Prints to stdout if omitted.")
    var output: String?

    @Option(name: .long, help: "CSV delimiter (default: \",\").")
    var delimiter: String = ","

    @Option(name: .long, help: "CSV column name for scenarios (default: \"Scenario\").")
    var scenarioColumn: String = "Scenario"

    @Option(name: .long, help: "CSV column name for Given steps (default: \"Given\").")
    var givenColumn: String = "Given"

    @Option(name: .long, help: "CSV column name for When steps (default: \"When\").")
    var whenColumn: String = "When"

    @Option(name: .long, help: "CSV column name for Then steps (default: \"Then\").")
    var thenColumn: String = "Then"

    @Option(name: .long, help: "CSV column name for tags (optional).")
    var tagColumn: String?

    @Option(name: .long, help: "Worksheet index for Excel files (default: 0).")
    var sheet: Int = 0

    func run() async throws {
        let fileExtension = (path as NSString).pathExtension.lowercased()
        let feature = try parseInput(fileExtension: fileExtension)
        try writeOutput(feature)
    }

    private func parseInput(fileExtension: String) throws -> Feature {
        switch fileExtension {
        case "csv":
            return try parseCSV()
        case "json":
            return try parseJSON()
        case "txt":
            return try parseTXT()
        case "xlsx":
            return try parseXLSX()
        default:
            throw ValidationError(
                "Unsupported file extension: '.\(fileExtension)'. Use .csv, .json, .txt, or .xlsx."
            )
        }
    }

    private func parseCSV() throws -> Feature {
        guard let featureTitle = title else {
            throw ValidationError("--title is required for CSV files.")
        }
        guard let delimiterChar = delimiter.first, delimiter.count == 1 else {
            throw ValidationError("Delimiter must be a single character.")
        }
        let source = try String(contentsOfFile: path, encoding: .utf8)
        let configuration = CSVImportConfiguration(
            delimiter: delimiterChar,
            scenarioColumn: scenarioColumn,
            givenColumn: givenColumn,
            whenColumn: whenColumn,
            thenColumn: thenColumn,
            tagColumn: tagColumn
        )
        return try CSVParser(configuration: configuration).parse(source, featureTitle: featureTitle)
    }

    private func parseJSON() throws -> Feature {
        let source = try String(contentsOfFile: path, encoding: .utf8)
        return try JSONFeatureParser().parse(source)
    }

    private func parseTXT() throws -> Feature {
        guard let featureTitle = title else {
            throw ValidationError("--title is required for TXT files.")
        }
        let source = try String(contentsOfFile: path, encoding: .utf8)
        return try PlainTextParser().parse(source, featureTitle: featureTitle)
    }

    private func parseXLSX() throws -> Feature {
        guard let featureTitle = title else {
            throw ValidationError("--title is required for Excel files.")
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let configuration = ExcelImportConfiguration(
            scenarioColumn: scenarioColumn,
            givenColumn: givenColumn,
            whenColumn: whenColumn,
            thenColumn: thenColumn,
            tagColumn: tagColumn,
            sheetIndex: sheet
        )
        return try ExcelParser(configuration: configuration).parse(data, featureTitle: featureTitle)
    }

    private func writeOutput(_ feature: Feature) throws {
        let formatter = GherkinFormatter()
        let formatted = formatter.format(feature)

        if let outputPath = output {
            try formatted.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print(ANSIColor.green("Converted to \(outputPath)"))
        } else {
            print(formatted, terminator: "")
        }
    }
}
