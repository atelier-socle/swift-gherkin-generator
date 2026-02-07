import Foundation

/// A parser that imports Gherkin features from JSON data.
///
/// `JSONFeatureParser` decodes JSON produced by ``GherkinExporter``'s
/// JSON format, providing a round-trip guarantee: exporting a feature
/// to JSON and importing it back produces an identical ``Feature``.
///
/// ```swift
/// let parser = JSONFeatureParser()
/// let feature = try parser.parse(jsonString)
/// ```
public struct JSONFeatureParser: Sendable {

    /// Creates a new JSON feature parser.
    public init() {}

    /// Parses a JSON string into a ``Feature``.
    ///
    /// - Parameter source: The JSON string to parse.
    /// - Returns: The decoded feature.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if decoding fails.
    public func parse(_ source: String) throws -> Feature {
        guard let data = source.data(using: .utf8) else {
            throw GherkinError.importFailed(path: "", reason: "Invalid UTF-8 in JSON source")
        }
        return try parse(data: data)
    }

    /// Parses JSON data into a ``Feature``.
    ///
    /// - Parameter data: The JSON data to decode.
    /// - Returns: The decoded feature.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if decoding fails.
    public func parse(data: Data) throws -> Feature {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Feature.self, from: data)
        } catch {
            throw GherkinError.importFailed(path: "", reason: error.localizedDescription)
        }
    }

    /// Parses a JSON file at the given path into a ``Feature``.
    ///
    /// - Parameter path: The path to the JSON file.
    /// - Returns: The decoded feature.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if the file cannot be read or decoded.
    public func parse(contentsOfFile path: String) throws -> Feature {
        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            throw GherkinError.importFailed(path: path, reason: error.localizedDescription)
        }
        return try parse(data: data)
    }
}
