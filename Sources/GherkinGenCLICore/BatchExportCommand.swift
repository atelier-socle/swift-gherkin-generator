import ArgumentParser
import Foundation
import GherkinGenerator

/// Batch-exports `.feature` files from a source directory to a target directory.
struct BatchExportCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "batch-export",
        abstract: "Batch-export .feature files from a source directory to a target directory."
    )

    @Argument(help: "Source directory containing .feature files.")
    var directory: String

    @Option(name: .long, help: "Output directory (required).")
    var output: String

    @Option(name: .long, help: "Export format: feature, json, or markdown (default: feature).")
    var format: ExportFormatOption = .feature

    enum ExportFormatOption: String, ExpressibleByArgument, Sendable {
        case feature
        case json
        case markdown

        var exportFormat: ExportFormat {
            switch self {
            case .feature: .feature
            case .json: .json
            case .markdown: .markdown
            }
        }
    }

    func run() async throws {
        try validateSourceDirectory()
        let (features, importErrors) = try await importFeatures()

        if features.isEmpty {
            print(ANSIColor.yellow("No valid .feature files found in \(directory)"))
            return
        }

        let exportErrors = try await exportAndReport(features)

        printSummary(
            total: features.count,
            exportErrors: exportErrors,
            importErrors: importErrors
        )

        if exportErrors > 0 {
            throw ExitCode.failure
        }
    }

    private func validateSourceDirectory() throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: directory, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            throw ValidationError("Source path is not a directory: '\(directory)'")
        }
    }

    private func importFeatures() async throws -> ([Feature], Int) {
        let importer = BatchImporter()
        let importResults = try await importer.importDirectory(at: directory, recursive: true)

        var features: [Feature] = []
        var importErrors = 0
        for result in importResults {
            switch result {
            case .success(let feature):
                features.append(feature)
            case .failure(let error):
                importErrors += 1
                print(ANSIColor.red("\u{2717}") + " Parse error: \(error.localizedDescription)")
            }
        }
        return (features, importErrors)
    }

    private func exportAndReport(_ features: [Feature]) async throws -> Int {
        let batchExporter = BatchExporter()
        let results = try await batchExporter.exportAll(
            features,
            to: output,
            format: format.exportFormat
        )

        var exportErrors = 0
        for (index, result) in results.enumerated() {
            let title = features[index].title
            switch result {
            case .success(let path):
                let fraction = Int(Double(index + 1) / Double(results.count) * 100)
                print(ANSIColor.green("\u{2713}") + " [\(fraction)%] \(title) \u{2192} \(path)")
            case .failure(let error):
                exportErrors += 1
                print(ANSIColor.red("\u{2717}") + " \(title): \(error.localizedDescription)")
            }
        }
        return exportErrors
    }

    private func printSummary(total: Int, exportErrors: Int, importErrors: Int) {
        let succeeded = total - exportErrors
        print("\n\(ANSIColor.bold("Done:")) \(succeeded)/\(total) features exported to \(output)")
        if importErrors > 0 {
            print(ANSIColor.yellow("\(importErrors) file(s) failed to parse."))
        }
    }
}
