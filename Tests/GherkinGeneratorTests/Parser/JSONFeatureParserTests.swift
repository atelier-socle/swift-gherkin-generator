import Foundation
import Testing

@testable import GherkinGenerator

@Suite("JSONFeatureParser")
struct JSONFeatureParserTests {

    private let jsonParser = JSONFeatureParser()
    private let exporter = GherkinExporter()

    // MARK: - Basic Parsing

    @Test("Parse valid JSON back to Feature")
    func parseValidJSON() throws {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(
                    Scenario(
                        title: "Success",
                        steps: [
                            Step(keyword: .given, text: "valid credentials"),
                            Step(keyword: .when, text: "user logs in"),
                            Step(keyword: .then, text: "dashboard shown")
                        ]
                    ))
            ]
        )

        let json = try exporter.render(feature, format: .json)
        let parsed = try jsonParser.parse(json)

        #expect(parsed.title == "Login")
        #expect(parsed.children.count == 1)

        guard case .scenario(let scenario) = parsed.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Success")
        #expect(scenario.steps.count == 3)
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[0].text == "valid credentials")
    }

    // MARK: - Complex Feature

    @Test("Parse JSON with all model types")
    func complexFeature() throws {
        let feature = Feature(
            title: "Complex",
            language: .french,
            tags: [Tag("smoke")],
            description: "A complex feature",
            background: Background(steps: [
                Step(keyword: .given, text: "a user")
            ]),
            children: [
                .scenario(
                    Scenario(
                        title: "Simple",
                        steps: [Step(keyword: .then, text: "it works")]
                    )),
                .outline(
                    ScenarioOutline(
                        title: "Parameterized",
                        steps: [
                            Step(keyword: .given, text: "value <val>")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["val"],
                                    ["1"],
                                    ["2"]
                                ]))
                        ]
                    )),
                .rule(
                    Rule(
                        title: "Business rule",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "Rule scenario",
                                    steps: [Step(keyword: .given, text: "in a rule")]
                                ))
                        ]
                    ))
            ],
            comments: [Comment(text: "A comment")]
        )

        let json = try exporter.render(feature, format: .json)
        let parsed = try jsonParser.parse(json)

        #expect(parsed == feature)
    }

    // MARK: - Data Parsing

    @Test("Parse from Data directly")
    func parseFromData() throws {
        let feature = Feature(title: "DataTest")
        let json = try exporter.render(feature, format: .json)
        let data = try #require(json.data(using: .utf8))
        let parsed = try jsonParser.parse(data: data)

        #expect(parsed.title == "DataTest")
    }

    // MARK: - Error Handling

    @Test("Invalid JSON throws import error")
    func invalidJSON() {
        #expect(throws: GherkinError.self) {
            try jsonParser.parse("not valid json")
        }
    }

    @Test("Empty JSON object throws import error")
    func emptyJSONObject() {
        #expect(throws: GherkinError.self) {
            try jsonParser.parse("{}")
        }
    }

    @Test("Invalid UTF-8 handled gracefully")
    func invalidData() {
        let invalidData = Data([0xFF, 0xFE])
        #expect(throws: GherkinError.self) {
            try jsonParser.parse(data: invalidData)
        }
    }
}
