import ArgumentParser
import Foundation
import GherkinGenerator

/// Generates a `.feature` file from CLI arguments.
struct GenerateCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate a .feature file from command-line arguments."
    )

    @Option(name: .long, help: "Feature title.")
    var title: String

    @Option(name: .long, help: "Scenario title.")
    var scenario: String

    @Option(name: .long, parsing: .singleValue, help: "Given step (repeatable).")
    var given: [String] = []

    @Option(name: .long, parsing: .singleValue, help: "When step (repeatable).")
    var when: [String] = []

    @Option(name: .long, parsing: .singleValue, help: "Then step (repeatable).")
    var then: [String] = []

    @Option(name: .long, parsing: .singleValue, help: "Feature-level tag (repeatable).")
    var tag: [String] = []

    @Option(name: .long, help: "Language code (default: en).")
    var language: String = "en"

    @Option(name: .long, help: "Output file path. Prints to stdout if omitted.")
    var output: String?

    func run() async throws {
        guard let gherkinLanguage = GherkinLanguage(code: language) else {
            throw ValidationError("Unknown language code: '\(language)'")
        }

        var builder = GherkinFeature(title: title, language: gherkinLanguage)

        if !tag.isEmpty {
            builder = builder.tags(tag)
        }

        builder = builder.addScenario(scenario)

        for step in given {
            builder = builder.given(step)
        }
        for step in when {
            builder = builder.when(step)
        }
        for step in then {
            builder = builder.then(step)
        }

        let feature = try builder.build()
        let formatter = GherkinFormatter()
        let formatted = formatter.format(feature)

        if let outputPath = output {
            try formatted.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print(ANSIColor.green("Feature written to \(outputPath)"))
        } else {
            print(formatted, terminator: "")
        }
    }
}
