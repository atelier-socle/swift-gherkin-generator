import Foundation
import Testing

@testable import GherkinGenerator

/// End-to-end showcase: complete authentication system.
///
/// Demonstrates the full builder → validate → format → export → parse
/// round-trip using a realistic multi-scenario authentication feature.
@Suite("Showcase — Authentication System")
struct ShowcaseAuthenticationTests {

    // MARK: - Builder

    /// Builds a complete authentication feature using the fluent builder API:
    /// background, 4 scenarios with tags, And/But continuations, data table,
    /// and doc string with JSON media type.
    @Test("Build authentication feature with fluent API")
    func buildAuthenticationFeature() throws {
        let feature = try GherkinFeature(title: "User Authentication")
            .tags(["auth", "critical"])
            .description("Covers login, logout, and password reset flows.")
            .background { $0.given("the user is on the login page") }
            // Scenario 1: successful login with data table
            .addScenario("Successful login with valid credentials")
            .scenarioTags(["smoke", "happy-path"])
            .given("the following user accounts exist")
            .table([
                ["username", "password", "role"],
                ["alice", "P@ssw0rd", "admin"],
                ["bob", "Secur3!", "viewer"]
            ])
            .when("the user logs in as \"alice\" with password \"P@ssw0rd\"")
            .then("the user is redirected to the dashboard")
            .and("a welcome message is displayed")
            // Scenario 2: failed login with doc string
            .addScenario("Failed login with invalid password")
            .scenarioTags(["negative"])
            .given("a registered user \"alice\"")
            .when("the user submits an invalid password")
            .then("an error message is displayed")
            .and("the API response body is")
            .docString(
                """
                {
                  "error": "invalid_credentials",
                  "message": "The password you entered is incorrect."
                }
                """, mediaType: "application/json"
            )
            .but("the account is not locked after one attempt")
            // Scenario 3: logout
            .addScenario("User logout")
            .given("the user is logged in")
            .when("the user clicks the logout button")
            .then("the user is redirected to the login page")
            .and("the session cookie is cleared")
            // Scenario 4: password reset
            .addScenario("Password reset request")
            .given("a registered user with email \"alice@example.com\"")
            .when("the user requests a password reset")
            .then("a reset email is sent to \"alice@example.com\"")
            .and("a confirmation message is displayed")
            .build()

        #expect(feature.title == "User Authentication")
        #expect(feature.tags.count == 2)
        #expect(feature.tags.map(\.name).contains("auth"))
        #expect(feature.background != nil)
        #expect(feature.children.count == 4)

        // Verify data table on first scenario
        let firstScenario = feature.scenarios[0]
        let tableStep = firstScenario.steps.first { $0.dataTable != nil }
        #expect(tableStep != nil)
        #expect(tableStep?.dataTable?.rowCount == 3)

        // Verify doc string on second scenario
        let secondScenario = feature.scenarios[1]
        let docStep = secondScenario.steps.first { $0.docString != nil }
        #expect(docStep != nil)
        #expect(docStep?.docString?.mediaType == "application/json")
    }

    // MARK: - Validation

    /// Validates a well-formed authentication feature — expects zero errors.
    @Test("Validate authentication feature produces zero errors")
    func validateFeature() throws {
        let feature = try buildSampleFeature()
        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(errors.isEmpty, "Expected no validation errors, got: \(errors)")
    }

    // MARK: - Formatting

    /// Formats the same feature with default and compact presets and verifies
    /// that compact output is shorter.
    @Test("Format with default and compact presets")
    func formatWithPresets() throws {
        let feature = try buildSampleFeature()

        let defaultOutput = GherkinFormatter().format(feature)
        let compactOutput = GherkinFormatter(configuration: .compact).format(feature)

        #expect(defaultOutput.contains("Feature: User Authentication"))
        #expect(compactOutput.contains("Feature: User Authentication"))
        #expect(defaultOutput.contains("Background:"))
        #expect(compactOutput.count < defaultOutput.count)
    }

    // MARK: - Export

    /// Exports to .feature, JSON, and Markdown — verifies each format
    /// contains the expected content.
    @Test("Export to .feature, JSON, and Markdown")
    func exportAllFormats() throws {
        let feature = try buildSampleFeature()
        let exporter = GherkinExporter()

        let gherkin = try exporter.render(feature, format: .feature)
        #expect(gherkin.contains("Feature: User Authentication"))
        #expect(gherkin.contains("@auth"))

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("User Authentication"))
        #expect(json.contains("\"title\""))

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("User Authentication"))
        #expect(markdown.contains("#"))
    }

    // MARK: - Round-trips

    /// Round-trip: build → format as .feature → parse back → compare structure.
    @Test("Round-trip through .feature format preserves structure")
    func featureRoundTrip() throws {
        let original = try buildSampleFeature()
        let formatted = GherkinFormatter().format(original)
        let parsed = try GherkinParser().parse(formatted)

        #expect(parsed.title == original.title)
        #expect(parsed.children.count == original.children.count)
        #expect(parsed.tags.count == original.tags.count)
        #expect(parsed.background != nil)
        #expect(parsed.scenarios[0].steps.count == original.scenarios[0].steps.count)
    }

    /// Round-trip: build → JSON export → JSON parse → compare structure.
    @Test("Round-trip through JSON format preserves structure")
    func jsonRoundTrip() throws {
        let original = try buildSampleFeature()
        let json = try GherkinExporter().render(original, format: .json)
        let parsed = try JSONFeatureParser().parse(json)

        #expect(parsed.title == original.title)
        #expect(parsed.children.count == original.children.count)
        #expect(parsed.tags.count == original.tags.count)
        #expect(parsed.scenarios[1].steps.first { $0.docString != nil } != nil)
    }

    // MARK: - Helper

    private func buildSampleFeature() throws -> Feature {
        try GherkinFeature(title: "User Authentication")
            .tags(["auth", "critical"])
            .background { $0.given("the user is on the login page") }
            .addScenario("Successful login")
            .scenarioTags(["smoke"])
            .given("valid user accounts exist")
            .table([["username", "password"], ["alice", "P@ssw0rd"]])
            .when("the user logs in as \"alice\"")
            .then("the dashboard is displayed")
            .and("a welcome message appears")
            .addScenario("Failed login")
            .scenarioTags(["negative"])
            .given("invalid credentials")
            .when("the user submits credentials")
            .then("an error is shown")
            .and("the response body is")
            .docString("{\"error\": \"invalid\"}", mediaType: "application/json")
            .but("the account is not locked")
            .addScenario("Logout")
            .given("the user is logged in")
            .when("the user logs out")
            .then("the login page is displayed")
            .addScenario("Password reset")
            .given("a registered email")
            .when("the user requests a reset")
            .then("a reset email is sent")
            .build()
    }
}
