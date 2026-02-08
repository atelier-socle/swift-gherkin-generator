import ArgumentParser

/// Root command for the `gherkin-gen` CLI tool.
///
/// This type lives in the `GherkinGenCLICore` library so that tests can
/// `@testable import GherkinGenCLICore` and call `parseAsRoot`.
/// The thin `@main` entry point in the `GherkinGenCLI` executable
/// simply invokes ``GherkinGen/main()``.
public struct GherkinGen: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "gherkin-gen",
        abstract: "Compose, validate, and convert Gherkin .feature files.",
        subcommands: [
            GenerateCommand.self,
            ValidateCommand.self,
            ParseCommand.self,
            ExportCommand.self,
            BatchExportCommand.self,
            ConvertCommand.self,
            LanguagesCommand.self
        ]
    )

    public init() {}
}
