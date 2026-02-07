import Testing

@testable import GherkinGenerator

@Suite("CSVParser")
struct CSVParserTests {

    // MARK: - Basic Parsing

    @Test("Parse basic CSV with default delimiter")
    func basicCSV() throws {
        let csv = """
            Scenario,Given,When,Then
            Login,valid credentials,user logs in,dashboard shown
            Logout,a logged-in user,user logs out,login page shown
            """
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)
        let feature = try parser.parse(csv, featureTitle: "Auth")

        #expect(feature.title == "Auth")
        #expect(feature.children.count == 2)

        guard case .scenario(let first) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(first.title == "Login")
        #expect(first.steps.count == 3)
        #expect(first.steps[0].keyword == .given)
        #expect(first.steps[0].text == "valid credentials")
        #expect(first.steps[1].keyword == .when)
        #expect(first.steps[1].text == "user logs in")
        #expect(first.steps[2].keyword == .then)
        #expect(first.steps[2].text == "dashboard shown")
    }

    // MARK: - Custom Delimiter

    @Test("Parse CSV with semicolon delimiter")
    func semicolonDelimiter() throws {
        let csv = """
            Scenario;Given;When;Then
            Login;valid credentials;user logs in;dashboard shown
            """
        let config = CSVImportConfiguration(
            delimiter: ";",
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)
        let feature = try parser.parse(csv, featureTitle: "Auth")

        #expect(feature.children.count == 1)
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Login")
        #expect(scenario.steps.count == 3)
    }

    // MARK: - Tags Column

    @Test("Parse CSV with tags column")
    func tagsColumn() throws {
        let csv = """
            Scenario,Given,When,Then,Tags
            Login,valid creds,user logs in,dashboard,@smoke @critical
            Logout,logged-in user,user logs out,login page,@regression
            """
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then",
            tagColumn: "Tags"
        )
        let parser = CSVParser(configuration: config)
        let feature = try parser.parse(csv, featureTitle: "Auth")

        guard case .scenario(let first) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(first.tags.count == 2)
        #expect(first.tags[0].name == "smoke")
        #expect(first.tags[1].name == "critical")
    }

    // MARK: - Error Handling

    @Test("Missing required column throws error")
    func missingColumn() throws {
        let csv = """
            Scenario,Given,Then
            Login,valid credentials,dashboard shown
            """
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse(csv, featureTitle: "Auth")
        }
    }

    @Test("Empty CSV throws error")
    func emptyCSV() throws {
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse("", featureTitle: "Empty")
        }
    }

    // MARK: - Empty Rows

    @Test("Empty rows are skipped")
    func emptyRowsSkipped() throws {
        let csv = """
            Scenario,Given,When,Then
            Login,valid credentials,user logs in,dashboard shown

            Logout,a logged-in user,user logs out,login page shown
            """
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)
        let feature = try parser.parse(csv, featureTitle: "Auth")

        #expect(feature.children.count == 2)
    }

    // MARK: - Quoted Fields

    @Test("Parse CSV with quoted fields containing delimiters")
    func quotedFields() throws {
        let csv = """
            Scenario,Given,When,Then
            "Add product",an empty cart,"I add a product at 29,99€",cart has 1 item
            """
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = CSVParser(configuration: config)
        let feature = try parser.parse(csv, featureTitle: "Shopping")

        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Add product")
        #expect(scenario.steps[1].text == "I add a product at 29,99€")
    }
}
