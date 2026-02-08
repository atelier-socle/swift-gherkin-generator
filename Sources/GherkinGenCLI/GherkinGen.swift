import ArgumentParser

/// Root command for the `gherkin-gen` CLI tool.
@main
struct GherkinGen: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "gherkin-gen",
        abstract: "Compose, validate, and convert Gherkin .feature files.",
        subcommands: [
            GenerateCommand.self,
            ValidateCommand.self,
            ParseCommand.self,
            ExportCommand.self,
            ConvertCommand.self,
            LanguagesCommand.self
        ]
    )
}
