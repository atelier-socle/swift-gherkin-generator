import Testing
@testable import GherkinGenerator

// MARK: - StructureRule Tests

@Suite("StructureRule")
struct StructureRuleTests {

    private let rule = StructureRule()

    @Test("Valid scenario with Given and Then passes")
    func validScenario() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(Scenario(
                    title: "Success",
                    steps: [
                        Step(keyword: .given, text: "a valid account"),
                        Step(keyword: .when, text: "the user logs in"),
                        Step(keyword: .then, text: "dashboard is displayed"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Scenario missing Given reports error")
    func missingGiven() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(Scenario(
                    title: "No given",
                    steps: [
                        Step(keyword: .when, text: "the user logs in"),
                        Step(keyword: .then, text: "dashboard is displayed"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .missingGiven(scenario: "No given"))
    }

    @Test("Scenario missing Then reports error")
    func missingThen() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(Scenario(
                    title: "No then",
                    steps: [
                        Step(keyword: .given, text: "a valid account"),
                        Step(keyword: .when, text: "the user logs in"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .missingThen(scenario: "No then"))
    }

    @Test("Scenario missing both Given and Then reports two errors")
    func missingBoth() {
        let feature = Feature(
            title: "Login",
            children: [
                .scenario(Scenario(
                    title: "Empty-ish",
                    steps: [
                        Step(keyword: .when, text: "something happens"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
        #expect(errors.contains(.missingGiven(scenario: "Empty-ish")))
        #expect(errors.contains(.missingThen(scenario: "Empty-ish")))
    }

    @Test("And after Given counts as Given")
    func andAfterGiven() {
        let feature = Feature(
            title: "Setup",
            children: [
                .scenario(Scenario(
                    title: "With And",
                    steps: [
                        Step(keyword: .given, text: "a user"),
                        Step(keyword: .and, text: "a product"),
                        Step(keyword: .then, text: "the page loads"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("But after Then counts as Then")
    func butAfterThen() {
        let feature = Feature(
            title: "Validation",
            children: [
                .scenario(Scenario(
                    title: "With But",
                    steps: [
                        Step(keyword: .given, text: "a form"),
                        Step(keyword: .then, text: "success message shown"),
                        Step(keyword: .but, text: "no redirect happens"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Outline is also validated")
    func outlineValidated() {
        let feature = Feature(
            title: "Email",
            children: [
                .outline(ScenarioOutline(
                    title: "Missing steps",
                    steps: [
                        Step(keyword: .when, text: "I validate <email>"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
        #expect(errors.contains(.missingGiven(scenario: "Missing steps")))
        #expect(errors.contains(.missingThen(scenario: "Missing steps")))
    }

    @Test("Scenarios inside rules are validated")
    func scenariosInsideRule() {
        let feature = Feature(
            title: "Discount",
            children: [
                .rule(Rule(
                    title: "Premium rules",
                    children: [
                        .scenario(Scenario(
                            title: "No given in rule",
                            steps: [
                                Step(keyword: .when, text: "I buy"),
                                Step(keyword: .then, text: "discount applied"),
                            ]
                        )),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .missingGiven(scenario: "No given in rule"))
    }

    @Test("Background is not checked for Given/Then")
    func backgroundNotChecked() {
        let feature = Feature(
            title: "Orders",
            background: Background(steps: [
                Step(keyword: .given, text: "a logged-in user"),
            ]),
            children: [
                .scenario(Scenario(
                    title: "View orders",
                    steps: [
                        Step(keyword: .given, text: "existing orders"),
                        Step(keyword: .when, text: "I view my orders"),
                        Step(keyword: .then, text: "the list is displayed"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }
}

// MARK: - CoherenceRule Tests

@Suite("CoherenceRule")
struct CoherenceRuleTests {

    private let rule = CoherenceRule()

    @Test("No duplicates passes")
    func noDuplicates() {
        let feature = Feature(
            title: "Cart",
            children: [
                .scenario(Scenario(
                    title: "Add product",
                    steps: [
                        Step(keyword: .given, text: "an empty cart"),
                        Step(keyword: .when, text: "I add a product"),
                        Step(keyword: .then, text: "cart has 1 item"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Consecutive duplicate steps reports error")
    func consecutiveDuplicate() {
        let feature = Feature(
            title: "Cart",
            children: [
                .scenario(Scenario(
                    title: "Duplicate",
                    steps: [
                        Step(keyword: .given, text: "an empty cart"),
                        Step(keyword: .given, text: "an empty cart"),
                        Step(keyword: .then, text: "cart is empty"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .duplicateConsecutiveStep(step: "an empty cart", scenario: "Duplicate"))
    }

    @Test("Same text but different keyword is not a duplicate")
    func sameTextDifferentKeyword() {
        let feature = Feature(
            title: "Cart",
            children: [
                .scenario(Scenario(
                    title: "Not duplicate",
                    steps: [
                        Step(keyword: .given, text: "a product exists"),
                        Step(keyword: .when, text: "a product exists"),
                        Step(keyword: .then, text: "ok"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Duplicates in background are detected")
    func duplicatesInBackground() {
        let feature = Feature(
            title: "Setup",
            background: Background(steps: [
                Step(keyword: .given, text: "a user"),
                Step(keyword: .given, text: "a user"),
            ]),
            children: [
                .scenario(Scenario(
                    title: "Test",
                    steps: [
                        Step(keyword: .given, text: "data"),
                        Step(keyword: .then, text: "ok"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .duplicateConsecutiveStep(step: "a user", scenario: "Setup"))
    }

    @Test("Duplicates in outline are detected")
    func duplicatesInOutline() {
        let feature = Feature(
            title: "Email",
            children: [
                .outline(ScenarioOutline(
                    title: "Dup outline",
                    steps: [
                        Step(keyword: .given, text: "email <email>"),
                        Step(keyword: .given, text: "email <email>"),
                        Step(keyword: .then, text: "result <valid>"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .duplicateConsecutiveStep(step: "email <email>", scenario: "Dup outline"))
    }

    @Test("Duplicates in rule children are detected")
    func duplicatesInRuleChildren() {
        let feature = Feature(
            title: "Rules",
            children: [
                .rule(Rule(
                    title: "Business",
                    children: [
                        .scenario(Scenario(
                            title: "Dup in rule",
                            steps: [
                                Step(keyword: .then, text: "ok"),
                                Step(keyword: .then, text: "ok"),
                            ]
                        )),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .duplicateConsecutiveStep(step: "ok", scenario: "Dup in rule"))
    }

    @Test("Multiple consecutive duplicates reports multiple errors")
    func multipleDuplicates() {
        let feature = Feature(
            title: "Cart",
            children: [
                .scenario(Scenario(
                    title: "Triple",
                    steps: [
                        Step(keyword: .given, text: "a"),
                        Step(keyword: .given, text: "a"),
                        Step(keyword: .given, text: "a"),
                        Step(keyword: .then, text: "done"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
    }
}

// MARK: - TagFormatRule Tests

@Suite("TagFormatRule")
struct TagFormatRuleTests {

    private let rule = TagFormatRule()

    @Test("Valid tags pass")
    func validTags() {
        let feature = Feature(
            title: "Payment",
            tags: [Tag("smoke"), Tag("critical")],
            children: [
                .scenario(Scenario(
                    title: "Pay",
                    tags: [Tag("card")],
                    steps: [
                        Step(keyword: .given, text: "a cart"),
                        Step(keyword: .then, text: "paid"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Empty tag name reports error")
    func emptyTagName() {
        let feature = Feature(
            title: "Test",
            tags: [Tag("")],
            children: []
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .invalidTagFormat(tag: "@"))
    }

    @Test("Tag with spaces reports error")
    func tagWithSpaces() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(Scenario(
                    title: "Scenario",
                    tags: [Tag("has space")],
                    steps: []
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .invalidTagFormat(tag: "@has space"))
    }

    @Test("Invalid tags on rule are detected")
    func invalidTagOnRule() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(Rule(
                    title: "My rule",
                    tags: [Tag("ok"), Tag("not valid")]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .invalidTagFormat(tag: "@not valid"))
    }

    @Test("Invalid tags on examples are detected")
    func invalidTagOnExamples() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(ScenarioOutline(
                    title: "Outline",
                    steps: [
                        Step(keyword: .given, text: "something <x>"),
                        Step(keyword: .then, text: "result <y>"),
                    ],
                    examples: [
                        Examples(
                            tags: [Tag("bad tag")],
                            table: DataTable(rows: [["x", "y"], ["1", "2"]])
                        ),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .invalidTagFormat(tag: "@bad tag"))
    }

    @Test("Invalid tags on scenarios inside rules are detected")
    func invalidTagOnScenarioInsideRule() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(Rule(
                    title: "Rule",
                    children: [
                        .scenario(Scenario(
                            title: "Nested",
                            tags: [Tag("has space")],
                            steps: []
                        )),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
    }

    @Test("Invalid tags on outlines inside rules are detected")
    func invalidTagOnOutlineInsideRule() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(Rule(
                    title: "Rule",
                    children: [
                        .outline(ScenarioOutline(
                            title: "Outline in rule",
                            tags: [Tag("bad tag")],
                            examples: [
                                Examples(
                                    tags: [Tag("another bad")],
                                    table: DataTable(rows: [["a"], ["b"]])
                                ),
                            ]
                        )),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
    }
}

// MARK: - TableConsistencyRule Tests

@Suite("TableConsistencyRule")
struct TableConsistencyRuleTests {

    private let rule = TableConsistencyRule()

    @Test("Consistent table passes")
    func consistentTable() {
        let feature = Feature(
            title: "Pricing",
            children: [
                .scenario(Scenario(
                    title: "Prices",
                    steps: [
                        Step(
                            keyword: .given,
                            text: "the following prices",
                            dataTable: DataTable(rows: [
                                ["Quantity", "Price"],
                                ["1-10", "10"],
                                ["11-50", "8"],
                            ])
                        ),
                        Step(keyword: .then, text: "ok"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Inconsistent column count reports error")
    func inconsistentColumns() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(Scenario(
                    title: "Bad table",
                    steps: [
                        Step(
                            keyword: .given,
                            text: "data",
                            dataTable: DataTable(rows: [
                                ["a", "b", "c"],
                                ["1", "2"],
                            ])
                        ),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.inconsistentTableColumns(expected: 3, found: 2, row: 1)))
    }

    @Test("Empty cell reports error")
    func emptyCell() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(Scenario(
                    title: "Empty cell",
                    steps: [
                        Step(
                            keyword: .given,
                            text: "data",
                            dataTable: DataTable(rows: [
                                ["name", "value"],
                                ["key", ""],
                            ])
                        ),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.emptyTableCell(row: 1, column: 1)))
    }

    @Test("Empty table passes (no rows to validate)")
    func emptyTable() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(Scenario(
                    title: "Empty",
                    steps: [
                        Step(
                            keyword: .given,
                            text: "data",
                            dataTable: DataTable(rows: [])
                        ),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Examples tables are validated")
    func examplesTableValidated() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(ScenarioOutline(
                    title: "Outline",
                    steps: [
                        Step(keyword: .given, text: "<a>"),
                        Step(keyword: .then, text: "<b>"),
                    ],
                    examples: [
                        Examples(table: DataTable(rows: [
                            ["a", "b"],
                            ["1"],
                        ])),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.inconsistentTableColumns(expected: 2, found: 1, row: 1)))
    }

    @Test("Tables in background are validated")
    func backgroundTableValidated() {
        let feature = Feature(
            title: "Test",
            background: Background(steps: [
                Step(
                    keyword: .given,
                    text: "setup data",
                    dataTable: DataTable(rows: [
                        ["x", "y"],
                        ["1", ""],
                    ])
                ),
            ]),
            children: []
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.emptyTableCell(row: 1, column: 1)))
    }

    @Test("Tables inside rules are validated")
    func tablesInRuleValidated() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(Rule(
                    title: "My rule",
                    children: [
                        .scenario(Scenario(
                            title: "In rule",
                            steps: [
                                Step(
                                    keyword: .given,
                                    text: "data",
                                    dataTable: DataTable(rows: [
                                        ["a"],
                                        ["b", "c"],
                                    ])
                                ),
                            ]
                        )),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.inconsistentTableColumns(expected: 1, found: 2, row: 1)))
    }

    @Test("Multiple errors in one table are all reported")
    func multipleErrors() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(Scenario(
                    title: "Many issues",
                    steps: [
                        Step(
                            keyword: .given,
                            text: "data",
                            dataTable: DataTable(rows: [
                                ["a", "b"],
                                ["", ""],
                                ["x"],
                            ])
                        ),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.emptyTableCell(row: 1, column: 0)))
        #expect(errors.contains(.emptyTableCell(row: 1, column: 1)))
        #expect(errors.contains(.inconsistentTableColumns(expected: 2, found: 1, row: 2)))
    }
}

// MARK: - OutlinePlaceholderRule Tests

@Suite("OutlinePlaceholderRule")
struct OutlinePlaceholderRuleTests {

    private let rule = OutlinePlaceholderRule()

    @Test("All placeholders defined passes")
    func allDefined() {
        let feature = Feature(
            title: "Email",
            children: [
                .outline(ScenarioOutline(
                    title: "Validation",
                    steps: [
                        Step(keyword: .given, text: "the email <email>"),
                        Step(keyword: .when, text: "I validate"),
                        Step(keyword: .then, text: "the result is <valid>"),
                    ],
                    examples: [
                        Examples(table: DataTable(rows: [
                            ["email", "valid"],
                            ["test@example.com", "true"],
                            ["invalid", "false"],
                        ])),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Undefined placeholder reports error")
    func undefinedPlaceholder() {
        let feature = Feature(
            title: "Email",
            children: [
                .outline(ScenarioOutline(
                    title: "Missing col",
                    steps: [
                        Step(keyword: .given, text: "the email <email>"),
                        Step(keyword: .then, text: "the result is <valid>"),
                    ],
                    examples: [
                        Examples(table: DataTable(rows: [
                            ["email"],
                            ["test@example.com"],
                        ])),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .undefinedPlaceholder(placeholder: "valid", scenario: "Missing col"))
    }

    @Test("No placeholders passes")
    func noPlaceholders() {
        let feature = Feature(
            title: "Simple",
            children: [
                .outline(ScenarioOutline(
                    title: "No placeholders",
                    steps: [
                        Step(keyword: .given, text: "something"),
                        Step(keyword: .then, text: "result"),
                    ],
                    examples: [
                        Examples(table: DataTable(rows: [
                            ["a"],
                            ["b"],
                        ])),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Multiple undefined placeholders reported")
    func multipleUndefined() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(ScenarioOutline(
                    title: "Multi",
                    steps: [
                        Step(keyword: .given, text: "<a> and <b> and <c>"),
                        Step(keyword: .then, text: "done"),
                    ],
                    examples: [
                        Examples(table: DataTable(rows: [
                            ["a"],
                            ["1"],
                        ])),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 2)
        #expect(errors.contains(.undefinedPlaceholder(placeholder: "b", scenario: "Multi")))
        #expect(errors.contains(.undefinedPlaceholder(placeholder: "c", scenario: "Multi")))
    }

    @Test("Placeholders defined across multiple examples blocks passes")
    func multipleExamplesBlocks() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(ScenarioOutline(
                    title: "Split",
                    steps: [
                        Step(keyword: .given, text: "<a> and <b>"),
                        Step(keyword: .then, text: "done"),
                    ],
                    examples: [
                        Examples(table: DataTable(rows: [
                            ["a"],
                            ["1"],
                        ])),
                        Examples(table: DataTable(rows: [
                            ["b"],
                            ["2"],
                        ])),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Outlines inside rules are validated")
    func outlineInRule() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(Rule(
                    title: "Rule",
                    children: [
                        .outline(ScenarioOutline(
                            title: "In rule",
                            steps: [
                                Step(keyword: .given, text: "<x>"),
                                Step(keyword: .then, text: "<y>"),
                            ],
                            examples: [
                                Examples(table: DataTable(rows: [
                                    ["x"],
                                    ["1"],
                                ])),
                            ]
                        )),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.count == 1)
        #expect(errors[0] == .undefinedPlaceholder(placeholder: "y", scenario: "In rule"))
    }

    @Test("Regular scenarios are ignored")
    func regularScenarioIgnored() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(Scenario(
                    title: "Not outline",
                    steps: [
                        Step(keyword: .given, text: "something <looks like placeholder>"),
                        Step(keyword: .then, text: "ok"),
                    ]
                )),
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }
}

// MARK: - GherkinValidator Integration Tests

@Suite("GherkinValidator")
struct GherkinValidatorTests {

    @Test("Valid feature passes all default rules")
    func validFeaturePasses() {
        let feature = Feature(
            title: "Shopping Cart",
            tags: [Tag("smoke")],
            children: [
                .scenario(Scenario(
                    title: "Add product",
                    tags: [Tag("cart")],
                    steps: [
                        Step(keyword: .given, text: "an empty cart"),
                        Step(keyword: .when, text: "I add a product"),
                        Step(keyword: .then, text: "cart contains 1 item"),
                    ]
                )),
            ]
        )
        let validator = GherkinValidator()
        let errors = validator.collectErrors(in: feature)
        #expect(errors.isEmpty)
    }

    @Test("validate() throws on first error")
    func validateThrows() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(Scenario(
                    title: "No steps",
                    steps: []
                )),
            ]
        )
        let validator = GherkinValidator()
        #expect(throws: GherkinError.self) {
            try validator.validate(feature)
        }
    }

    @Test("Custom rules are applied")
    func customRules() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(Scenario(
                    title: "Valid",
                    steps: [
                        Step(keyword: .given, text: "a"),
                        Step(keyword: .then, text: "b"),
                    ]
                )),
            ]
        )
        let validator = GherkinValidator(rules: [StructureRule()])
        let errors = validator.collectErrors(in: feature)
        #expect(errors.isEmpty)
    }

    @Test("Multiple rules accumulate errors")
    func multipleRulesAccumulate() {
        let feature = Feature(
            title: "Test",
            tags: [Tag("has space")],
            children: [
                .scenario(Scenario(
                    title: "Bad",
                    steps: [
                        Step(keyword: .when, text: "something"),
                    ]
                )),
            ]
        )
        let validator = GherkinValidator(rules: [StructureRule(), TagFormatRule()])
        let errors = validator.collectErrors(in: feature)
        #expect(errors.count == 3)
    }
}
