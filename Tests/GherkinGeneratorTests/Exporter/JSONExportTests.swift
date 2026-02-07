import Foundation
import Testing

@testable import GherkinGenerator

@Suite("GherkinExporter - JSON")
struct JSONExportTests {

    private let exporter = GherkinExporter()

    // MARK: - Basic JSON Export

    @Test("Export simple feature to JSON")
    func simpleFeatureJSON() throws {
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

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("\"title\" : \"Login\""))
        #expect(json.contains("\"Successful login\""))
        #expect(json.contains("\"given\""))
        #expect(json.contains("\"a valid account\""))
    }

    @Test("JSON output is pretty-printed with sorted keys")
    func prettyPrintedSortedKeys() throws {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "A",
                        steps: [Step(keyword: .given, text: "something")]
                    ))
            ]
        )

        let json = try exporter.render(feature, format: .json)
        // Pretty-printed → contains newlines and indentation
        #expect(json.contains("\n"))
        // Sorted keys → "children" comes before "title"
        let childrenIndex = json.range(of: "\"children\"")
        let titleIndex = json.range(of: "\"title\"")
        #expect(childrenIndex != nil)
        #expect(titleIndex != nil)
        if let childrenIdx = childrenIndex, let titleIdx = titleIndex {
            #expect(childrenIdx.lowerBound < titleIdx.lowerBound)
        }
    }

    // MARK: - All Model Types in JSON

    @Test("Export feature with tags to JSON")
    func featureWithTags() throws {
        let feature = Feature(
            title: "Tagged",
            tags: [Tag("smoke"), Tag("critical")]
        )

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("smoke"))
        #expect(json.contains("critical"))
    }

    @Test("Export feature with data table to JSON")
    func featureWithDataTable() throws {
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

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("Alice"))
        #expect(json.contains("admin"))
        #expect(json.contains("Bob"))
    }

    @Test("Export feature with doc string to JSON")
    func featureWithDocString() throws {
        let feature = Feature(
            title: "DocStrings",
            children: [
                .scenario(
                    Scenario(
                        title: "JSON payload",
                        steps: [
                            Step(
                                keyword: .given, text: "a request with body",
                                docString: DocString(
                                    content: "{\"key\": \"value\"}",
                                    mediaType: "application/json"
                                )
                            )
                        ]
                    ))
            ]
        )

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("application/json"))
        #expect(json.contains("key"))
        #expect(json.contains("value"))
    }

    @Test("Export feature with scenario outline to JSON")
    func featureWithOutline() throws {
        let feature = Feature(
            title: "Outlines",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Email validation",
                        steps: [
                            Step(keyword: .given, text: "the email <email>"),
                            Step(keyword: .then, text: "the result is <valid>")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["email", "valid"],
                                    ["test@example.com", "true"],
                                    ["invalid", "false"]
                                ]))
                        ]
                    ))
            ]
        )

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("Email validation"))
        #expect(json.contains("email"))
        #expect(json.contains("test@example.com"))
    }

    @Test("Export feature with rule to JSON")
    func featureWithRule() throws {
        let feature = Feature(
            title: "Rules",
            children: [
                .rule(
                    Rule(
                        title: "Discount rules",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "10% off",
                                    steps: [
                                        Step(keyword: .given, text: "a premium customer"),
                                        Step(keyword: .then, text: "10% discount applies")
                                    ]
                                ))
                        ]
                    ))
            ]
        )

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("Discount rules"))
        #expect(json.contains("10% off"))
        #expect(json.contains("a premium customer"))
    }

    @Test("Export feature with comments to JSON")
    func featureWithComments() throws {
        let feature = Feature(
            title: "Commented",
            comments: [Comment(text: "This is a comment")]
        )

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("This is a comment"))
    }

    @Test("Export feature with description to JSON")
    func featureWithDescription() throws {
        let feature = Feature(
            title: "Described",
            description: "This feature handles authentication"
        )

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("This feature handles authentication"))
    }

    @Test("Export non-English feature to JSON")
    func frenchFeatureJSON() throws {
        let feature = Feature(
            title: "Authentification",
            language: .french,
            children: [
                .scenario(
                    Scenario(
                        title: "Connexion",
                        steps: [
                            Step(keyword: .given, text: "un compte valide")
                        ]
                    ))
            ]
        )

        let json = try exporter.render(feature, format: .json)
        #expect(json.contains("\"fr\""))
        #expect(json.contains("Authentification"))
    }
}
