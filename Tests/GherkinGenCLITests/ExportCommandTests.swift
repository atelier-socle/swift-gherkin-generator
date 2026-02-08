import ArgumentParser
import Foundation
import GherkinGenerator
import Testing

@testable import GherkinGenCLICore

@Suite("ExportCommand")
struct ExportCommandTests {

    private static let sampleFeature = """
        Feature: Checkout
          Scenario: Empty cart
            Given an empty cart
            When I proceed to checkout
            Then I see a warning
        """

    @Test("Export to .feature format")
    func exportFeature() async throws {
        let fixture = try CLIFixtureDirectory(files: ["input.feature": Self.sampleFeature])
        let outputPath = NSTemporaryDirectory() + "export-feature-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "export", fixture.filePath("input.feature"),
            "--format", "feature",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: Checkout"))
        #expect(content.contains("Empty cart"))
    }

    @Test("Export to JSON format")
    func exportJson() async throws {
        let fixture = try CLIFixtureDirectory(files: ["input.feature": Self.sampleFeature])
        let outputPath = NSTemporaryDirectory() + "export-json-\(UUID().uuidString).json"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "export", fixture.filePath("input.feature"),
            "--format", "json",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Checkout"))
        #expect(content.contains("Empty cart"))
    }

    @Test("Export to Markdown format")
    func exportMarkdown() async throws {
        let fixture = try CLIFixtureDirectory(files: ["input.feature": Self.sampleFeature])
        let outputPath = NSTemporaryDirectory() + "export-md-\(UUID().uuidString).md"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "export", fixture.filePath("input.feature"),
            "--format", "markdown",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Checkout"))
        #expect(content.contains("Empty cart"))
    }
}

/// Executes a parsed ArgumentParser command.
private func execute(_ command: any ParsableCommand) async throws {
    if var asyncCommand = command as? any AsyncParsableCommand {
        try await asyncCommand.run()
    } else {
        var mutableCommand = command
        try mutableCommand.run()
    }
}

/// Temporary directory helper for CLI tests.
private final class CLIFixtureDirectory: @unchecked Sendable {
    let path: String

    init(files: [String: String]) throws {
        let tempDir = NSTemporaryDirectory()
        let dirName = "cli-export-\(UUID().uuidString)"
        let dirPath = (tempDir as NSString).appendingPathComponent(dirName)
        try FileManager.default.createDirectory(
            atPath: dirPath, withIntermediateDirectories: true
        )
        self.path = dirPath
        for (name, content) in files {
            let filePath = (dirPath as NSString).appendingPathComponent(name)
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
    }

    func filePath(_ name: String) -> String {
        (path as NSString).appendingPathComponent(name)
    }

    deinit {
        try? FileManager.default.removeItem(atPath: path)
    }
}
