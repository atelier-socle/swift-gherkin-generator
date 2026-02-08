import ArgumentParser
import Foundation
import GherkinGenerator

/// Converts CSV, JSON, or TXT files to `.feature` format.
struct ConvertCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert a CSV, JSON, or TXT file to .feature format."
    )

    @Argument(help: "Path to a .csv, .json, or .txt file.")
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

    func run() async throws {
        let fileExtension = (path as NSString).pathExtension.lowercased()
        let source = try String(contentsOfFile: path, encoding: .utf8)

        let feature: Feature

        switch fileExtension {
        case "csv":
            guard let featureTitle = title else {
                throw ValidationError("--title is required for CSV files.")
            }
            guard let delimiterChar = delimiter.first, delimiter.count == 1 else {
                throw ValidationError("Delimiter must be a single character.")
            }
            let configuration = CSVImportConfiguration(
                delimiter: delimiterChar,
                scenarioColumn: scenarioColumn,
                givenColumn: givenColumn,
                whenColumn: whenColumn,
                thenColumn: thenColumn,
                tagColumn: tagColumn
            )
            let csvParser = CSVParser(configuration: configuration)
            feature = try csvParser.parse(source, featureTitle: featureTitle)

        case "json":
            let jsonParser = JSONFeatureParser()
            feature = try jsonParser.parse(source)

        case "txt":
            guard let featureTitle = title else {
                throw ValidationError("--title is required for TXT files.")
            }
            let textParser = PlainTextParser()
            feature = try textParser.parse(source, featureTitle: featureTitle)

        default:
            throw ValidationError(
                "Unsupported file extension: '.\(fileExtension)'. Use .csv, .json, or .txt."
            )
        }

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
