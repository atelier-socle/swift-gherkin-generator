import ArgumentParser
import Foundation
import GherkinGenerator
import Testing

@testable import GherkinGenCLICore

@Suite("ValidateCommand")
struct ValidateCommandTests {

    private static let validFeature = """
        Feature: Valid
          Scenario: Test
            Given a precondition
            When an action
            Then a result
        """

    private static let invalidFeature = """
        Feature: Invalid
          Scenario: No steps
        """

    @Test("Valid .feature file passes validation")
    func validateValidFile() async throws {
        let fixture = try CLIFixtureDirectory(files: ["valid.feature": Self.validFeature])

        let arguments = ["validate", fixture.filePath("valid.feature")]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)
    }

    @Test("Invalid .feature file fails validation")
    func validateInvalidFile() async throws {
        let fixture = try CLIFixtureDirectory(
            files: ["invalid.feature": Self.invalidFeature]
        )

        let arguments = ["validate", fixture.filePath("invalid.feature")]
        let command = try GherkinGen.parseAsRoot(arguments)
        await #expect(throws: (any Error).self) {
            try await execute(command)
        }
    }

    @Test("Directory validation with mixed files")
    func validateDirectory() async throws {
        let fixture = try CLIFixtureDirectory(
            files: [
                "good.feature": Self.validFeature,
                "bad.feature": Self.invalidFeature
            ]
        )

        let arguments = ["validate", fixture.path]
        let command = try GherkinGen.parseAsRoot(arguments)
        await #expect(throws: (any Error).self) {
            try await execute(command)
        }
    }

    @Test("Nonexistent path fails")
    func nonexistentPath() async throws {
        let arguments = ["validate", "/nonexistent/path/file.feature"]
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
        let dirName = "cli-validate-\(UUID().uuidString)"
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
