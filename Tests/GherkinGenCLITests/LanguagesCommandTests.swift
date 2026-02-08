import ArgumentParser
import GherkinGenerator
import Testing

@testable import GherkinGenCLI

@Suite("LanguagesCommand")
struct LanguagesCommandTests {

    @Test("All languages list contains en, fr, de and has 70+ entries")
    func listAllLanguages() {
        let languages = GherkinLanguage.all
        let codes = languages.map(\.code)

        #expect(codes.contains("en"))
        #expect(codes.contains("fr"))
        #expect(codes.contains("de"))
        #expect(languages.count > 70)
    }

    @Test("English language has correct keywords")
    func englishKeywords() throws {
        let language = try #require(GherkinLanguage(code: "en"))
        let keywords = language.keywords

        #expect(keywords.feature.contains("Feature"))
        #expect(keywords.scenario.contains("Scenario"))
        #expect(keywords.given.contains { $0.hasPrefix("Given") })
        #expect(keywords.when.contains { $0.hasPrefix("When") })
        #expect(keywords.then.contains { $0.hasPrefix("Then") })
    }

    @Test("Unknown language code returns nil")
    func unknownLanguage() {
        let language = GherkinLanguage(code: "xx")
        #expect(language == nil)
    }

    @Test("French language has correct metadata")
    func frenchLanguage() throws {
        let language = try #require(GherkinLanguage(code: "fr"))
        #expect(language.name == "French")
        #expect(language.nativeName == "français")
    }

    @Test("Languages command runs without error")
    func languagesCommandRuns() async throws {
        let arguments = ["languages"]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)
    }

    @Test("Languages command with --code en runs without error")
    func languagesCommandWithCode() async throws {
        let arguments = ["languages", "--code", "en"]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)
    }

    @Test("Languages command with unknown code fails")
    func languagesCommandUnknownCode() async throws {
        let arguments = ["languages", "--code", "xx"]
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
