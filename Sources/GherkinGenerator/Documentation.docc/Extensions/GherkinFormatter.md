# ``GherkinGenerator/GherkinFormatter``

A formatter that produces properly indented Gherkin text from a ``Feature`` value.

## Overview

`GherkinFormatter` takes a ``Feature`` and produces a correctly indented `.feature` file string. It handles keyword localization, pipe-aligned data tables, doc strings, and configurable indentation.

```swift
let formatter = GherkinFormatter()
let output = formatter.format(feature)
```

Use ``FormatterConfiguration`` presets — `.default`, `.compact`, or `.tabs` — or create a custom configuration for full control over indentation style and spacing.

## Topics

### Creating a Formatter

- ``init(configuration:)``

### Formatting

- ``format(_:)``

### Configuration

- ``configuration``
