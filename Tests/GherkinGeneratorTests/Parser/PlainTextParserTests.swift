import Testing

@testable import GherkinGenerator

@Suite("PlainTextParser")
struct PlainTextParserTests {

    private let parser = PlainTextParser()

    // MARK: - Basic Parsing

    @Test("Parse plain text with Given/When/Then prefixes")
    func basicParsing() throws {
        let text = """
            Shopping Cart
            Add a product
            Given an empty cart
            When I add a product
            Then the cart has 1 item
            """
        let feature = try parser.parse(text)

        #expect(feature.title == "Shopping Cart")
        #expect(feature.children.count == 1)

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Add a product")
        #expect(scenario.steps.count == 3)
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[0].text == "an empty cart")
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[1].text == "I add a product")
        #expect(scenario.steps[2].keyword == .then)
        #expect(scenario.steps[2].text == "the cart has 1 item")
    }

    // MARK: - Scenario Separation

    @Test("Scenarios separated by separator line")
    func separatorScenarios() throws {
        let text = """
            My Feature
            First scenario
            Given step one
            Then result one
            ---
            Second scenario
            Given step two
            Then result two
            """
        let feature = try parser.parse(text)

        #expect(feature.title == "My Feature")
        #expect(feature.children.count == 2)

        guard case .scenario(let first) = feature.children[0],
            case .scenario(let second) = feature.children[1]
        else {
            Issue.record("Expected two scenarios")
            return
        }
        #expect(first.title == "First scenario")
        #expect(second.title == "Second scenario")
    }

    @Test("Scenarios separated by blank lines")
    func blankLineSeparation() throws {
        let text = """
            My Feature
            First scenario
            Given step one
            Then result one

            Second scenario
            Given step two
            Then result two
            """
        let feature = try parser.parse(text)

        #expect(feature.children.count == 2)
    }

    // MARK: - Custom Configuration

    @Test("Custom prefix configuration")
    func customPrefixes() throws {
        let config = PlainTextImportConfiguration(
            givenPrefix: "Soit ",
            whenPrefix: "Quand ",
            thenPrefix: "Alors ",
            andPrefix: "Et ",
            butPrefix: "Mais "
        )
        let parser = PlainTextParser(configuration: config)
        let text = """
            Ma Fonctionnalité
            Un scénario
            Soit un utilisateur
            Quand il se connecte
            Alors il voit le tableau de bord
            """
        let feature = try parser.parse(text)

        #expect(feature.title == "Ma Fonctionnalité")
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps[0].keyword == .given)
        #expect(scenario.steps[1].keyword == .when)
        #expect(scenario.steps[2].keyword == .then)
    }

    @Test("Custom scenario separator")
    func customSeparator() throws {
        let config = PlainTextImportConfiguration(scenarioSeparator: "===")
        let parser = PlainTextParser(configuration: config)
        let text = """
            Feature
            Scenario A
            Given something
            ===
            Scenario B
            Given something else
            """
        let feature = try parser.parse(text)
        #expect(feature.children.count == 2)
    }

    // MARK: - Feature Title Override

    @Test("Feature title override with featureTitle parameter")
    func featureTitleOverride() throws {
        let text = """
            First scenario
            Given something
            Then result
            """
        let feature = try parser.parse(text, featureTitle: "My Custom Title")

        #expect(feature.title == "My Custom Title")
    }

    // MARK: - And/But Steps

    @Test("And and But steps parsed correctly")
    func andButSteps() throws {
        let text = """
            Feature
            Scenario
            Given a cart
            And a product
            When I checkout
            But not with a coupon
            Then order placed
            """
        let feature = try parser.parse(text)

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.steps.count == 5)
        #expect(scenario.steps[1].keyword == .and)
        #expect(scenario.steps[1].text == "a product")
        #expect(scenario.steps[3].keyword == .but)
        #expect(scenario.steps[3].text == "not with a coupon")
    }

    // MARK: - Edge Cases

    @Test("Empty text throws error")
    func emptyText() {
        #expect(throws: GherkinError.self) {
            try parser.parse("")
        }
    }

    @Test("Whitespace-only text throws error")
    func whitespaceOnly() {
        #expect(throws: GherkinError.self) {
            try parser.parse("   \n   \n   ")
        }
    }

    @Test("Text starting with steps gets default title")
    func stepsWithoutTitle() throws {
        let text = """
            Given an empty cart
            When I add a product
            Then the cart has 1 item
            """
        let feature = try parser.parse(text)

        #expect(feature.title == "Untitled Feature")
        #expect(feature.children.count == 1)
    }

    @Test("Leading blank lines are skipped")
    func leadingBlanks() throws {
        let text = """

            My Feature
            A scenario
            Given something
            Then result
            """
        let feature = try parser.parse(text)
        #expect(feature.title == "My Feature")
    }
}
