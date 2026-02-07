/// The keyword type for a Gherkin step.
///
/// Represents the standard Gherkin keywords used to begin steps
/// in scenarios, backgrounds, and scenario outlines.
///
/// ```swift
/// let step = Step(keyword: .given, text: "a valid account")
/// ```
public enum StepKeyword: String, Sendable, Hashable, CaseIterable, Codable {
    /// A precondition step (`Given`).
    case given

    /// An action step (`When`).
    case when

    /// An expected outcome step (`Then`).
    case then

    /// A continuation of the previous step type (`And`).
    case and

    /// An alternative continuation of the previous step type (`But`).
    case but

    /// A wildcard step (`*`), used when the keyword is unimportant.
    case wildcard
}

/// A single step in a Gherkin scenario.
///
/// Steps are the building blocks of scenarios. Each step has a keyword
/// (`Given`, `When`, `Then`, `And`, `But`, or `*`) and descriptive text.
/// Steps may optionally include a data table or a doc string.
///
/// ```swift
/// let step = Step(keyword: .given, text: "the following users")
///     .withTable(DataTable(rows: [["name", "role"], ["Alice", "admin"]]))
/// ```
public struct Step: Sendable, Hashable, Codable {
    /// The step keyword (`Given`, `When`, `Then`, `And`, `But`, `*`).
    public let keyword: StepKeyword

    /// The descriptive text following the keyword.
    public let text: String

    /// An optional inline data table attached to this step.
    public let dataTable: DataTable?

    /// An optional doc string attached to this step.
    public let docString: DocString?

    /// Creates a new step.
    ///
    /// - Parameters:
    ///   - keyword: The step keyword.
    ///   - text: The descriptive text for this step.
    ///   - dataTable: An optional data table. Defaults to `nil`.
    ///   - docString: An optional doc string. Defaults to `nil`.
    public init(
        keyword: StepKeyword,
        text: String,
        dataTable: DataTable? = nil,
        docString: DocString? = nil
    ) {
        self.keyword = keyword
        self.text = text
        self.dataTable = dataTable
        self.docString = docString
    }

    /// Returns a copy of this step with the given data table attached.
    ///
    /// - Parameter dataTable: The data table to attach.
    /// - Returns: A new step with the data table.
    public func withTable(_ dataTable: DataTable) -> Step {
        Step(keyword: keyword, text: text, dataTable: dataTable, docString: docString)
    }

    /// Returns a copy of this step with the given doc string attached.
    ///
    /// - Parameter docString: The doc string to attach.
    /// - Returns: A new step with the doc string.
    public func withDocString(_ docString: DocString) -> Step {
        Step(keyword: keyword, text: text, dataTable: dataTable, docString: docString)
    }
}
