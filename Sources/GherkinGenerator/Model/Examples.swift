/// An examples block for a Scenario Outline.
///
/// Examples provide concrete values for the placeholders defined in
/// a Scenario Outline's steps. Each examples block can have its own
/// tags and an optional name.
///
/// ```swift
/// let examples = Examples(
///     table: DataTable(rows: [
///         ["email", "valid"],
///         ["test@example.com", "true"],
///         ["invalid", "false"],
///     ])
/// )
/// ```
public struct Examples: Sendable, Hashable, Codable {
    /// An optional name for this examples block.
    public let name: String?

    /// Tags attached to this examples block.
    public let tags: [Tag]

    /// The data table containing header row and example rows.
    public let table: DataTable

    /// Creates a new examples block.
    ///
    /// - Parameters:
    ///   - name: An optional name. Defaults to `nil`.
    ///   - tags: Tags for this block. Defaults to empty.
    ///   - table: The data table with headers and rows.
    public init(name: String? = nil, tags: [Tag] = [], table: DataTable) {
        self.name = name
        self.tags = tags
        self.table = table
    }
}
