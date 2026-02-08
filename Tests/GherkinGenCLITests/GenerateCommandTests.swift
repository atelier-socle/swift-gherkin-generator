import ArgumentParser
import Foundation
import GherkinGenerator
import Testing

@testable import GherkinGenCLICore

@Suite("GenerateCommand")
struct GenerateCommandTests {

    @Test("Generates valid .feature output via argument parsing")
    func generateToFile() async throws {
        let outputPath = NSTemporaryDirectory() + "generate-test-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "generate",
            "--title", "Shopping Cart",
            "--scenario", "Add a product",
            "--given", "an empty cart",
            "--when", "I add a product at 29€",
            "--then", "the cart contains 1 item",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: Shopping Cart"))
        #expect(content.contains("Add a product"))
        #expect(content.contains("Given an empty cart"))
        #expect(content.contains("When I add a product at 29€"))
        #expect(content.contains("Then the cart contains 1 item"))
    }

    @Test("Generates French keywords with --language fr")
    func generateFrench() async throws {
        let outputPath = NSTemporaryDirectory() + "generate-fr-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "generate",
            "--title", "Panier",
            "--scenario", "Ajouter un produit",
            "--given", "un panier vide",
            "--when", "j'ajoute un produit",
            "--then", "le panier contient 1 article",
            "--language", "fr",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("# language: fr"))
        #expect(content.contains("Panier"))
        #expect(content.contains("un panier vide"))
    }

    @Test("Generates feature with tags")
    func generateWithTags() async throws {
        let outputPath = NSTemporaryDirectory() + "generate-tags-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "generate",
            "--title", "Tagged Feature",
            "--scenario", "Test",
            "--given", "something",
            "--then", "something else",
            "--tag", "smoke",
            "--tag", "regression",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("@smoke"))
        #expect(content.contains("@regression"))
    }

    @Test("Rejects unknown language code")
    func unknownLanguage() async throws {
        let arguments = [
            "generate",
            "--title", "Test",
            "--scenario", "Test",
            "--given", "x",
            "--then", "y",
            "--language", "xx"
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        await #expect(throws: (any Error).self) {
            try await execute(command)
        }
    }
}

/// Executes a parsed ArgumentParser command.
private func execute(_ command: any ParsableCommand) async throws {
    if var asyncCommand = command as? any AsyncParsableCommand {
        try await asyncCommand.run()
    } else {
        var mutableCommand = command
        try mutableCommand.run()
    }
}
