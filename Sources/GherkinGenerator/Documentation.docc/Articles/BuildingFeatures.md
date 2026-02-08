# Building Features

Compose Gherkin features programmatically using the fluent builder API.

## Overview

``GherkinFeature`` provides a chainable, immutable API for constructing `.feature` files. Every method returns a new copy of the builder, making it `Sendable`-safe and suitable for concurrent use.

## Scenarios

Start a scenario with ``GherkinFeature/addScenario(_:)`` then chain steps:

```swift
let feature = try GherkinFeature(title: "Shopping Cart")
    .addScenario("Add a product")
    .given("an empty cart")
    .when("I add a product at 29€")
    .then("the cart contains 1 item")
    .and("the total is 29€")
    .but("no discount is applied")
    .build()
```

## Background

Define shared preconditions that run before every scenario using a closure. The closure receives a ``BackgroundBuilder``:

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

You can also set a pre-built ``Background`` value directly.

## Scenario Outlines

Use ``GherkinFeature/addOutline(_:)`` for parameterized scenarios. Placeholders in angle brackets are substituted from the examples table:

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

Named and tagged examples blocks are supported via ``GherkinFeature/examples(_:name:tags:)``:

```swift
.examples(
    [["email", "valid"], ["test@example.com", "true"]],
    name: "Valid emails",
    tags: ["@positive"]
)
```

## Data Tables

Attach a data table to any step with ``GherkinFeature/table(_:)``. The first row is the header:

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

## Doc Strings

Attach multi-line text with an optional media type using ``GherkinFeature/docString(_:mediaType:)``:

```swift
let feature = try GherkinFeature(title: "API")
    .addScenario("POST request")
    .given("a request body")
    .docString("{\"key\": \"value\"}", mediaType: "application/json")
    .then("status 201")
    .build()
```

## Tags

Apply tags at feature level with ``GherkinFeature/tags(_:)`` and at scenario level with ``GherkinFeature/scenarioTags(_:)``:

```swift
let feature = try GherkinFeature(title: "Payment")
    .tags(["@payment", "@critical"])
    .addScenario("Credit card")
    .scenarioTags(["@card", "@slow"])
    .given("a validated cart")
    .then("payment is processed")
    .build()
```

## Rules

Add pre-built ``Rule`` values with ``GherkinFeature/addRule(_:)``:

```swift
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

let feature = try GherkinFeature(title: "E-Commerce Platform")
    .addRule(catalogRule)
    .build()
```

## Mass Generation

Use `var` and reassignment for loop-based generation of many scenarios:

```swift
var builder = GherkinFeature(title: "Load Test Scenarios")
for i in 1...100 {
    builder =
        builder
        .addScenario("Scenario \(i)")
        .given("precondition \(i)")
        .when("action \(i)")
        .then("expected result \(i)")
}
let feature = try builder.build()
```

For a mutating approach, use ``GherkinFeature/appendScenario(_:)`` or ``GherkinFeature/appendOutline(_:)`` instead.

## Validate and Export

Use ``GherkinFeature/validate()`` to check for structural errors and ``GherkinFeature/export(to:)`` to write directly to disk:

```swift
let builder = GherkinFeature(title: "Export Test")
    .addScenario("Scenario")
    .given("a precondition")
    .then("a result")

try builder.validate()
try await builder.export(to: "output.feature")
```
