# ``GherkinGenerator/GherkinFeature``

An immutable, chainable builder for composing Gherkin features programmatically.

## Overview

`GherkinFeature` is the primary entry point for building `.feature` files in code. Every method returns a new copy of the builder, making it `Sendable`-safe and suitable for concurrent use.

```swift
let feature = try GherkinFeature(title: "Shopping Cart")
    .addScenario("Add a product")
    .given("an empty cart")
    .when("I add a product at 29€")
    .then("the cart contains 1 item")
    .build()
```

Call ``build()`` to finalize the builder into an immutable ``Feature`` value. Use ``validate()`` to check for structural errors, or ``export(to:)`` to build, validate, and write to disk in one step.

## Topics

### Creating a Builder

- ``init(title:language:)``

### Feature Configuration

- ``tags(_:)``
- ``description(_:)``
- ``comment(_:)``

### Background

- ``background(_:)-((BackgroundBuilder)->BackgroundBuilder)``
- ``background(_:)-(Background)``

### Adding Scenarios

- ``addScenario(_:)``
- ``addOutline(_:)``
- ``addRule(_:)``

### Steps

- ``given(_:)``
- ``when(_:)``
- ``then(_:)``
- ``and(_:)``
- ``but(_:)``
- ``step(_:)``

### Step Attachments

- ``table(_:)``
- ``docString(_:mediaType:)``

### Scenario Configuration

- ``scenarioTags(_:)``
- ``examples(_:)``
- ``examples(_:name:tags:)``

### Mutating API

- ``appendScenario(_:)``
- ``appendOutline(_:)``

### Build and Export

- ``build()``
- ``validate()``
- ``export(to:)``
