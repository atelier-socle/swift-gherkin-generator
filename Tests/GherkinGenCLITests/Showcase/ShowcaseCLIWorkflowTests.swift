import ArgumentParser
import Foundation
import Testing

@testable import GherkinGenCLICore
@testable import GherkinGenerator

/// End-to-end showcase: CLI workflow simulation.
///
/// Demonstrates the full generate → parse → validate → export → convert
/// pipeline through ArgumentParser command structs, as a user would
/// invoke them from the terminal.
@Suite("Showcase — CLI Workflow")
struct ShowcaseCLIWorkflowTests {

    // MARK: - Generate → Parse → Validate → Export

    /// Simulates a complete CLI workflow: generate a .feature file,
    /// parse it, validate it, then export to JSON and Markdown.
    @Test("Full CLI workflow: generate → parse → validate → export")
    func fullWorkflow() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let featurePath = path(tempDir, "login.feature")
        let jsonPath = path(tempDir, "login.json")
        let mdPath = path(tempDir, "login.md")

        // Step 1: Generate a .feature file
        try await run([
            "generate",
            "--title", "User Login",
            "--scenario", "Successful login",
            "--given", "a valid account",
            "--when", "the user logs in",
            "--then", "the dashboard is displayed",
            "--tag", "smoke",
            "--output", featurePath
        ])
        #expect(FileManager.default.fileExists(atPath: featurePath))

        // Step 2: Parse the generated file (summary)
        try await run(["parse", featurePath])

        // Step 3: Validate the file
        try await run(["validate", featurePath])

        // Step 4: Export to JSON
        try await run(["export", featurePath, "--format", "json", "--output", jsonPath])
        let json = try String(contentsOfFile: jsonPath, encoding: .utf8)
        #expect(json.contains("User Login"))

        // Step 5: Export to Markdown
        try await run([
            "export", featurePath, "--format", "markdown", "--output", mdPath
        ])
        let md = try String(contentsOfFile: mdPath, encoding: .utf8)
        #expect(md.contains("User Login"))
    }

    // MARK: - Generate Command

    /// Demonstrates generate with multiple steps and tags.
    @Test("GenerateCommand produces valid .feature output")
    func generateCommand() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }
        let outputPath = path(tempDir, "auth.feature")

        try await run([
            "generate",
            "--title", "Authentication",
            "--scenario", "Login",
            "--given", "valid credentials",
            "--when", "the user submits the form",
            "--then", "access is granted",
            "--tag", "auth",
            "--tag", "smoke",
            "--output", outputPath
        ])

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: Authentication"))
        #expect(content.contains("@auth"))
    }

    // MARK: - Validate Command

    /// Validates a correct file (no error) and an invalid file (throws).
    @Test("ValidateCommand: valid and invalid files")
    func validateCommand() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let validPath = path(tempDir, "valid.feature")
        try """
        Feature: OK
          Scenario: Test
            Given a state
            When an action
            Then a result
        """.write(toFile: validPath, atomically: true, encoding: .utf8)

        // Valid — should not throw
        try await run(["validate", validPath])

        let invalidPath = path(tempDir, "invalid.feature")
        try """
        Feature: Bad
          Scenario: Missing Given
            When no given
            Then a result
        """.write(toFile: invalidPath, atomically: true, encoding: .utf8)

        // Invalid — should throw
        await #expect(throws: (any Error).self) {
            try await run(["validate", invalidPath])
        }
    }

    // MARK: - Parse Command

    /// Parses with --format json via export and verifies the output is valid
    /// JSON that round-trips through JSONFeatureParser.
    @Test("Parse then export to JSON produces valid JSON")
    func parseAndExportJSON() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let featurePath = path(tempDir, "test.feature")
        try """
        Feature: Parse Test
          Scenario: Roundtrip
            Given a state
            When an action
            Then a result
        """.write(toFile: featurePath, atomically: true, encoding: .utf8)

        // Parse summary (no --output, prints to stdout)
        try await run(["parse", featurePath])

        // Export to JSON file via ExportCommand
        let jsonPath = path(tempDir, "parsed.json")
        try await run([
            "export", featurePath, "--format", "json", "--output", jsonPath
        ])

        let json = try String(contentsOfFile: jsonPath, encoding: .utf8)
        let feature = try JSONFeatureParser().parse(json)
        #expect(feature.title == "Parse Test")
    }

    // MARK: - Export Command (3 Formats)

    /// Exports a .feature file to all 3 formats and verifies each.
    @Test("ExportCommand to .feature, JSON, and Markdown")
    func exportThreeFormats() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let sourcePath = path(tempDir, "source.feature")
        try """
        Feature: Export Test
          Scenario: Example
            Given a precondition
            When an action
            Then a result
        """.write(toFile: sourcePath, atomically: true, encoding: .utf8)

        for (format, ext) in [("feature", ".feature"), ("json", ".json"), ("markdown", ".md")] {
            let outPath = path(tempDir, "out\(ext)")
            try await run([
                "export", sourcePath, "--format", format, "--output", outPath
            ])
            let content = try String(contentsOfFile: outPath, encoding: .utf8)
            #expect(content.contains("Export Test"), "\(format) output missing title")
        }
    }

    // MARK: - Convert Command (CSV + TXT)

    /// Converts a CSV and a TXT file to .feature format via ConvertCommand.
    @Test("ConvertCommand from CSV and TXT")
    func convertCSVAndTXT() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        // CSV conversion
        let csvPath = path(tempDir, "data.csv")
        try "Scenario,Given,When,Then\nLogin,credentials,submit,dashboard"
            .write(toFile: csvPath, atomically: true, encoding: .utf8)
        let csvOut = path(tempDir, "csv-out.feature")
        try await run([
            "convert", csvPath, "--title", "CSV Feature", "--output", csvOut
        ])
        let csvContent = try String(contentsOfFile: csvOut, encoding: .utf8)
        #expect(csvContent.contains("Feature: CSV Feature"))

        // TXT conversion
        let txtPath = path(tempDir, "steps.txt")
        try "Given a state\nWhen an action\nThen a result"
            .write(toFile: txtPath, atomically: true, encoding: .utf8)
        let txtOut = path(tempDir, "txt-out.feature")
        try await run([
            "convert", txtPath, "--title", "TXT Feature", "--output", txtOut
        ])
        let txtContent = try String(contentsOfFile: txtOut, encoding: .utf8)
        #expect(txtContent.contains("Feature: TXT Feature"))
    }

    // MARK: - Languages Command

    /// Lists all languages and shows keywords for French.
    @Test("LanguagesCommand lists all and shows French keywords")
    func languagesCommand() async throws {
        // List all languages — should not throw
        try await run(["languages"])

        // Show keywords for French — should not throw
        try await run(["languages", "--code", "fr"])
    }

    // MARK: - Helpers

    private func run(_ arguments: [String]) async throws {
        let command = try GherkinGen.parseAsRoot(arguments)
        if var async = command as? any AsyncParsableCommand {
            try await async.run()
        } else {
            var sync = command
            try sync.run()
        }
    }

    private func makeTempDir() -> String {
        let dir = NSTemporaryDirectory() + "showcase-cli-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true)
        return dir
    }

    private func path(_ dir: String, _ file: String) -> String {
        (dir as NSString).appendingPathComponent(file)
    }

    private func cleanup(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}
