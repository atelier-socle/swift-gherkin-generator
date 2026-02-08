#if canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#elseif canImport(Darwin)
    import Darwin
#endif

/// Terminal color helpers for CLI output.
enum ANSIColor {

    /// Whether stdout is connected to a terminal (not piped).
    static let isTerminal: Bool = isatty(STDOUT_FILENO) != 0

    /// Wraps text in green ANSI escape codes.
    static func green(_ text: String) -> String {
        isTerminal ? "\u{001B}[32m\(text)\u{001B}[0m" : text
    }

    /// Wraps text in red ANSI escape codes.
    static func red(_ text: String) -> String {
        isTerminal ? "\u{001B}[31m\(text)\u{001B}[0m" : text
    }

    /// Wraps text in bold ANSI escape codes.
    static func bold(_ text: String) -> String {
        isTerminal ? "\u{001B}[1m\(text)\u{001B}[0m" : text
    }

    /// Wraps text in yellow ANSI escape codes.
    static func yellow(_ text: String) -> String {
        isTerminal ? "\u{001B}[33m\(text)\u{001B}[0m" : text
    }
}
