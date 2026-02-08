import Foundation
import Testing

@testable import GherkinGenerator

/// End-to-end showcase: validation pipeline and error detection.
///
/// Demonstrates the validator catching every error type, a custom
/// validation rule, and batch validation of a mixed directory.
@Suite("Showcase — Validation Pipeline")
struct ShowcaseValidationTests {

    // MARK: - Valid Feature

    /// A well-formed feature passes all default validation rules.
    @Test("Valid feature produces zero validation errors")
    func validFeaturePassesAllRules() throws {
        let feature = try GherkinFeature(title: "Payment")
            .addScenario("Process payment")
            .given("a cart with items")
            .when("the user pays")
            .then("the payment is processed")
            .build()

        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(errors.isEmpty)
    }

    // MARK: - Each Error Type

    /// Missing Given step — StructureRule detects it.
    @Test("Detect missing Given step")
    func missingGiven() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "No Given",
                        steps: [
                            Step(keyword: .when, text: "something"),
                            Step(keyword: .then, text: "result")
                        ]))
            ])
        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(errors.contains(.missingGiven(scenario: "No Given")))
    }

    /// Missing Then step — StructureRule detects it.
    @Test("Detect missing Then step")
    func missingThen() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "No Then",
                        steps: [
                            Step(keyword: .given, text: "something"),
                            Step(keyword: .when, text: "action")
                        ]))
            ])
        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(errors.contains(.missingThen(scenario: "No Then")))
    }

    /// Duplicate consecutive steps — CoherenceRule detects it.
    @Test("Detect duplicate consecutive steps")
    func duplicateSteps() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Dup",
                        steps: [
                            Step(keyword: .given, text: "a state"),
                            Step(keyword: .given, text: "a state"),
                            Step(keyword: .when, text: "action"),
                            Step(keyword: .then, text: "result")
                        ]))
            ])
        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(errors.contains(.duplicateConsecutiveStep(step: "a state", scenario: "Dup")))
    }

    /// Invalid tag format — TagFormatRule detects it.
    @Test("Detect invalid tag format")
    func invalidTag() {
        let feature = Feature(
            title: "Test",
            tags: [Tag("valid"), Tag("")],
            children: [
                .scenario(
                    Scenario(
                        title: "S",
                        steps: [
                            Step(keyword: .given, text: "x"),
                            Step(keyword: .then, text: "y")
                        ]))
            ])
        let errors = GherkinValidator().collectErrors(in: feature)
        let hasTagError = errors.contains { error in
            if case .invalidTagFormat = error { return true }
            return false
        }
        #expect(hasTagError)
    }

    /// Inconsistent data table columns — TableConsistencyRule detects it.
    @Test("Detect inconsistent table columns")
    func inconsistentTable() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "S",
                        steps: [
                            Step(
                                keyword: .given, text: "data",
                                dataTable: DataTable(rows: [["a", "b"], ["c"]])),
                            Step(keyword: .when, text: "action"),
                            Step(keyword: .then, text: "result")
                        ]))
            ])
        let errors = GherkinValidator().collectErrors(in: feature)
        let hasTableError = errors.contains { error in
            if case .inconsistentTableColumns = error { return true }
            return false
        }
        #expect(hasTableError)
    }

    /// Undefined placeholder in outline — OutlinePlaceholderRule detects it.
    @Test("Detect undefined outline placeholder")
    func undefinedPlaceholder() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Outline",
                        steps: [
                            Step(keyword: .given, text: "the value <missing>"),
                            Step(keyword: .then, text: "it works")
                        ],
                        examples: [
                            Examples(table: DataTable(rows: [["defined"], ["val"]]))
                        ]))
            ])
        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(
            errors.contains(.undefinedPlaceholder(placeholder: "missing", scenario: "Outline")))
    }

    // MARK: - Custom Validation Rule

    /// Demonstrates a custom validation rule that limits the maximum
    /// number of scenarios in a feature.
    @Test("Custom MaxScenariosRule rejects features with too many scenarios")
    func customMaxScenariosRule() throws {
        let rule = MaxScenariosRule(limit: 2)
        let validator = GherkinValidator(rules: [rule])

        // Feature with 3 scenarios should fail
        var builder = GherkinFeature(title: "Big Feature")
        for i in 1...3 {
            builder =
                builder
                .addScenario("Scenario \(i)")
                .given("step \(i)")
                .then("result \(i)")
        }
        let feature = try builder.build()
        let errors = validator.collectErrors(in: feature)
        #expect(!errors.isEmpty, "Expected MaxScenariosRule to reject 3 scenarios")
    }

    // MARK: - Batch Validation

    /// Batch-validates a directory with a mix of valid and invalid files —
    /// verifies results are reported per file.
    @Test("Batch validate directory with mixed files")
    func batchValidation() async throws {
        let tempDir = NSTemporaryDirectory() + "showcase-val-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: tempDir) }
        try FileManager.default.createDirectory(
            atPath: tempDir, withIntermediateDirectories: true)

        let validFeature = """
            Feature: Valid
              Scenario: OK
                Given a state
                When an action
                Then a result
            """
        let invalidFeature = """
            Feature: Invalid
              Scenario: Bad
                When no given here
                Then a result
            """

        try validFeature.write(
            toFile: (tempDir as NSString).appendingPathComponent("valid.feature"),
            atomically: true, encoding: .utf8)
        try invalidFeature.write(
            toFile: (tempDir as NSString).appendingPathComponent("invalid.feature"),
            atomically: true, encoding: .utf8)

        let batchValidator = BatchValidator()
        let results = try await batchValidator.validateDirectory(at: tempDir)

        #expect(results.count == 2)
        let successes = results.filter(\.isSuccess)
        let failures = results.filter { !$0.isSuccess }
        #expect(successes.count == 1)
        #expect(failures.count == 1)
    }
}

// MARK: - Custom Rule

/// A custom validation rule that limits the number of scenarios in a feature.
/// Demonstrates how to extend the validation pipeline with domain rules.
private struct MaxScenariosRule: ValidationRule, Sendable {
    let limit: Int

    func validate(_ feature: Feature) -> [GherkinError] {
        let count = feature.scenarios.count
        if count > limit {
            return [
                .importFailed(
                    path: "",
                    reason: "Feature has \(count) scenarios, max allowed is \(limit)")
            ]
        }
        return []
    }
}
