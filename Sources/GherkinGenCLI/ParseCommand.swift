import ArgumentParser
import Foundation
import GherkinGenerator

/// Parses a `.feature` file and displays information.
struct ParseCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parse a .feature file and display its structure."
    )

    @Argument(help: "Path to a .feature file.")
    var path: String

    @Option(name: .long, help: "Output format: summary or json (default: summary).")
    var format: OutputFormat = .summary

    enum OutputFormat: String, ExpressibleByArgument, Sendable {
        case summary
        case json
    }

    func run() async throws {
        let parser = GherkinParser()
        let feature = try parser.parse(contentsOfFile: path)

        switch format {
        case .summary:
            printSummary(feature)
        case .json:
            let exporter = GherkinExporter()
            let jsonOutput = try exporter.render(feature, format: .json)
            print(jsonOutput)
        }
    }

    private func printSummary(_ feature: Feature) {
        print(ANSIColor.bold("Feature:") + " \(feature.title)")
        print(
            ANSIColor.bold("Language:")
                + " \(feature.language.name) (\(feature.language.code))"
        )

        let scenarioCount = feature.scenarios.count
        let outlineCount = feature.outlines.count
        let ruleCount = feature.rules.count

        print(ANSIColor.bold("Scenarios:") + " \(scenarioCount)")
        print(ANSIColor.bold("Outlines:") + " \(outlineCount)")
        print(ANSIColor.bold("Rules:") + " \(ruleCount)")

        if !feature.tags.isEmpty {
            let tagNames = feature.tags.map(\.rawValue).joined(separator: ", ")
            print(ANSIColor.bold("Tags:") + " \(tagNames)")
        }

        if let description = feature.description {
            print(ANSIColor.bold("Description:") + " \(description)")
        }
    }
}
