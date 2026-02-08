import ArgumentParser
import Foundation
import GherkinGenerator

/// Validates one or more `.feature` files.
struct ValidateCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate .feature file(s) for correctness."
    )

    @Argument(help: "Path to a .feature file or directory.")
    var path: String

    @Flag(name: .long, help: "Use all default validation rules (default: true).")
    var strict: Bool = false

    @Flag(name: .long, help: "Only show errors, suppress success messages.")
    var quiet: Bool = false

    func run() async throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw ValidationError("Path does not exist: '\(path)'")
        }

        if isDirectory.boolValue {
            try await validateDirectory(at: path)
        } else {
            try validateFile(at: path)
        }
    }

    private func validateDirectory(at directoryPath: String) async throws {
        let batchValidator = BatchValidator()
        let results = try await batchValidator.validateDirectory(
            at: directoryPath,
            recursive: true
        )

        var hasErrors = false

        for result in results {
            if result.isSuccess {
                if !quiet {
                    let name = result.featureTitle ?? result.path
                    print(ANSIColor.green("\u{2713}") + " \(name)")
                }
            } else {
                hasErrors = true
                let name = result.featureTitle ?? result.path
                print(ANSIColor.red("\u{2717}") + " \(name)")
                for error in result.errors {
                    print("  " + ANSIColor.red(error.localizedDescription))
                }
            }
        }

        if results.isEmpty {
            print(ANSIColor.yellow("No .feature files found in \(directoryPath)"))
        }

        if hasErrors {
            throw ExitCode.failure
        }
    }

    private func validateFile(at filePath: String) throws {
        let parser = GherkinParser()
        let feature = try parser.parse(contentsOfFile: filePath)

        let validator = GherkinValidator()
        let errors = validator.collectErrors(in: feature)

        if errors.isEmpty {
            if !quiet {
                print(ANSIColor.green("\u{2713}") + " \(feature.title)")
            }
        } else {
            print(ANSIColor.red("\u{2717}") + " \(feature.title)")
            for error in errors {
                print("  " + ANSIColor.red(error.localizedDescription))
            }
            throw ExitCode.failure
        }
    }
}
