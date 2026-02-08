# Makefile — GherkinGenerator
#
# Targets for building, testing, linting, formatting, and installing
# the gherkin-gen CLI tool.

# ---------- Variables ----------

PREFIX       ?= /usr/local/bin
BINARY_NAME   = gherkin-gen
BUILD_DIR     = .build/release

# ---------- Phony targets ----------

.PHONY: build build-release test lint format format-check \
        install uninstall clean coverage all help

# ---------- Build ----------

## Build the project (debug)
build:
	swift build

## Build the project (release, optimised)
build-release:
	swift build -c release

# ---------- Quality ----------

## Run tests
test:
	swift test

## Lint sources with SwiftLint
lint:
	swiftlint lint --quiet

## Format sources in-place with swift-format
format:
	swift-format format -r -i Sources/ Tests/

## Check formatting without modifying files
format-check:
	swift-format lint -r Sources/ Tests/

# ---------- Coverage ----------

## Run tests with code coverage and display a summary report
coverage:
	swift test --enable-code-coverage
	@PROF_DATA=$$(find .build -name "default.profdata" -type f | head -1); \
	TEST_BIN=$$(find .build/debug -name "GherkinGeneratorPackageTests" -type f ! -name "*.o" | head -1); \
	if [ -n "$$PROF_DATA" ] && [ -n "$$TEST_BIN" ]; then \
		xcrun llvm-cov report "$$TEST_BIN" \
			-instr-profile="$$PROF_DATA" \
			-ignore-filename-regex='\.build|Tests'; \
	else \
		echo "Coverage data not found."; \
	fi

# ---------- Install / Uninstall ----------

## Build release and install the binary to PREFIX (/usr/local/bin)
install: build-release
	@mkdir -p $(PREFIX)
	install -m 755 $(BUILD_DIR)/$(BINARY_NAME) $(PREFIX)/$(BINARY_NAME)
	@echo "$(BINARY_NAME) installed to $(PREFIX)/$(BINARY_NAME)"

## Remove the binary from PREFIX
uninstall:
	rm -f $(PREFIX)/$(BINARY_NAME)
	@echo "$(BINARY_NAME) removed from $(PREFIX)/$(BINARY_NAME)"

# ---------- Clean ----------

## Remove all build artifacts
clean:
	swift package clean

# ---------- Aggregate ----------

## Run the full quality pipeline: lint + format-check + build + test
all: lint format-check build test

# ---------- Help ----------

## Display available targets
help:
	@echo "GherkinGenerator — Makefile targets"
	@echo ""
	@echo "  build          Build the project (debug)"
	@echo "  build-release  Build the project (release)"
	@echo "  test           Run tests"
	@echo "  lint           Lint sources with SwiftLint"
	@echo "  format         Format sources in-place"
	@echo "  format-check   Check formatting (no changes)"
	@echo "  coverage       Run tests with code coverage report"
	@echo "  install        Build release + install to PREFIX (default: /usr/local/bin)"
	@echo "  uninstall      Remove the binary from PREFIX"
	@echo "  clean          Remove all build artifacts"
	@echo "  all            lint + format-check + build + test"
	@echo "  help           Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  PREFIX=$(PREFIX)"
