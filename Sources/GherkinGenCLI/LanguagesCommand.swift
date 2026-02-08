import ArgumentParser
import GherkinGenerator

/// Lists supported Gherkin languages and their keywords.
struct LanguagesCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "languages",
        abstract: "List supported Gherkin languages and keywords."
    )

    @Option(name: .long, help: "Show keywords for a specific language code.")
    var code: String?

    func run() async throws {
        if let languageCode = code {
            try showLanguageDetail(code: languageCode)
        } else {
            listAllLanguages()
        }
    }

    private func listAllLanguages() {
        let languages = GherkinLanguage.all
        let codeWidth = 8
        let nameWidth = 24

        let header =
            "Code".padding(toLength: codeWidth, withPad: " ", startingAt: 0)
            + "Name".padding(toLength: nameWidth, withPad: " ", startingAt: 0)
            + "Native Name"
        print(ANSIColor.bold(header))
        print(String(repeating: "-", count: 60))

        for language in languages {
            let line =
                language.code.padding(toLength: codeWidth, withPad: " ", startingAt: 0)
                + language.name.padding(toLength: nameWidth, withPad: " ", startingAt: 0)
                + language.nativeName
            print(line)
        }

        print("\n\(languages.count) languages supported.")
    }

    private func showLanguageDetail(code languageCode: String) throws {
        guard let language = GherkinLanguage(code: languageCode) else {
            throw ValidationError("Unknown language code: '\(languageCode)'")
        }

        let keywords = language.keywords

        print(ANSIColor.bold("\(language.name) (\(language.code))"))
        print(ANSIColor.bold("Native name:") + " \(language.nativeName)")
        print("")
        printKeywords("Feature", keywords.feature)
        printKeywords("Rule", keywords.rule)
        printKeywords("Background", keywords.background)
        printKeywords("Scenario", keywords.scenario)
        printKeywords("Scenario Outline", keywords.scenarioOutline)
        printKeywords("Examples", keywords.examples)
        printKeywords("Given", keywords.given)
        printKeywords("When", keywords.when)
        printKeywords("Then", keywords.then)
        printKeywords("And", keywords.and)
        printKeywords("But", keywords.but)
    }

    private func printKeywords(_ label: String, _ keywords: [String]) {
        let formatted = keywords.map { "\"" + $0 + "\"" }.joined(separator: ", ")
        let paddedLabel = (label + ":").padding(
            toLength: 20,
            withPad: " ",
            startingAt: 0
        )
        print(ANSIColor.bold(paddedLabel) + formatted)
    }
}
