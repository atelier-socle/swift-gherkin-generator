import Foundation
import Testing

@testable import GherkinGenerator

/// End-to-end showcase: streaming and high-volume processing.
///
/// Demonstrates building a large feature programmatically, streaming
/// export with progress tracking, and streaming batch import.
@Suite("Showcase — Streaming & Volume")
struct ShowcaseStreamingTests {

    // MARK: - Large Feature Generation

    /// Builds a feature with 100+ scenarios programmatically using a loop.
    @Test("Build feature with 100 scenarios programmatically")
    func buildLargeFeature() throws {
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

        #expect(feature.children.count == 100)
        #expect(feature.scenarios[0].title == "Scenario 1")
        #expect(feature.scenarios[99].title == "Scenario 100")
    }

    // MARK: - Streaming Lines

    /// Uses StreamingExporter.lines(for:) to collect all output lines from
    /// a large feature — verifies the line count is consistent.
    @Test("StreamingExporter.lines yields all formatted lines")
    func streamingLines() async throws {
        let feature = try buildLargeFeature(count: 50)
        let streamer = StreamingExporter()
        var lines: [String] = []

        for await line in await streamer.lines(for: feature) {
            lines.append(line)
        }

        // At minimum: 1 Feature line + 50 * (Scenario + Given + When + Then) = 201+
        #expect(lines.count > 200)
        #expect(lines.first?.contains("Feature:") == true)
    }

    // MARK: - Streaming Export with Progress

    /// Uses StreamingExporter.exportWithProgress to track progress from 0 to 1.
    @Test("StreamingExporter.exportWithProgress tracks progress 0 → 1")
    func streamingExportProgress() async throws {
        let feature = try buildLargeFeature(count: 20)
        let tempPath = NSTemporaryDirectory() + "showcase-stream-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let streamer = StreamingExporter()
        var fractions: [Double] = []

        for await progress in await streamer.exportWithProgress(feature, to: tempPath) {
            fractions.append(progress.fractionCompleted)
        }

        #expect(!fractions.isEmpty)
        #expect(fractions.last == 1.0)

        // Verify the file was written
        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
        #expect(content.contains("Feature:"))
    }

    // MARK: - Stream Export → Parse Round-trip

    /// Exports a large feature via StreamingExporter, re-parses it,
    /// and verifies the structure survives the round-trip.
    @Test("StreamingExporter export → parse round-trip")
    func streamExportRoundTrip() async throws {
        let original = try buildLargeFeature(count: 30)
        let tempPath = NSTemporaryDirectory() + "showcase-rt-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let streamer = StreamingExporter()
        try await streamer.export(original, to: tempPath)

        let parsed = try GherkinParser().parse(contentsOfFile: tempPath)
        #expect(parsed.title == original.title)
        #expect(parsed.children.count == original.children.count)
    }

    // MARK: - Batch Import Streaming

    /// Uses BatchImporter.streamDirectory to receive features as they are
    /// parsed — verifies streaming delivers all results.
    @Test("BatchImporter.streamDirectory yields features as they are parsed")
    func batchImportStreaming() async throws {
        let tempDir = NSTemporaryDirectory() + "showcase-batchstream-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: tempDir) }
        try FileManager.default.createDirectory(
            atPath: tempDir, withIntermediateDirectories: true)

        // Write 5 feature files
        for i in 1...5 {
            let content = """
                Feature: Feature \(i)
                  Scenario: Test \(i)
                    Given step \(i)
                    When action \(i)
                    Then result \(i)
                """
            try content.write(
                toFile: (tempDir as NSString).appendingPathComponent("f\(i).feature"),
                atomically: true, encoding: .utf8)
        }

        let importer = BatchImporter()
        var received: [Result<Feature, GherkinError>] = []

        for await result in await importer.streamDirectory(at: tempDir) {
            received.append(result)
        }

        #expect(received.count == 5)
        let features = received.compactMap { try? $0.get() }
        #expect(features.count == 5)
    }

    // MARK: - Helper

    private func buildLargeFeature(count: Int) throws -> Feature {
        var builder = GherkinFeature(title: "Volume Feature")
        for i in 1...count {
            builder =
                builder
                .addScenario("Scenario \(i)")
                .given("precondition \(i)")
                .when("action \(i)")
                .then("result \(i)")
        }
        return try builder.build()
    }
}
