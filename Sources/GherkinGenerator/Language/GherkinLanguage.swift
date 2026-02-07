/// A language for Gherkin keyword localization.
///
/// Gherkin supports 70+ languages, each providing localized keywords
/// for `Feature`, `Scenario`, `Given`, `When`, `Then`, etc.
///
/// Use ``keywords`` to access the localized keyword set for a language.
///
/// ```swift
/// let lang = GherkinLanguage.french
/// print(lang.keywords.feature) // ["Fonctionnalité"]
/// print(lang.keywords.given)   // ["Soit", "Etant donné", ...]
/// ```
///
/// - Note: The full set of 70+ languages will be loaded from the official
///   `gherkin-languages.json`. This enum provides the most commonly used
///   languages as static members with support for custom languages.
public struct GherkinLanguage: Sendable, Hashable, Codable {
    /// The ISO language code (e.g., `"en"`, `"fr"`, `"de"`).
    public let code: String

    /// The language name in English.
    public let name: String

    /// The native language name.
    public let nativeName: String

    /// Creates a language with the given code and names.
    ///
    /// - Parameters:
    ///   - code: The ISO language code.
    ///   - name: The English language name.
    ///   - nativeName: The native language name.
    public init(code: String, name: String, nativeName: String) {
        self.code = code
        self.name = name
        self.nativeName = nativeName
    }

    /// The localized keywords for this language.
    ///
    /// Returns the keyword set registered for this language code,
    /// or falls back to English keywords if the code is not registered.
    public var keywords: LanguageKeywords {
        LanguageKeywords.keywords(for: code)
    }
}

// MARK: - Common Languages

extension GherkinLanguage {
    /// English (default).
    public static let english = GherkinLanguage(code: "en", name: "English", nativeName: "English")

    /// French.
    public static let french = GherkinLanguage(code: "fr", name: "French", nativeName: "Français")

    /// German.
    public static let german = GherkinLanguage(code: "de", name: "German", nativeName: "Deutsch")

    /// Spanish.
    public static let spanish = GherkinLanguage(code: "es", name: "Spanish", nativeName: "Español")

    /// Italian.
    public static let italian = GherkinLanguage(code: "it", name: "Italian", nativeName: "Italiano")

    /// Portuguese.
    public static let portuguese = GherkinLanguage(code: "pt", name: "Portuguese", nativeName: "Português")

    /// Japanese.
    public static let japanese = GherkinLanguage(code: "ja", name: "Japanese", nativeName: "日本語")

    /// Chinese (Simplified).
    public static let chinese = GherkinLanguage(code: "zh-CN", name: "Chinese (Simplified)", nativeName: "简体中文")

    /// Russian.
    public static let russian = GherkinLanguage(code: "ru", name: "Russian", nativeName: "Русский")

    /// Arabic.
    public static let arabic = GherkinLanguage(code: "ar", name: "Arabic", nativeName: "العربية")

    /// Korean.
    public static let korean = GherkinLanguage(code: "ko", name: "Korean", nativeName: "한국어")

    /// Dutch.
    public static let dutch = GherkinLanguage(code: "nl", name: "Dutch", nativeName: "Nederlands")

    /// Polish.
    public static let polish = GherkinLanguage(code: "pl", name: "Polish", nativeName: "Polski")

    /// Turkish.
    public static let turkish = GherkinLanguage(code: "tr", name: "Turkish", nativeName: "Türkçe")

    /// Swedish.
    public static let swedish = GherkinLanguage(code: "sv", name: "Swedish", nativeName: "Svenska")
}

extension GherkinLanguage: CustomStringConvertible {
    public var description: String { "\(name) (\(code))" }
}
