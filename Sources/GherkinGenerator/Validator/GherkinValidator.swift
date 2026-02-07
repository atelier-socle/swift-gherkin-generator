/// A stateless validator for Gherkin features.
///
/// `GherkinValidator` checks a ``Feature`` for structural correctness,
/// coherence, and compliance with Gherkin conventions. It reports
/// all issues found, not just the first one.
///
/// ```swift
/// let validator = GherkinValidator()
/// let errors = validator.collectErrors(in: feature)
/// if errors.isEmpty {
///     print("Feature is valid!")
/// }
/// ```
///
/// ## Custom Rules
///
/// Add custom validation rules by conforming to ``ValidationRule``:
///
/// ```swift
/// let validator = GherkinValidator(rules: [
///     StructureRule(),
///     TagFormatRule(),
///     MyCustomRule(),
/// ])
/// ```
public struct GherkinValidator: Sendable {
    /// The validation rules to apply.
    public let rules: [any ValidationRule]

    /// Creates a validator with the default set of rules.
    public init() {
        self.rules = Self.defaultRules
    }

    /// Creates a validator with custom rules.
    ///
    /// - Parameter rules: The validation rules to apply.
    public init(rules: [any ValidationRule]) {
        self.rules = rules
    }

    /// Validates a feature and throws on the first error.
    ///
    /// - Parameter feature: The feature to validate.
    /// - Throws: ``GherkinError`` for the first validation failure.
    public func validate(_ feature: Feature) throws {
        let errors = collectErrors(in: feature)
        if let first = errors.first {
            throw first
        }
    }

    /// Collects all validation errors in a feature.
    ///
    /// Unlike ``validate(_:)``, this method returns all issues found
    /// rather than stopping at the first one.
    ///
    /// - Parameter feature: The feature to validate.
    /// - Returns: An array of validation errors (empty if valid).
    public func collectErrors(in feature: Feature) -> [GherkinError] {
        var errors: [GherkinError] = []
        for rule in rules {
            errors.append(contentsOf: rule.validate(feature))
        }
        return errors
    }

    /// The default set of validation rules.
    public static let defaultRules: [any ValidationRule] = [
        StructureRule(),
        CoherenceRule(),
        TagFormatRule(),
        TableConsistencyRule(),
        OutlinePlaceholderRule(),
    ]
}

// MARK: - Built-in Rules

/// Validates scenario structure (Given/Then requirements).
///
/// Each scenario and scenario outline must have at least one `Given` step
/// (or an `And`/`But` that follows a `Given`) and at least one `Then` step
/// (or an `And`/`But` that follows a `Then`). Background steps are excluded
/// from this check.
public struct StructureRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        var errors: [GherkinError] = []
        for child in feature.children {
            switch child {
            case .scenario(let scenario):
                errors.append(contentsOf: validateSteps(scenario.steps, title: scenario.title))
            case .outline(let outline):
                errors.append(contentsOf: validateSteps(outline.steps, title: outline.title))
            case .rule(let rule):
                for ruleChild in rule.children {
                    switch ruleChild {
                    case .scenario(let scenario):
                        errors.append(contentsOf: validateSteps(scenario.steps, title: scenario.title))
                    case .outline(let outline):
                        errors.append(contentsOf: validateSteps(outline.steps, title: outline.title))
                    }
                }
            }
        }
        return errors
    }

    private func validateSteps(_ steps: [Step], title: String) -> [GherkinError] {
        var errors: [GherkinError] = []
        let hasGiven = stepsContainEffectiveKeyword(.given, in: steps)
        let hasThen = stepsContainEffectiveKeyword(.then, in: steps)
        if !hasGiven {
            errors.append(.missingGiven(scenario: title))
        }
        if !hasThen {
            errors.append(.missingThen(scenario: title))
        }
        return errors
    }

    /// Checks whether the steps contain an effective keyword, considering
    /// that `And`/`But` inherit the keyword of the preceding primary step.
    private func stepsContainEffectiveKeyword(_ target: StepKeyword, in steps: [Step]) -> Bool {
        var lastPrimaryKeyword: StepKeyword?
        for step in steps {
            switch step.keyword {
            case .given, .when, .then:
                lastPrimaryKeyword = step.keyword
            case .and, .but, .wildcard:
                break
            }
            let effective = effectiveKeyword(for: step, lastPrimary: lastPrimaryKeyword)
            if effective == target {
                return true
            }
        }
        return false
    }

    private func effectiveKeyword(for step: Step, lastPrimary: StepKeyword?) -> StepKeyword {
        switch step.keyword {
        case .given, .when, .then:
            return step.keyword
        case .and, .but, .wildcard:
            return lastPrimary ?? step.keyword
        }
    }
}

