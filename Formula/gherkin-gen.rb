# Homebrew formula for gherkin-gen
#
# Tap: atelier-socle/homebrew-tools
# Install: brew install atelier-socle/tools/gherkin-gen

class GherkinGen < Formula
  desc "CLI tool for composing, validating, and converting Gherkin .feature files"
  homepage "https://github.com/atelier-socle/swift-gherkin-generator"
  url "https://github.com/atelier-socle/swift-gherkin-generator/archive/refs/tags/0.1.0.tar.gz"
  sha256 "UPDATE_SHA256_AFTER_RELEASE"
  license "MIT"

  depends_on xcode: ["26.0", :build]

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/gherkin-gen"
  end

  test do
    system "#{bin}/gherkin-gen", "languages"
  end
end
