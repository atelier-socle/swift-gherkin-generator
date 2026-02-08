# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x | Yes |

## Reporting a Vulnerability

If you discover a security vulnerability in GherkinGenerator, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, please report vulnerabilities through our contact page:

[Atelier Socle](https://www.atelier-socle.com/en/contact)

### What to Include

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgement:** within 48 hours
- **Initial assessment:** within 5 business days
- **Fix and release:** as soon as reasonably possible, depending on severity

### After Reporting

- We will acknowledge receipt of your report
- We will investigate and assess the impact
- We will work on a fix and coordinate disclosure
- We will credit you in the release notes (unless you prefer to remain anonymous)

## Scope

This policy applies to the GherkinGenerator Swift library (`Sources/GherkinGenerator/`). The library processes Gherkin feature files and related formats (CSV, JSON, plain text). Relevant concerns include:

- Input parsing vulnerabilities (malformed `.feature`, CSV, JSON, or plain text files)
- Path traversal in file import/export operations
- Denial of service through crafted inputs