/// Validates coherence (no consecutive duplicate steps).
///
/// Two consecutive steps with the same keyword and the same text
/// are considered duplicates.
public struct CoherenceRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        var errors: [GherkinError] = []
        for child in feature.children {
            switch child {
            case .scenario(let scenario):
                errors.append(contentsOf: checkDuplicates(scenario.steps, title: scenario.title))
            case .outline(let outline):
                errors.append(contentsOf: checkDuplicates(outline.steps, title: outline.title))
            case .rule(let rule):
                if let background = rule.background {
                    errors.append(contentsOf: checkDuplicates(background.steps, title: rule.title))
                }
                for ruleChild in rule.children {
                    switch ruleChild {
                    case .scenario(let scenario):
                        errors.append(contentsOf: checkDuplicates(scenario.steps, title: scenario.title))
                    case .outline(let outline):
                        errors.append(contentsOf: checkDuplicates(outline.steps, title: outline.title))
                    }
                }
            }
        }
        if let background = feature.background {
            errors.append(contentsOf: checkDuplicates(background.steps, title: feature.title))
        }
        return errors
    }

    private func checkDuplicates(_ steps: [Step], title: String) -> [GherkinError] {
        var errors: [GherkinError] = []
        for index in steps.indices.dropFirst() {
            let previous = steps[index - 1]
            let current = steps[index]
            if current.keyword == previous.keyword && current.text == previous.text {
                errors.append(.duplicateConsecutiveStep(step: current.text, scenario: title))
            }
        }
        return errors
    }
}

/// Validates tag format (name must be non-empty and contain no spaces).
///
/// Checks all tags at every level: feature, scenarios, scenario outlines,
/// rules, and examples blocks.
public struct TagFormatRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        var errors: [GherkinError] = []
        errors.append(contentsOf: validateTags(feature.tags))
        for child in feature.children {
            switch child {
            case .scenario(let scenario):
                errors.append(contentsOf: validateTags(scenario.tags))
            case .outline(let outline):
                errors.append(contentsOf: validateTags(outline.tags))
                for example in outline.examples {
                    errors.append(contentsOf: validateTags(example.tags))
                }
            case .rule(let rule):
                errors.append(contentsOf: validateTags(rule.tags))
                for ruleChild in rule.children {
                    switch ruleChild {
                    case .scenario(let scenario):
                        errors.append(contentsOf: validateTags(scenario.tags))
                    case .outline(let outline):
                        errors.append(contentsOf: validateTags(outline.tags))
                        for example in outline.examples {
                            errors.append(contentsOf: validateTags(example.tags))
                        }
                    }
                }
            }
        }
        return errors
    }

    private func validateTags(_ tags: [Tag]) -> [GherkinError] {
        var errors: [GherkinError] = []
        for tag in tags {
            if tag.name.isEmpty || tag.name.contains(" ") {
                errors.append(.invalidTagFormat(tag: tag.rawValue))
            }
        }
        return errors
    }
}

