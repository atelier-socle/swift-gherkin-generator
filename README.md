# swift-gherkin-generator

A Swift library for composing, validating, importing, and exporting Gherkin `.feature` files programmatically.

[![CI](https://github.com/atelier-socle/swift-gherkin-generator/actions/workflows/ci.yml/badge.svg)](https://github.com/atelier-socle/swift-gherkin-generator/actions/workflows/ci.yml)
[![codecov](https://codecov.io/github/atelier-socle/swift-gherkin-generator/graph/badge.svg?token=3V6JR0WJ5E)](https://codecov.io/github/atelier-socle/swift-gherkin-generator)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20visionOS%20|%20Linux-blue.svg)]()

![swift-gherkin-generator](./assets/banner.png)

## Overview

swift-gherkin-generator replaces manual Gherkin authoring with a type-safe, fluent Swift API. Build features programmatically, validate them against 5 built-in rules, import from CSV/JSON/plain text, and export to `.feature`, JSON, or Markdown. Full multi-language support for 70+ languages from the official Gherkin specification.

Part of the [Atelier Socle](https://www.atelier-socle.com) Gherkin ecosystem alongside [swift-gherkin-testing](https://github.com/atelier-socle/swift-gherkin-testing) (execute `.feature` files as Swift Testing tests).

## Features

- **Fluent Builder** — chainable, immutable, `Sendable`-safe construction of features, scenarios, outlines, backgrounds, rules, data tables, and doc strings
- **Validation Engine** — 5 built-in rules (structure, coherence, tag format, table consistency, outline placeholders) plus custom rules via the `ValidationRule` protocol
- **Multi-format Export** — `.feature`, JSON (`Codable`), and Markdown
- **Multi-format Import** — `.feature` (recursive descent parser), CSV, JSON, plain text, and Excel `.xlsx`
- **Batch Export** — parallel export of multiple features to a directory via `BatchExporter` actor, with progress tracking and automatic filename slugification
- **Excel Import** — native `.xlsx` parsing via built-in ZIP/OOXML reader, cross-platform (macOS, iOS, Linux) with no third-party dependencies
- **CLI Tool** — `gherkin-gen` command-line interface with 7 commands: generate, validate, parse, export, convert, batch-export, languages
- **70+ languages** — localized keywords from the official `gherkin-languages.json` with automatic language detection
- **Streaming & Batch** — `AsyncStream`-based streaming export and batch import/validation via actors
- **Strict concurrency** — all public types are `Sendable`, actors for shared state, `async/await` throughout

## Installation

### Requirements

- **Swift 6.2+** with strict concurrency
- **Platforms**: iOS 17+ · macOS 14+ · tvOS 17+ · watchOS 10+ · visionOS 1+ · Mac Catalyst 17+ · Linux

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/atelier-socle/swift-gherkin-generator.git", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["GherkinGenerator"]
)
```

## Quick Start

Build a feature with the fluent API and produce an immutable `Feature` value:

```swift
import GherkinGenerator

let feature = try GherkinFeature(title: "Login")
    .addScenario("Successful login")
    .given("a valid account")
    .when("the user logs in")
    .then("the dashboard is displayed")
    .build()
```

The `GherkinFeature` builder is immutable — every method returns a new copy. Call `.build()` to finalize the feature, `.validate()` to check for structural errors, or `.export(to:)` to write it directly to a `.feature` file.

## Key Concepts

### Scenarios with Continuations

Chain `And` and `But` steps after any primary step to add continuation clauses:

```swift
let feature = try GherkinFeature(title: "Cart")
    .addScenario("Add product")
    .given("an empty cart")
    .when("I add a product at 29€")
    .then("the cart contains 1 item")
    .and("the total is 29€")
    .but("no discount is applied")
    .build()
```

### Background

Define shared preconditions that run before every scenario in the feature. The closure receives a `BackgroundBuilder`:

```swift
let feature = try GherkinFeature(title: "Orders")
    .background {
        $0.given("a logged-in user")
            .and("at least one existing order")
    }
    .addScenario("View orders")
    .when("I view my orders")
    .then("the list is displayed")
    .build()
```

### Scenario Outline with Examples

Use `addOutline` for parameterized scenarios. Placeholders in angle brackets (`<email>`) are substituted from the examples table at generation time:

```swift
let feature = try GherkinFeature(title: "Email Validation")
    .addOutline("Email format")
    .given("the email <email>")
    .when("I validate the format")
    .then("the result is <valid>")
    .examples([
        ["email", "valid"],
        ["test@example.com", "true"],
        ["invalid", "false"]
    ])
    .build()
```

Named and tagged examples blocks are also supported via `.examples(_:name:tags:)`.

### Data Tables

Attach a data table to any step. The first row is the header row:

```swift
let feature = try GherkinFeature(title: "Pricing")
    .addScenario("Price by quantity")
    .given("the following prices")
    .table([
        ["Quantity", "Unit Price"],
        ["1-10", "10€"],
        ["11-50", "8€"]
    ])
    .when("I order 25 units")
    .then("the unit price is 8€")
    .build()
```

### Doc Strings

Attach multi-line text with an optional media type to a step:

```swift
let feature = try GherkinFeature(title: "API")
    .addScenario("POST request")
    .given("a request body")
    .docString("{\"key\": \"value\"}", mediaType: "application/json")
    .then("status 201")
    .build()
```

### Tags

Apply tags at feature level with `.tags()` and at scenario level with `.scenarioTags()`. Tags are used for filtering, categorization, and hook targeting:

```swift
let feature = try GherkinFeature(title: "Payment")
    .tags(["@payment", "@critical"])
    .addScenario("Credit card")
    .scenarioTags(["@card", "@slow"])
    .given("a validated cart")
    .then("payment is processed")
    .build()
```

### Mass Generation

Use `var` and reassignment for loop-based generation of many scenarios:

```swift
let endpoints = ["users", "products", "orders"]
var builder = GherkinFeature(title: "API Smoke Tests")

for endpoint in endpoints {
    builder =
        builder
        .addScenario("GET /\(endpoint) returns 200")
        .given("the API is running")
        .when("I request GET /api/\(endpoint)")
        .then("the response status is 200")
}

let feature = try builder.build()
```

For a mutating approach, use `appendScenario(_:)` or `appendOutline(_:)` instead.

### Validate and Export

Combine building, validation, and file export in a single call:

```swift
let builder = GherkinFeature(title: "Export Test")
    .addScenario("Scenario")
    .given("a precondition")
    .then("a result")

try await builder.export(to: "output.feature")
```

This calls `.build()`, runs the validator, and writes the formatted output to disk.

## Parsing

### Parse `.feature` Files

`GherkinParser` uses a recursive descent approach. It automatically detects the language from a `# language:` header or falls back to English:

```swift
let parser = GherkinParser()
let feature = try parser.parse(contentsOfFile: "login.feature")
```

### Parse Gherkin Strings

Parse Gherkin source directly from a string:

```swift
let parser = GherkinParser()
let feature = try parser.parse("""
    Feature: Login

      Scenario: Successful login
        Given a valid account
        When the user logs in
        Then the dashboard is displayed
    """)
```

### Language Detection

Detect the language of a Gherkin source without parsing it:

```swift
let parser = GherkinParser()
let language = parser.detectLanguage(in: "# language: fr\nFonctionnalité: ...")
// language == .french
```

## Importers

### CSV

Map CSV columns to Gherkin step types via `CSVImportConfiguration`. Each row becomes a scenario:

```swift
let csv = """
    Scenario,Given,When,Then
    Login,valid credentials,user logs in,dashboard shown
    """
let config = CSVImportConfiguration(
    scenarioColumn: "Scenario",
    givenColumn: "Given",
    whenColumn: "When",
    thenColumn: "Then"
)
let feature = try CSVParser(configuration: config).parse(csv, featureTitle: "Auth")
```

Custom delimiters and an optional tag column are supported.

### JSON

`JSONFeatureParser` decodes JSON produced by `GherkinExporter`, providing a round-trip guarantee — exporting to JSON and importing back produces an identical `Feature`:

```swift
let parser = JSONFeatureParser()
let feature = try parser.parse(jsonString)
```

Also supports `parse(data:)` for raw `Data` and `parse(contentsOfFile:)` for file paths.

### Plain Text

Parse informal plain text into scenarios. Lines starting with `Given`/`When`/`Then` become steps, `---` separates scenarios, and the first line is the feature title:

```swift
let text = """
    Shopping Cart
    Add a product
    Given an empty cart
    When I add a product
    Then the cart has 1 item
    ---
    Remove a product
    Given a cart with 1 item
    When I remove the product
    Then the cart is empty
    """
let feature = try PlainTextParser().parse(text)
```

All prefixes and the separator are configurable via `PlainTextImportConfiguration`.

### Excel

`ExcelParser` reads `.xlsx` files natively using a built-in ZIP/OOXML reader (no third-party dependencies). It works cross-platform on macOS, iOS, and Linux via the system `zlib` library. Configure column mapping with `ExcelImportConfiguration`:

```swift
let config = ExcelImportConfiguration(
    scenarioColumn: "Scenario",
    givenColumn: "Given",
    whenColumn: "When",
    thenColumn: "Then"
)
let data = try Data(contentsOf: URL(fileURLWithPath: "tests.xlsx"))
let feature = try ExcelParser(configuration: config).parse(data, featureTitle: "Auth")
```

An optional `tagColumn` parameter maps a column to scenario-level tags (space or comma separated). The `sheetIndex` parameter selects which worksheet to read (defaults to `0`):

```swift
let config = ExcelImportConfiguration(
    scenarioColumn: "Scenario",
    givenColumn: "Given",
    whenColumn: "When",
    thenColumn: "Then",
    tagColumn: "Tags",
    sheetIndex: 0
)
```

### Batch Import

`BatchImporter` is an actor that scans a directory for `.feature` files and parses them in parallel using `TaskGroup`:

```swift
let importer = BatchImporter()
let results = try await importer.importDirectory(at: "features/")
for result in results {
    switch result {
    case .success(let feature):
        print("Imported: \(feature.title)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

Use `streamDirectory(at:)` for progressive processing via `AsyncStream`.

## Validation

### Validate a Feature

`GherkinValidator` checks a feature for structural correctness, coherence, and convention compliance. It reports all issues found, not just the first:

```swift
let validator = GherkinValidator()
let errors = validator.collectErrors(in: feature)
if errors.isEmpty {
    print("Feature is valid!")
}
```

Use `validate(_:)` to throw on the first error instead.

### Built-in Rules

| Rule | Description |
|------|-------------|
| `StructureRule` | Every scenario must have at least one `Given` and one `Then` step |
| `CoherenceRule` | No consecutive duplicate steps |
| `TagFormatRule` | Tag names must be non-empty and contain no spaces |
| `TableConsistencyRule` | All rows must have the same column count, no empty cells |
| `OutlinePlaceholderRule` | Every `<placeholder>` must match an Examples column header |

### Custom Rules

Conform to the `ValidationRule` protocol to add project-specific checks. Rules are composable — pass any combination to the validator:

```swift
struct MaxScenariosRule: ValidationRule {
    let maxCount: Int

    func validate(_ feature: Feature) -> [GherkinError] {
        if feature.children.count > maxCount {
            // Return appropriate errors
        }
        return []
    }
}

let validator = GherkinValidator(rules: [
    StructureRule(),
    TagFormatRule(),
    MaxScenariosRule(maxCount: 50),
])
```

### Batch Validation

`BatchValidator` is an actor that parses and validates all `.feature` files in a directory in parallel:

```swift
let validator = BatchValidator()
let results = try await validator.validateDirectory(at: "features/")
for result in results {
    if result.isSuccess {
        print("✓ \(result.featureTitle ?? result.path)")
    } else {
        print("✗ \(result.path): \(result.errors)")
    }
}
```

Use `streamValidation(at:)` for progressive reporting via `AsyncStream`.

## Formatting

`GherkinFormatter` converts a `Feature` into a properly formatted Gherkin string with consistent indentation and pipe-aligned tables:

```swift
let formatter = GherkinFormatter(configuration: .default)
let output = formatter.format(feature)
```

Three presets are available:

| Preset | Description |
|--------|-------------|
| `.default` | 2-space indent, standard spacing |
| `.compact` | Minimal whitespace |
| `.tabs` | Tab-based indentation (1 tab per level) |

## Exporting

### Export to File

`GherkinExporter` writes a feature to disk in the chosen format:

```swift
let exporter = GherkinExporter()
try await exporter.export(feature, to: "output.feature")
try await exporter.export(feature, to: "output.json", format: .json)
try await exporter.export(feature, to: "output.md", format: .markdown)
```

### Render to String

Render in-memory without writing to disk:

```swift
let exporter = GherkinExporter()
let gherkin = try exporter.render(feature, format: .feature)
let json = try exporter.render(feature, format: .json)
let markdown = try exporter.render(feature, format: .markdown)
```

### Streaming Export

`StreamingExporter` is an actor that writes features line-by-line without loading the entire output in memory, suitable for features with hundreds of scenarios:

```swift
let exporter = StreamingExporter()
try await exporter.export(largeFeature, to: "large.feature")
```

Get an `AsyncStream<String>` of formatted lines for custom processing:

```swift
let exporter = StreamingExporter()
for await line in exporter.lines(for: feature) {
    print(line)
}
```

Track progress as each child (scenario, outline, rule) is written:

```swift
let exporter = StreamingExporter()
for await progress in await exporter.exportWithProgress(feature, to: path) {
    print("\(Int(progress.fractionCompleted * 100))%")
}
```

### Batch Export

`BatchExporter` is an actor that exports multiple features to individual files in a target directory. Files are written in parallel using `TaskGroup`. Feature titles are automatically slugified into filenames, and duplicate names receive numeric suffixes:

```swift
let exporter = BatchExporter()
let results = try await exporter.exportAll(features, to: tempDir)
```

Export to JSON or Markdown by passing a format:

```swift
let exporter = BatchExporter()
let results = try await exporter.exportAll(
    [sampleFeatures[0]],
    to: tempDir,
    format: .json
)
```

Track progress with `exportAllWithProgress`, which yields a `BatchExportProgress` value for each exported file:

```swift
let exporter = BatchExporter()
for await progress in await exporter.exportAllWithProgress(
    sampleFeatures,
    to: tempDir
) {
    print("\(progress.featureTitle) — \(Int(progress.fractionCompleted * 100))%")
}
```

Filename slugification converts titles to lowercase, replaces spaces and underscores with hyphens, removes special characters, and collapses consecutive hyphens. If a filename already exists, a numeric suffix is appended (`login.feature`, `login-1.feature`, `login-2.feature`).

## i18n

Write features in 70+ languages. The parser detects `# language:` directives and uses localized keywords. The formatter produces output with the correct localized keywords:

```swift
let feature = try GherkinFeature(title: "Authentification", language: .french)
    .addScenario("Connexion")
    .given("un compte valide")
    .when("je me connecte")
    .then("je suis connecté")
    .build()
```

15 common languages have static shortcuts: `.english`, `.french`, `.german`, `.spanish`, `.italian`, `.portuguese`, `.japanese`, `.chinese`, `.russian`, `.arabic`, `.korean`, `.dutch`, `.polish`, `.turkish`, `.swedish`.

Look up any language by ISO code or list all available languages:

```swift
let language = GherkinLanguage(code: "ja") // Japanese
let allLanguages = GherkinLanguage.all     // 70+ languages
```

Access localized keywords for a language:

```swift
let lang = GherkinLanguage.french
print(lang.keywords.feature) // ["Fonctionnalité"]
print(lang.keywords.given)   // ["Soit ", "Etant donné ", ...]
```

## Architecture

```
Sources/
    CZlib/                # System library wrapper for zlib (ZIP decompression)
    GherkinGenerator/     # Core library (no external dependencies)
        Model/            # Feature, Scenario, Step, Tag, DataTable, DocString, ...
        Builder/          # GherkinFeature fluent builder
        Parser/           # GherkinParser, CSVParser, JSONFeatureParser, PlainTextParser,
                          # ExcelParser, ZIPReader, BatchImporter
        Validator/        # GherkinValidator, ValidationRule, built-in rules, BatchValidator
        Formatter/        # GherkinFormatter, FormatterConfiguration
        Exporter/         # GherkinExporter, StreamingExporter, BatchExporter, ExportFormat
        Language/         # GherkinLanguage, LanguageKeywords, GherkinLanguageRegistry
    GherkinGenCLICore/    # CLI command implementations (depends on ArgumentParser)
    GherkinGenCLI/        # Executable entry point (@main)
```

## CLI

`gherkin-gen` is a command-line tool for composing, validating, and converting Gherkin `.feature` files. It provides 7 subcommands:

### Install the CLI

Build from source and install to `/usr/local/bin`:

```bash
make install
```

Or use the standalone install script:

```bash
./Scripts/install.sh
```

Or build manually:

```bash
swift build -c release
cp .build/release/gherkin-gen /usr/local/bin/
```

Homebrew support via the `atelier-socle/tools` tap is planned for a future release.

### generate

Generate a `.feature` file from command-line arguments:

```bash
gherkin-gen generate \
    --title "User Login" \
    --scenario "Successful login" \
    --given "a valid account" \
    --when "the user logs in" \
    --then "the dashboard is displayed" \
    --tag smoke \
    --output login.feature
```

Options `--given`, `--when`, `--then`, and `--tag` are repeatable. Use `--language` for non-English features (default: `en`). Omit `--output` to print to stdout.

### validate

Validate one or more `.feature` files for correctness:

```bash
gherkin-gen validate login.feature
gherkin-gen validate features/
```

Pass a directory to validate all `.feature` files recursively. Use `--strict` to enable all default rules and `--quiet` to suppress success messages.

### parse

Parse a `.feature` file and display its structure:

```bash
gherkin-gen parse login.feature
gherkin-gen parse login.feature --format json
```

The `--format` option accepts `summary` (default) or `json`.

### export

Export a `.feature` file to another format:

```bash
gherkin-gen export login.feature --format json --output login.json
gherkin-gen export login.feature --format markdown --output login.md
```

The `--format` option accepts `feature`, `json`, or `markdown`. Omit `--output` to print to stdout.

### batch-export

Batch-export all `.feature` files from a directory:

```bash
gherkin-gen batch-export features/ --output dist/ --format json
```

Exports each `.feature` file as a separate output file. The `--format` option accepts `feature` (default), `json`, or `markdown`.

### convert

Convert CSV, JSON, TXT, or Excel `.xlsx` files to `.feature` format:

```bash
gherkin-gen convert data.csv --title "My Feature" --output output.feature
gherkin-gen convert steps.txt --title "My Feature" --output output.feature
gherkin-gen convert tests.xlsx --title "My Feature" --output output.feature --sheet 0
```

For CSV files, column names default to `Scenario`, `Given`, `When`, `Then` and can be customized with `--scenario-column`, `--given-column`, `--when-column`, `--then-column`. Use `--delimiter` to change the CSV delimiter and `--tag-column` to map a column to scenario-level tags.

### languages

List all 70+ supported Gherkin languages or show keywords for a specific language:

```bash
gherkin-gen languages
gherkin-gen languages --code fr
```

## Documentation

Full documentation will be available in the DocC catalog (coming soon).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute.

## License

MIT License. See [LICENSE](LICENSE) for details.

Copyright (c) 2026 Atelier Socle SAS
