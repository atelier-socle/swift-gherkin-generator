/// An inline data table attached to a Gherkin step.
///
/// Data tables provide structured data in a pipe-delimited format.
/// The first row typically contains column headers.
///
/// ```swift
/// let table = DataTable(rows: [
///     ["name", "email"],
///     ["Alice", "alice@example.com"],
///     ["Bob", "bob@example.com"],
/// ])
/// ```
public struct DataTable: Sendable, Hashable, Codable {
    /// The rows of the table. Each row is an array of cell values.
    /// The first row is typically the header row.
    public let rows: [[String]]

    /// The number of columns in the table, determined by the first row.
    /// Returns `0` if the table is empty.
    public var columnCount: Int { rows.first?.count ?? 0 }

    /// The number of rows in the table, including the header row.
    public var rowCount: Int { rows.count }

    /// Whether the table has no rows.
    public var isEmpty: Bool { rows.isEmpty }

    /// The header row (first row), if any.
    public var headers: [String]? { rows.first }

    /// The data rows (all rows except the first).
    public var dataRows: [[String]] {
        guard rows.count > 1 else { return [] }
        return Array(rows.dropFirst())
    }

    /// Creates a new data table.
    ///
    /// - Parameter rows: The rows of the table. Each row should have
    ///   the same number of columns.
    public init(rows: [[String]]) {
        self.rows = rows
    }
}
