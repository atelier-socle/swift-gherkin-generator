import ArgumentParser
import Foundation
import GherkinGenerator
import Testing

@testable import GherkinGenCLI

@Suite("ParseCommand")
struct ParseCommandTests {

    private static let sampleFeature = """
        @smoke
        Feature: Login
          As a user I want to log in.

          Scenario: Valid credentials
            Given a registered user
            When I enter valid credentials
            Then I am logged in

          Scenario: Invalid password
            Given a registered user
            When I enter an invalid password
            Then I see an error
        """

    @Test("Summary format parses feature correctly")
    func parseSummary() throws {
        let fixture = try CLIFixtureDirectory(files: ["login.feature": Self.sampleFeature])

        let parser = GherkinParser()
        let feature = try parser.parse(contentsOfFile: fixture.filePath("login.feature"))

        #expect(feature.title == "Login")
        #expect(feature.scenarios.count == 2)
        #expect(feature.tags.count == 1)
        #expect(feature.tags[0].name == "smoke")
    }

    @Test("JSON format produces valid JSON round-trip")
    func parseJson() throws {
        let fixture = try CLIFixtureDirectory(files: ["login.feature": Self.sampleFeature])

        let parser = GherkinParser()
        let feature = try parser.parse(contentsOfFile: fixture.filePath("login.feature"))

        let exporter = GherkinExporter()
        let jsonOutput = try exporter.render(feature, format: .json)

        #expect(!jsonOutput.isEmpty)

        let jsonParser = JSONFeatureParser()
        let roundTripped = try jsonParser.parse(jsonOutput)
        #expect(roundTripped.title == "Login")
        #expect(roundTripped.scenarios.count == 2)
    }

    @Test("Parse command runs with summary format")
    func parseCommandSummary() async throws {
        let fixture = try CLIFixtureDirectory(files: ["login.feature": Self.sampleFeature])

        let arguments = ["parse", fixture.filePath("login.feature"), "--format", "summary"]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)
    }

    @Test("Parse command runs with json format")
    func parseCommandJson() async throws {
        let fixture = try CLIFixtureDirectory(files: ["login.feature": Self.sampleFeature])

        let arguments = ["parse", fixture.filePath("login.feature"), "--format", "json"]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)
    }

    @Test("Nonexistent file fails")
    func nonexistentFile() async throws {
        let arguments = ["parse", "/nonexistent/file.feature"]
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
        let dirName = "cli-parse-\(UUID().uuidString)"
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
