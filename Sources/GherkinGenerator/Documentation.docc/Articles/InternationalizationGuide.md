# Internationalization Guide

Write and parse Gherkin features in 70+ languages from the official specification.

## Overview

GherkinGenerator ships with the full `gherkin-languages.json` from the official Gherkin project. Every keyword — `Feature`, `Scenario`, `Given`, `When`, `Then`, and more — is available in 70+ languages. Language detection, localized formatting, and multi-language parsing all work out of the box.

## Available Languages

``GherkinLanguage`` provides named constants for the most common languages:

| Constant | Code | Native Name |
|----------|------|-------------|
| ``GherkinLanguage/english`` | `en` | English |
| ``GherkinLanguage/french`` | `fr` | français |
| ``GherkinLanguage/german`` | `de` | Deutsch |
| ``GherkinLanguage/spanish`` | `es` | español |
| ``GherkinLanguage/italian`` | `it` | italiano |
| ``GherkinLanguage/portuguese`` | `pt` | português |
| ``GherkinLanguage/japanese`` | `ja` | 日本語 |
| ``GherkinLanguage/chinese`` | `zh-CN` | 简体中文 |
| ``GherkinLanguage/russian`` | `ru` | русский |
| ``GherkinLanguage/arabic`` | `ar` | العربية |
| ``GherkinLanguage/korean`` | `ko` | 한국어 |
| ``GherkinLanguage/dutch`` | `nl` | Nederlands |
| ``GherkinLanguage/polish`` | `pl` | polski |
| ``GherkinLanguage/turkish`` | `tr` | Türkçe |
| ``GherkinLanguage/swedish`` | `sv` | Svenska |

For any other language, use the failable initializer with an ISO code:

```swift
let hindi = GherkinLanguage(code: "hi")
let catalan = GherkinLanguage(code: "ca")
```

List all registered languages:

```swift
for language in GherkinLanguage.all {
    print("\(language.code): \(language.name) — \(language.nativeName)")
}
```

## Build Features in Any Language

Pass a ``GherkinLanguage`` to the builder. The formatter automatically uses localized keywords:

```swift
let feature = try GherkinFeature(title: "Authentification", language: .french)
    .addScenario("Connexion réussie")
    .given("un compte valide")
    .when("l'utilisateur se connecte")
    .then("le tableau de bord est affiché")
    .build()

let output = GherkinFormatter().format(feature)
// # language: fr
// Fonctionnalité: Authentification
//
//   Scénario: Connexion réussie
//     Soit un compte valide
//     Quand l'utilisateur se connecte
//     Alors le tableau de bord est affiché
```

## Language Keywords

Each ``GherkinLanguage`` exposes its ``LanguageKeywords`` via the ``GherkinLanguage/keywords`` property. Keywords are arrays — some languages have multiple synonyms:

```swift
let keywords = GherkinLanguage.french.keywords
// keywords.given → ["Soit ", "Etant donné ", "Étant donné ", ...]
// keywords.when  → ["Quand ", "Lorsque ", "Lorsqu'"]
// keywords.then  → ["Alors "]
```

The first keyword in each array is the preferred one used for formatting output.

## Detect Language from Source

``GherkinParser`` automatically detects the language from a `# language:` header:

```swift
let parser = GherkinParser()
let language = parser.detectLanguage(in: """
    # language: de
    Funktionalität: Anmeldung
    """)
// language == .german
```

When no header is present, the parser defaults to English.

## Parse Localized Features

Parsing works transparently with any supported language. The parser reads the `# language:` header and switches keywords accordingly:

```swift
let parser = GherkinParser()
let feature = try parser.parse("""
    # language: ja
    フィーチャ: ログイン

      シナリオ: 正常ログイン
        前提 有効なアカウント
        もし ユーザーがログインする
        ならば ダッシュボードが表示される
    """)
```

## Localized Formatting

``GherkinFormatter`` reads the ``Feature/language`` property and uses the corresponding keywords automatically. No additional configuration is needed — just set the language when building:

```swift
let feature = try GherkinFeature(title: "Autenticación", language: .spanish)
    .addScenario("Inicio de sesión exitoso")
    .given("una cuenta válida")
    .when("el usuario inicia sesión")
    .then("se muestra el panel de control")
    .build()

let output = GherkinFormatter().format(feature)
// # language: es
// Característica: Autenticación
// ...
```

## Keyword Lookup

Use ``LanguageKeywords/keywords(for:)`` to retrieve keywords for any language code. It falls back to English for unknown codes:

```swift
let frKeywords = LanguageKeywords.keywords(for: "fr")
let unknownKeywords = LanguageKeywords.keywords(for: "xx")
// unknownKeywords == LanguageKeywords.english
```

List all registered language codes:

```swift
let codes = LanguageKeywords.registeredLanguages
// ["af", "am", "an", "ar", "ast", "az", "bg", "bm", "bs", "ca", ...]
```
