# ``GherkinGenerator``

@Metadata {
    @DisplayName("Gherkin Generator")
}

A Swift library for composing, validating, importing, and exporting Gherkin `.feature` files programmatically.

## Overview

**Gherkin Generator** replaces manual Gherkin authoring with a type-safe, fluent Swift API. Build features programmatically, validate them against built-in rules, import from multiple formats, and export to `.feature`, JSON, or Markdown. Full multi-language support for 70+ languages from the official Gherkin specification.

```swift
import GherkinGenerator

let feature = try GherkinFeature(title: "User Authentication")
    .tags(["auth"])
    .background {
        $0.given("the login page is displayed")
    }
    .addScenario("Successful login")
    .given("a valid account")
    .when("the user logs in")
    .then("the dashboard is displayed")
    .build()
```

### Key Features

- **Fluent Builder** — chainable, immutable, `Sendable`-safe construction of features, scenarios, outlines, backgrounds, rules, data tables, and doc strings
- **Validation Engine** — 5 built-in rules (structure, coherence, tag format, table consistency, outline placeholders) plus custom rules via the ``ValidationRule`` protocol
- **Multi-format Export** — `.feature`, JSON (`Codable`), and Markdown via ``GherkinExporter``
- **Multi-format Import** — `.feature`, CSV, JSON, plain text, and Excel `.xlsx`
- **Batch Processing** — ``BatchExporter``, ``BatchImporter``, and ``BatchValidator`` actors for directory-level operations with parallel I/O
- **Streaming** — `AsyncStream`-based streaming export via ``StreamingExporter`` for large features
- **70+ Languages** — localized keywords from the official `gherkin-languages.json` with automatic language detection
- **Strict Concurrency** — all public types are `Sendable`, actors for shared state, `async/await` throughout
- **CLI Tool** — `gherkin-gen` command-line interface for composing, validating, and converting Gherkin files

### How It Works

1. **Build** features programmatically using the ``GherkinFeature`` fluent builder
2. **Validate** features against structural and coherence rules with ``GherkinValidator``
3. **Format** features into properly indented Gherkin output with ``GherkinFormatter``
4. **Export** to `.feature`, JSON, or Markdown via ``GherkinExporter`` or ``StreamingExporter``
5. **Import** from `.feature` files, CSV, JSON, plain text, or Excel with the built-in parsers

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:BuildingFeatures>

### Parsing & Importing

- <doc:ParsingAndImporting>

### Validation

- <doc:ValidationGuide>

### Formatting & Exporting

- <doc:FormattingAndExporting>

### Internationalization

- <doc:InternationalizationGuide>

### Streaming & Batch Processing

- <doc:StreamingAndBatch>

### Command-Line Interface

- <doc:CLIReference>

### Model Types

- ``Feature``
- ``Scenario``
- ``ScenarioOutline``
- ``Step``
- ``StepKeyword``
- ``Background``
- ``Rule``
- ``DataTable``
- ``DocString``
- ``Tag``
- ``Examples``
- ``Comment``
- ``FeatureChild``
- ``RuleChild``

### Builder

- ``GherkinFeature``
- ``BackgroundBuilder``

### Parsers

- ``GherkinParser``
- ``CSVParser``
- ``CSVImportConfiguration``
- ``JSONFeatureParser``
- ``PlainTextParser``
- ``PlainTextImportConfiguration``
- ``ExcelParser``
- ``ExcelImportConfiguration``
- ``BatchImporter``

### Validators

- ``GherkinValidator``
- ``ValidationRule``
- ``StructureRule``
- ``CoherenceRule``
- ``TagFormatRule``
- ``TableConsistencyRule``
- ``OutlinePlaceholderRule``
- ``BatchValidator``
- ``BatchValidationResult``

### Formatters

- ``GherkinFormatter``
- ``FormatterConfiguration``

### Exporters

- ``GherkinExporter``
- ``StreamingExporter``
- ``BatchExporter``
- ``ExportFormat``
- ``ExportProgress``
- ``BatchExportProgress``

### Language

- ``GherkinLanguage``
- ``LanguageKeywords``

### Errors

- ``GherkinError``
