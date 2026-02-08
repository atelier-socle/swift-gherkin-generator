import Foundation
import Testing

@testable import GherkinGenerator

/// End-to-end showcase: multi-language Gherkin support.
///
/// Demonstrates building the same feature in 5 languages, verifying
/// that formatted output uses localized keywords, and round-tripping
/// through parse and batch operations.
@Suite("Showcase — Multi-Language")
struct ShowcaseMultiLanguageTests {

    private struct LanguageFixture {
        let language: GherkinLanguage
        let expectedGiven: String
        let expectedWhen: String
    }

    private static let languages: [LanguageFixture] = [
        LanguageFixture(language: .english, expectedGiven: "Given ", expectedWhen: "When "),
        LanguageFixture(language: .french, expectedGiven: "Soit ", expectedWhen: "Quand "),
        LanguageFixture(language: .german, expectedGiven: "Angenommen ", expectedWhen: "Wenn "),
        LanguageFixture(language: .japanese, expectedGiven: "前提", expectedWhen: "もし"),
        LanguageFixture(language: .spanish, expectedGiven: "Dado ", expectedWhen: "Cuando ")
    ]

    // MARK: - Build in 5 Languages

    /// Builds the same login feature in English, French, German, Japanese,
    /// and Spanish — verifies that all produce valid features.
    @Test("Build login feature in 5 languages")
    func buildInFiveLanguages() throws {
        for fixture in Self.languages {
            let language = fixture.language
            let feature = try GherkinFeature(title: "Login", language: language)
                .addScenario("Successful login")
                .given("valid credentials")
                .when("the user logs in")
                .then("the dashboard is shown")
                .build()

            #expect(feature.language == language)
            #expect(feature.title == "Login")

            let errors = GherkinValidator().collectErrors(in: feature)
            #expect(errors.isEmpty, "Validation failed for \(language.name)")
        }
    }

    // MARK: - Localized Keywords in Formatted Output

    /// Formats each language variant and verifies the output contains
    /// localized keywords (e.g. "Soit" for French Given).
    @Test("Formatted output uses localized keywords")
    func localizedKeywords() throws {
        let formatter = GherkinFormatter()

        for fixture in Self.languages {
            let feature = try GherkinFeature(title: "Login", language: fixture.language)
                .addScenario("Success")
                .given("valid credentials")
                .when("the user logs in")
                .then("the dashboard is shown")
                .build()

            let output = formatter.format(feature)

            // The formatted output must contain the localized step keywords
            #expect(
                output.contains(fixture.expectedGiven),
                "Expected '\(fixture.expectedGiven)' in \(fixture.language.name) output"
            )
            #expect(
                output.contains(fixture.expectedWhen),
                "Expected '\(fixture.expectedWhen)' in \(fixture.language.name) output"
            )
        }
    }

    // MARK: - Parse Round-trip per Language

    /// Formats then re-parses each language variant — verifies the parser
    /// correctly detects the language and preserves the structure.
    @Test("Round-trip format → parse preserves language and structure")
    func roundTripPerLanguage() throws {
        let formatter = GherkinFormatter()
        let parser = GherkinParser()

        for fixture in Self.languages {
            let original = try GherkinFeature(title: "Login", language: fixture.language)
                .addScenario("Success")
                .given("valid credentials")
                .when("the user logs in")
                .then("the dashboard is shown")
                .build()

            let formatted = formatter.format(original)
            let parsed = try parser.parse(formatted)

            #expect(
                parsed.language == fixture.language,
                "Language mismatch for \(fixture.language.name)")
            #expect(parsed.title == "Login")
            #expect(parsed.children.count == 1)
        }
    }

    // MARK: - Batch Export → Import Round-trip

    /// Batch-exports 5 language variants to a directory, re-imports them,
    /// and verifies all languages survive the round-trip.
    @Test("Batch export and import 5 language variants")
    func batchRoundTrip() async throws {
        let tempDir = NSTemporaryDirectory() + "showcase-lang-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        var features: [Feature] = []
        for fixture in Self.languages {
            let feature = try GherkinFeature(
                title: "Login \(fixture.language.name)", language: fixture.language
            )
            .addScenario("Success")
            .given("valid credentials")
            .when("the user logs in")
            .then("the dashboard is shown")
            .build()
            features.append(feature)
        }

        let exporter = BatchExporter()
        let results = try await exporter.exportAll(features, to: tempDir)
        #expect(results.compactMap { try? $0.get() }.count == 5)

        let importer = BatchImporter()
        let imported = try await importer.importDirectory(at: tempDir)
        let importedFeatures = imported.compactMap { try? $0.get() }
        #expect(importedFeatures.count == 5)

        let importedLanguages = Set(importedFeatures.map(\.language.code))
        #expect(importedLanguages.contains("en"))
        #expect(importedLanguages.contains("fr"))
        #expect(importedLanguages.contains("de"))
        #expect(importedLanguages.contains("ja"))
        #expect(importedLanguages.contains("es"))
    }

    // MARK: - Language Registry

    /// Verifies the language registry contains 70+ languages.
    @Test("Language registry has 70+ languages")
    func languageRegistryCount() {
        #expect(GherkinLanguage.all.count >= 70)
    }

    /// Looks up 10 different language codes and verifies they resolve correctly.
    @Test("Lookup 10 language codes")
    func lookupLanguageCodes() {
        let codes = ["en", "fr", "de", "es", "ja", "zh-CN", "ru", "ar", "ko", "pt"]
        for code in codes {
            let language = GherkinLanguage(code: code)
            #expect(language != nil, "Language code '\(code)' should exist")
            #expect(language?.code == code)
        }
    }

    /// Verifies that an unknown language code returns nil.
    @Test("Unknown language code returns nil")
    func unknownLanguageCode() {
        #expect(GherkinLanguage(code: "xx-unknown") == nil)
    }
}
