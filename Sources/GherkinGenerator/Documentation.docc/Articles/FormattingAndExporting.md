# Formatting and Exporting

Format features into properly indented Gherkin output and export to multiple formats.

## Overview

``GherkinFormatter`` produces correctly indented, pipe-aligned Gherkin text from a ``Feature`` value. ``GherkinExporter`` writes that text — or JSON or Markdown — to disk or returns it as a `String`.

## Format a Feature

```swift
let formatter = GherkinFormatter()
let output = formatter.format(feature)
```

The default configuration uses 2-space indentation and blank lines between sections.

## Configuration Presets

``FormatterConfiguration`` ships with three presets:

| Preset | Indent | Compact |
|--------|--------|---------|
| `.default` | 2 spaces | No |
| `.compact` | 2 spaces | Yes |
| `.tabs` | 1 tab | No |

Use `.compact` to remove blank lines between scenarios:

```swift
let formatter = GherkinFormatter(configuration: .compact)
let compactOutput = formatter.format(feature)
```

Use `.tabs` for tab-based indentation:

```swift
let formatter = GherkinFormatter(configuration: .tabs)
let tabbedOutput = formatter.format(feature)
```

Create a custom configuration for full control:

```swift
let config = FormatterConfiguration(
    indentCharacter: " ",
    indentWidth: 4,
    compact: false
)
let formatter = GherkinFormatter(configuration: config)
```

## Export Formats

``GherkinExporter`` supports three output formats via ``ExportFormat``:

| Format | Extension | Description |
|--------|-----------|-------------|
| `.feature` | `.feature` | Standard Gherkin syntax |
| `.json` | `.json` | JSON structured representation (`Codable`) |
| `.markdown` | `.md` | Markdown documentation |

## Render to String

Use ``GherkinExporter/render(_:format:)`` to get a formatted string without writing to disk:

```swift
let exporter = GherkinExporter()
let gherkin = try exporter.render(feature, format: .feature)
let json = try exporter.render(feature, format: .json)
let markdown = try exporter.render(feature, format: .markdown)
```

## Export to File

Use ``GherkinExporter/export(_:to:format:)`` to write directly to disk:

```swift
let exporter = GherkinExporter()
try await exporter.export(feature, to: "output.feature")
try await exporter.export(feature, to: "output.json", format: .json)
try await exporter.export(feature, to: "output.md", format: .markdown)
```

## Custom Formatter for Export

Pass a configured ``GherkinFormatter`` to the exporter to control `.feature` output style:

```swift
let formatter = GherkinFormatter(configuration: .compact)
let exporter = GherkinExporter(formatter: formatter)
let output = try exporter.render(feature, format: .feature)
```

## JSON Round-Trip

JSON export uses `Codable`, producing output that ``JSONFeatureParser`` can import back. This provides a round-trip guarantee — exporting to JSON and importing back produces an identical ``Feature``:

```swift
let exporter = GherkinExporter()
let json = try exporter.render(feature, format: .json)

let parser = JSONFeatureParser()
let restored = try parser.parse(json)
```

## Builder Shortcut

``GherkinFeature`` includes a convenience method that builds, validates, and exports in one call:

```swift
let builder = GherkinFeature(title: "Export Test")
    .addScenario("Scenario")
    .given("a precondition")
    .then("a result")

try await builder.export(to: "output.feature")
```
