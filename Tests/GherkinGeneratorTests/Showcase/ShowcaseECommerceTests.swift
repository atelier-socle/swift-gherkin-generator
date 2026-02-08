import Foundation
import Testing

@testable import GherkinGenerator

/// End-to-end showcase: e-commerce product catalog and shopping cart.
///
/// Demonstrates Scenario Outlines with Examples, Rules, multi-format import
/// (CSV, Excel, plain text), batch export, and batch import round-trip.
@Suite("Showcase — E-Commerce")
struct ShowcaseECommerceTests {

    // MARK: - Builder with Outlines and Rules

    /// Builds an e-commerce feature with Scenario Outlines, Examples,
    /// Rules, and a Background — demonstrating advanced Gherkin constructs.
    @Test("Build e-commerce feature with outlines, rules, and background")
    func buildECommerceFeature() throws {
        let catalogRule = Rule(
            title: "Catalog browsing",
            children: [
                .scenario(
                    Scenario(
                        title: "View product details",
                        steps: [
                            Step(keyword: .given, text: "a product \"Laptop\" exists"),
                            Step(keyword: .when, text: "the user views the product"),
                            Step(keyword: .then, text: "the product details are displayed")
                        ]
                    ))
            ]
        )
        let cartRule = Rule(
            title: "Shopping cart",
            children: [
                .scenario(
                    Scenario(
                        title: "Add product to cart",
                        steps: [
                            Step(keyword: .given, text: "an empty cart"),
                            Step(keyword: .when, text: "the user adds \"Laptop\" to the cart"),
                            Step(keyword: .then, text: "the cart contains 1 item")
                        ]
                    ))
            ]
        )

        let feature = try GherkinFeature(title: "E-Commerce Platform")
            .tags(["ecommerce"])
            .background { $0.given("the product catalog is loaded") }
            .addOutline("Product search with filters")
            .given("the user is on the search page")
            .when("the user searches for <query> in category <category>")
            .then("the results contain <count> products")
            .examples([
                ["query", "category", "count"],
                ["laptop", "Electronics", "15"],
                ["shirt", "Clothing", "42"],
                ["", "All", "100"]
            ])
            .addRule(catalogRule)
            .addRule(cartRule)
            .build()

        #expect(feature.title == "E-Commerce Platform")
        #expect(feature.background != nil)
        #expect(feature.outlines.count == 1)
        #expect(feature.rules.count == 2)
        #expect(feature.outlines[0].examples[0].table.rowCount == 4)
    }

    // MARK: - CSV Import

    /// Imports scenarios from a CSV string — demonstrates CSVParser with
    /// column mapping and optional tag column.
    @Test("Import scenarios from CSV")
    func importFromCSV() throws {
        let csv = """
            Scenario,Given,When,Then,Tags
            Search products,the catalog is loaded,the user searches for laptop,15 results are shown,@search
            Add to cart,an empty cart,the user adds an item,the cart has 1 item,@cart @smoke
            Checkout,a cart with items,the user checks out,the order is confirmed,@checkout
            """
        let config = CSVImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then",
            tagColumn: "Tags"
        )
        let feature = try CSVParser(configuration: config)
            .parse(csv, featureTitle: "E-Commerce CSV Import")

        #expect(feature.title == "E-Commerce CSV Import")
        #expect(feature.children.count == 3)
        #expect(feature.scenarios[0].tags.map(\.name).contains("search"))
        #expect(feature.scenarios[1].tags.count == 2)

        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(errors.isEmpty)
    }

    // MARK: - Excel Import

    /// Imports scenarios from a programmatically-built .xlsx file —
    /// demonstrates ExcelParser with shared string table.
    @Test("Import scenarios from Excel xlsx")
    func importFromExcel() throws {
        let xlsx = TestXLSXBuilder.build(rows: [
            ["Scenario", "Given", "When", "Then"],
            ["Browse catalog", "the catalog is loaded", "the user browses products", "products are listed"],
            ["Filter by price", "the catalog is loaded", "the user sets max price to 50", "only affordable items show"]
        ])
        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let feature = try ExcelParser(configuration: config)
            .parse(xlsx, featureTitle: "E-Commerce Excel Import")

        #expect(feature.title == "E-Commerce Excel Import")
        #expect(feature.children.count == 2)
        #expect(feature.scenarios[0].title == "Browse catalog")

        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(errors.isEmpty)
    }

    // MARK: - Plain Text Import

    /// Imports scenarios from plain text — demonstrates PlainTextParser
    /// with scenario separators.
    @Test("Import scenarios from plain text")
    func importFromPlainText() throws {
        let text = """
            Given the product catalog is loaded
            When the user searches for "laptop"
            Then 15 results are displayed
            ---
            Given an empty cart
            When the user adds a product
            Then the cart contains 1 item
            """
        let feature = try PlainTextParser()
            .parse(text, featureTitle: "E-Commerce Text Import")

        #expect(feature.title == "E-Commerce Text Import")
        #expect(feature.children.count == 2)

        let errors = GherkinValidator().collectErrors(in: feature)
        #expect(errors.isEmpty)
    }

    // MARK: - Batch Export → Batch Import Round-trip

    /// Exports multiple features to a directory with BatchExporter, then
    /// re-imports them with BatchImporter — verifies round-trip integrity.
    @Test("Batch export and re-import round-trip")
    func batchRoundTrip() async throws {
        let tempDir = makeTempDir()
        defer { cleanup(tempDir) }

        let features = [
            try GherkinFeature(title: "Catalog")
                .addScenario("List products")
                .given("products exist").when("I browse").then("products shown")
                .build(),
            try GherkinFeature(title: "Cart")
                .addScenario("Add item")
                .given("an empty cart").when("I add a product").then("cart has 1 item")
                .build(),
            try GherkinFeature(title: "Checkout")
                .addScenario("Complete order")
                .given("a full cart").when("I checkout").then("order confirmed")
                .build()
        ]

        // Batch export
        let exporter = BatchExporter()
        let results = try await exporter.exportAll(features, to: tempDir)
        let successes = results.compactMap { try? $0.get() }
        #expect(successes.count == 3)

        // Batch import
        let importer = BatchImporter()
        let imported = try await importer.importDirectory(at: tempDir)
        let importedFeatures = imported.compactMap { try? $0.get() }
        #expect(importedFeatures.count == 3)

        let titles = Set(importedFeatures.map(\.title))
        #expect(titles.contains("Catalog"))
        #expect(titles.contains("Cart"))
        #expect(titles.contains("Checkout"))
    }

    // MARK: - Helpers

    private func makeTempDir() -> String {
        let path = NSTemporaryDirectory() + "showcase-ecom-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(
            atPath: path, withIntermediateDirectories: true)
        return path
    }

    private func cleanup(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}
