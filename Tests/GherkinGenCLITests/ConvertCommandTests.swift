import ArgumentParser
import Foundation
import GherkinGenerator
import Testing

@testable import GherkinGenCLI

@Suite("ConvertCommand")
struct ConvertCommandTests {

    @Test("Convert CSV to .feature")
    func convertCSV() async throws {
        let csv = """
            Scenario,Given,When,Then
            Login,a registered user,I log in,I see the dashboard
            Logout,a logged-in user,I log out,I see the login page
            """
        let fixture = try CLIFixtureDirectory(files: ["scenarios.csv": csv])
        let outputPath = NSTemporaryDirectory() + "convert-csv-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "convert", fixture.filePath("scenarios.csv"),
            "--title", "User Auth",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: User Auth"))
        #expect(content.contains("Login"))
        #expect(content.contains("a registered user"))
    }

    @Test("Convert JSON to .feature")
    func convertJSON() async throws {
        let parser = GherkinParser()
        let sourceFeature = """
            Feature: JSON Source
              Scenario: Test
                Given a step
                When an action
                Then a result
            """
        let feature = try parser.parse(sourceFeature)
        let exporter = GherkinExporter()
        let json = try exporter.render(feature, format: .json)

        let fixture = try CLIFixtureDirectory(files: ["source.json": json])
        let outputPath = NSTemporaryDirectory() + "convert-json-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "convert", fixture.filePath("source.json"),
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: JSON Source"))
        #expect(content.contains("Test"))
    }

    @Test("Convert TXT to .feature")
    func convertTXT() async throws {
        let txt = """
            Given a precondition
            When an action is taken
            Then a result is observed
            """
        let fixture = try CLIFixtureDirectory(files: ["steps.txt": txt])
        let outputPath = NSTemporaryDirectory() + "convert-txt-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "convert", fixture.filePath("steps.txt"),
            "--title", "Text Feature",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: Text Feature"))
    }

    @Test("Unsupported extension fails")
    func unsupportedExtension() async throws {
        let fixture = try CLIFixtureDirectory(files: ["data.xml": "<xml/>"])

        let arguments = [
            "convert", fixture.filePath("data.xml"),
            "--title", "Test"
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        await #expect(throws: (any Error).self) {
            try await execute(command)
        }
    }

    @Test("CSV without --title fails")
    func csvMissingTitle() async throws {
        let csv = "Scenario,Given,When,Then\nTest,a,b,c\n"
        let fixture = try CLIFixtureDirectory(files: ["no-title.csv": csv])

        let arguments = [
            "convert", fixture.filePath("no-title.csv")
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        await #expect(throws: (any Error).self) {
            try await execute(command)
        }
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
        let dirName = "cli-convert-\(UUID().uuidString)"
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
