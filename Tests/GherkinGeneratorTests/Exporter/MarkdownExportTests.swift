import Testing

@testable import GherkinGenerator

@Suite("GherkinExporter - Markdown")
struct MarkdownExportTests {

    private let exporter = GherkinExporter()

    // MARK: - Basic Markdown Export

    @Test("Export simple feature to Markdown")
    func simpleFeatureMarkdown() throws {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(
                    Scenario(
                        title: "Successful login",
                        steps: [
                            Step(keyword: .given, text: "a valid account"),
                            Step(keyword: .when, text: "the user logs in"),
                            Step(keyword: .then, text: "the dashboard is displayed")
                        ]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("# Feature: Login"))
        #expect(markdown.contains("## Scenario: Successful login"))
        #expect(markdown.contains("- **Given** a valid account"))
        #expect(markdown.contains("- **When** the user logs in"))
        #expect(markdown.contains("- **Then** the dashboard is displayed"))
    }

    // MARK: - Tags

    @Test("Tags rendered as code badges")
    func tagsAsBadges() throws {
        let feature = Feature(
            title: "Tagged",
            tags: [Tag("smoke"), Tag("critical")],
            children: [
                .scenario(
                    Scenario(
                        title: "Test",
                        tags: [Tag("wip")],
                        steps: [Step(keyword: .given, text: "something")]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("`@smoke`"))
        #expect(markdown.contains("`@critical`"))
        #expect(markdown.contains("`@wip`"))
    }

    // MARK: - Description

    @Test("Feature description rendered as paragraph")
    func featureDescription() throws {
        let feature = Feature(
            title: "Described",
            description: "This feature covers authentication flows."
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("This feature covers authentication flows."))
    }

    // MARK: - Data Table

    @Test("Data table rendered as Markdown table")
    func dataTableAsMarkdownTable() throws {
        let feature = Feature(
            title: "Tables",
            children: [
                .scenario(
                    Scenario(
                        title: "Users",
                        steps: [
                            Step(
                                keyword: .given, text: "the following users",
                                dataTable: DataTable(rows: [
                                    ["name", "role"],
                                    ["Alice", "admin"],
                                    ["Bob", "user"]
                                ])
                            )
                        ]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("| name | role |"))
        #expect(markdown.contains("| --- | --- |") || markdown.contains("| ---- | ---- |"))
        #expect(markdown.contains("| Alice | admin |"))
        #expect(markdown.contains("| Bob | user |"))
    }

    // MARK: - Doc String

    @Test("Doc string rendered as fenced code block")
    func docStringAsCodeBlock() throws {
        let feature = Feature(
            title: "DocStrings",
            children: [
                .scenario(
                    Scenario(
                        title: "JSON payload",
                        steps: [
                            Step(
                                keyword: .given, text: "a request body",
                                docString: DocString(
                                    content: "{\"key\": \"value\"}",
                                    mediaType: "json"
                                )
                            )
                        ]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("```json"))
        #expect(markdown.contains("{\"key\": \"value\"}"))
        #expect(markdown.contains("```"))
    }

    // MARK: - Scenario Outline

    @Test("Scenario outline with examples table")
    func scenarioOutline() throws {
        let feature = Feature(
            title: "Outlines",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Email check",
                        steps: [
                            Step(keyword: .given, text: "the email <email>"),
                            Step(keyword: .then, text: "result is <valid>")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["email", "valid"],
                                    ["test@test.com", "true"],
                                    ["invalid", "false"]
                                ]))
                        ]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("## Scenario Outline: Email check"))
        #expect(markdown.contains("### Examples"))
        #expect(markdown.contains("| email | valid |"))
        #expect(markdown.contains("| test@test.com | true |"))
    }

    // MARK: - Background

    @Test("Background rendered as subsection")
    func backgroundSection() throws {
        let feature = Feature(
            title: "With Background",
            background: Background(steps: [
                Step(keyword: .given, text: "a logged-in user")
            ]),
            children: [
                .scenario(
                    Scenario(
                        title: "View dashboard",
                        steps: [Step(keyword: .then, text: "the dashboard is shown")]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("### Background"))
        #expect(markdown.contains("- **Given** a logged-in user"))
    }

    // MARK: - Rule

    @Test("Rule rendered as section")
    func ruleSection() throws {
        let feature = Feature(
            title: "With Rule",
            children: [
                .rule(
                    Rule(
                        title: "Discount rules",
                        description: "Rules for premium customers",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "10% off",
                                    steps: [
                                        Step(keyword: .given, text: "a premium customer"),
                                        Step(keyword: .then, text: "10% discount")
                                    ]
                                ))
                        ]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("## Rule: Discount rules"))
        #expect(markdown.contains("Rules for premium customers"))
        #expect(markdown.contains("## Scenario: 10% off"))
    }

    // MARK: - And/But Steps

    @Test("And and But steps rendered correctly")
    func andButSteps() throws {
        let feature = Feature(
            title: "Steps",
            children: [
                .scenario(
                    Scenario(
                        title: "Multiple steps",
                        steps: [
                            Step(keyword: .given, text: "a cart"),
                            Step(keyword: .and, text: "a product"),
                            Step(keyword: .when, text: "I checkout"),
                            Step(keyword: .but, text: "not with a coupon"),
                            Step(keyword: .then, text: "order is placed")
                        ]
                    ))
            ]
        )

        let markdown = try exporter.render(feature, format: .markdown)
        #expect(markdown.contains("- **And** a product"))
        #expect(markdown.contains("- **But** not with a coupon"))
    }
}