/// Validates data table consistency (column counts and no empty cells).
///
/// For every data table (in steps and in examples blocks), all rows must
/// have the same number of columns as the first row, and no cell may be
/// an empty string.
public struct TableConsistencyRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        var errors: [GherkinError] = []
        let allTables = collectTables(from: feature)
        for table in allTables {
            errors.append(contentsOf: validateTable(table))
        }
        return errors
    }

    private func collectTables(from feature: Feature) -> [DataTable] {
        var tables: [DataTable] = []
        if let background = feature.background {
            tables.append(contentsOf: tablesFromSteps(background.steps))
        }
        for child in feature.children {
            switch child {
            case .scenario(let scenario):
                tables.append(contentsOf: tablesFromSteps(scenario.steps))
            case .outline(let outline):
                tables.append(contentsOf: tablesFromSteps(outline.steps))
                for example in outline.examples {
                    tables.append(example.table)
                }
            case .rule(let rule):
                if let background = rule.background {
                    tables.append(contentsOf: tablesFromSteps(background.steps))
                }
                for ruleChild in rule.children {
                    switch ruleChild {
                    case .scenario(let scenario):
                        tables.append(contentsOf: tablesFromSteps(scenario.steps))
                    case .outline(let outline):
                        tables.append(contentsOf: tablesFromSteps(outline.steps))
                        for example in outline.examples {
                            tables.append(example.table)
                        }
                    }
                }
            }
        }
        return tables
    }

    private func tablesFromSteps(_ steps: [Step]) -> [DataTable] {
        steps.compactMap { $0.dataTable }
    }

    private func validateTable(_ table: DataTable) -> [GherkinError] {
        guard !table.isEmpty else { return [] }
        var errors: [GherkinError] = []
        let expectedColumns = table.columnCount
        for (rowIndex, row) in table.rows.enumerated() {
            if row.count != expectedColumns {
                errors.append(.inconsistentTableColumns(expected: expectedColumns, found: row.count, row: rowIndex))
            }
            for (columnIndex, cell) in row.enumerated() {
                if cell.isEmpty {
                    errors.append(.emptyTableCell(row: rowIndex, column: columnIndex))
                }
            }
        }
        return errors
    }
}

/// Validates Scenario Outline placeholders match Examples columns.
///
/// Every `<placeholder>` found in the step texts of a scenario outline
/// must correspond to a column header in at least one of its examples blocks.
public struct OutlinePlaceholderRule: ValidationRule, Sendable {
    public init() {}

    public func validate(_ feature: Feature) -> [GherkinError] {
        var errors: [GherkinError] = []
        for child in feature.children {
            switch child {
            case .scenario:
                break
            case .outline(let outline):
                errors.append(contentsOf: validateOutline(outline))
            case .rule(let rule):
                for ruleChild in rule.children {
                    switch ruleChild {
                    case .scenario:
                        break
                    case .outline(let outline):
                        errors.append(contentsOf: validateOutline(outline))
                    }
                }
            }
        }
        return errors
    }

    private func validateOutline(_ outline: ScenarioOutline) -> [GherkinError] {
        let placeholders = extractPlaceholders(from: outline.steps)
        guard !placeholders.isEmpty else { return [] }

        var definedColumns: Set<String> = []
        for example in outline.examples {
            if let headers = example.table.headers {
                for header in headers {
                    definedColumns.insert(header)
                }
            }
        }

        var errors: [GherkinError] = []
        for placeholder in placeholders.sorted() {
            if !definedColumns.contains(placeholder) {
                errors.append(.undefinedPlaceholder(placeholder: placeholder, scenario: outline.title))
            }
        }
        return errors
    }

    private func extractPlaceholders(from steps: [Step]) -> Set<String> {
        var placeholders: Set<String> = []
        let pattern = /<([^>]+)>/
        for step in steps {
            for match in step.text.matches(of: pattern) {
                placeholders.insert(String(match.1))
            }
        }
        return placeholders
    }
}
