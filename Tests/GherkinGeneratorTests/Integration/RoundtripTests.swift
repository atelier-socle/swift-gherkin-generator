import Foundation
import Testing

@testable import GherkinGenerator

@Suite("Round-trip Tests")
struct RoundtripTests {

    // MARK: - Test Fixtures

    private static let complexFeature = Feature(
        title: "Shopping Cart",
        tags: [Tag("smoke"), Tag("e2e")],
        description: "End-to-end shopping cart tests",
        background: Background(
            name: "Setup",
            steps: [
                Step(keyword: .given, text: "a logged-in user"),
                Step(keyword: .and, text: "an empty cart")
            ]
        ),
        children: [
            .scenario(
                Scenario(
                    title: "Add a product",
                    tags: [Tag("happy-path")],
                    description: "Adding a single product to the cart",
                    steps: [
                        Step(keyword: .given, text: "a product catalog"),
                        Step(keyword: .when, text: "I add product A"),
                        Step(keyword: .then, text: "the cart contains 1 item"),
                        Step(keyword: .and, text: "the total is 29€")
                    ]
                )),
            .outline(
                ScenarioOutline(
                    title: "Add multiple products",
                    steps: [
                        Step(keyword: .given, text: "the product <name>"),
                        Step(keyword: .when, text: "I add <count> units"),
                        Step(keyword: .then, text: "the total is <total>")
                    ],
                    examples: [
                        Examples(
                            name: "Normal products",
                            table: DataTable(rows: [
                                ["name", "count", "total"],
                                ["Widget", "2", "58€"],
                                ["Gadget", "1", "99€"]
                            ])
                        )
                    ]
                )),
            .rule(
                Rule(
                    title: "Discounts",
                    tags: [Tag("business")],
                    description: "Discount calculation rules",
                    background: Background(steps: [
                        Step(keyword: .given, text: "a premium customer")
                    ]),
                    children: [
                        .scenario(
                            Scenario(
                                title: "10% off large orders",
                                steps: [
                                    Step(keyword: .when, text: "the order exceeds 100€"),
                                    Step(keyword: .then, text: "10% discount is applied")
                                ]
                            ))
                    ]
                ))
        ],
        comments: [Comment(text: "Main shopping cart feature")]
    )

    // MARK: - JSON Round-trip

    @Test("JSON round-trip: encode then decode produces identical Feature")
    func jsonRoundtrip() throws {
        let exporter = GherkinExporter()
        let jsonParser = JSONFeatureParser()

        let json = try exporter.render(Self.complexFeature, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(Self.complexFeature == decoded)
    }

    @Test("JSON round-trip with data table step")
    func jsonRoundtripDataTable() throws {
        let original = Feature(
            title: "Users",
            children: [
                .scenario(
                    Scenario(
                        title: "Create users",
                        steps: [
                            Step(
                                keyword: .given, text: "the following users",
                                dataTable: DataTable(rows: [
                                    ["name", "email", "role"],
                                    ["Alice", "alice@test.com", "admin"],
                                    ["Bob", "bob@test.com", "user"]
                                ])
                            ),
                            Step(keyword: .then, text: "2 users exist")
                        ]
                    ))
            ]
        )

        let exporter = GherkinExporter()
        let jsonParser = JSONFeatureParser()

        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON round-trip with doc string step")
    func jsonRoundtripDocString() throws {
        let original = Feature(
            title: "API",
            children: [
                .scenario(
                    Scenario(
                        title: "POST request",
                        steps: [
                            Step(
                                keyword: .given, text: "the request body",
                                docString: DocString(
                                    content: "{\n  \"name\": \"test\"\n}",
                                    mediaType: "application/json"
                                )
                            ),
                            Step(keyword: .when, text: "I send the request"),
                            Step(keyword: .then, text: "the response is 201")
                        ]
                    ))
            ]
        )

        let exporter = GherkinExporter()
        let jsonParser = JSONFeatureParser()

        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON round-trip with non-English language")
    func jsonRoundtripFrench() throws {
        let original = Feature(
            title: "Authentification",
            language: .french,
            children: [
                .scenario(
                    Scenario(
                        title: "Connexion",
                        steps: [
                            Step(keyword: .given, text: "un compte valide"),
                            Step(keyword: .when, text: "je me connecte"),
                            Step(keyword: .then, text: "je suis connecté")
                        ]
                    ))
            ]
        )

        let exporter = GherkinExporter()
        let jsonParser = JSONFeatureParser()

        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    // MARK: - Feature File Round-trip

    @Test(".feature round-trip: format then parse produces same output")
    func featureFileRoundtrip() throws {
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
                    )),
                .scenario(
                    Scenario(
                        title: "Failed login",
                        tags: [Tag("negative")],
                        steps: [
                            Step(keyword: .given, text: "invalid credentials"),
                            Step(keyword: .when, text: "the user logs in"),
                            Step(keyword: .then, text: "an error is shown")
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let parser = GherkinParser()

        // Format → Parse → Format → Compare
        let firstOutput = formatter.format(feature)
        let parsed = try parser.parse(firstOutput)
        let secondOutput = formatter.format(parsed)

        #expect(firstOutput == secondOutput)
    }

    @Test(".feature round-trip with background")
    func featureRoundtripWithBackground() throws {
        let feature = Feature(
            title: "Orders",
            background: Background(steps: [
                Step(keyword: .given, text: "a logged-in user"),
                Step(keyword: .and, text: "at least one order")
            ]),
            children: [
                .scenario(
                    Scenario(
                        title: "View orders",
                        steps: [
                            Step(keyword: .when, text: "I view my orders"),
                            Step(keyword: .then, text: "the list is displayed")
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let parser = GherkinParser()

        let firstOutput = formatter.format(feature)
        let parsed = try parser.parse(firstOutput)
        let secondOutput = formatter.format(parsed)

        #expect(firstOutput == secondOutput)
    }

    @Test(".feature round-trip with scenario outline")
    func featureRoundtripWithOutline() throws {
        let feature = Feature(
            title: "Email Validation",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Email format",
                        steps: [
                            Step(keyword: .given, text: "the email <email>"),
                            Step(keyword: .when, text: "I validate the format"),
                            Step(keyword: .then, text: "the result is <valid>")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["email", "valid"],
                                    ["test@example.com", "true"],
                                    ["invalid-email", "false"]
                                ]))
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let parser = GherkinParser()

        let firstOutput = formatter.format(feature)
        let parsed = try parser.parse(firstOutput)
        let secondOutput = formatter.format(parsed)

        #expect(firstOutput == secondOutput)
    }

    @Test(".feature round-trip with French language")
    func featureRoundtripFrench() throws {
        let feature = Feature(
            title: "Authentification",
            language: .french,
            children: [
                .scenario(
                    Scenario(
                        title: "Connexion réussie",
                        steps: [
                            Step(keyword: .given, text: "un compte valide"),
                            Step(keyword: .when, text: "je me connecte"),
                            Step(keyword: .then, text: "je suis connecté")
                        ]
                    ))
            ]
        )

        let formatter = GherkinFormatter()
        let parser = GherkinParser()

        let firstOutput = formatter.format(feature)
        let parsed = try parser.parse(firstOutput)
        let secondOutput = formatter.format(parsed)

        #expect(firstOutput == secondOutput)
    }
}
