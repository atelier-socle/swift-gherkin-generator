import ArgumentParser
import Foundation
import GherkinGenerator
import Testing

@testable import GherkinGenCLICore

@Suite("ConvertCommand")
struct ConvertCommandTests {

    @Test("Convert CSV to .feature")
    func convertCSV() async throws {
        let csv = """
            Scenario,Given,When,Then
            Login,a registered user,I log in,I see the dashboard
            Logout,a logged-in user,I log out,I see the login page
            """
        let fixture = try CLIFixtureDirectory(files: ["scenarios.csv": csv])
        let outputPath = NSTemporaryDirectory() + "convert-csv-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "convert", fixture.filePath("scenarios.csv"),
            "--title", "User Auth",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: User Auth"))
        #expect(content.contains("Login"))
        #expect(content.contains("a registered user"))
    }

    @Test("Convert JSON to .feature")
    func convertJSON() async throws {
        let parser = GherkinParser()
        let sourceFeature = """
            Feature: JSON Source
              Scenario: Test
                Given a step
                When an action
                Then a result
            """
        let feature = try parser.parse(sourceFeature)
        let exporter = GherkinExporter()
        let json = try exporter.render(feature, format: .json)

        let fixture = try CLIFixtureDirectory(files: ["source.json": json])
        let outputPath = NSTemporaryDirectory() + "convert-json-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "convert", fixture.filePath("source.json"),
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: JSON Source"))
        #expect(content.contains("Test"))
    }

    @Test("Convert TXT to .feature")
    func convertTXT() async throws {
        let txt = """
            Given a precondition
            When an action is taken
            Then a result is observed
            """
        let fixture = try CLIFixtureDirectory(files: ["steps.txt": txt])
        let outputPath = NSTemporaryDirectory() + "convert-txt-\(UUID().uuidString).feature"
        defer { try? FileManager.default.removeItem(atPath: outputPath) }

        let arguments = [
            "convert", fixture.filePath("steps.txt"),
            "--title", "Text Feature",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: Text Feature"))
    }

    @Test("Unsupported extension fails")
    func unsupportedExtension() async throws {
        let fixture = try CLIFixtureDirectory(files: ["data.xml": "<xml/>"])

        let arguments = [
            "convert", fixture.filePath("data.xml"),
            "--title", "Test"
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        await #expect(throws: (any Error).self) {
            try await execute(command)
        }
    }

    @Test("CSV without --title fails")
    func csvMissingTitle() async throws {
        let csv = "Scenario,Given,When,Then\nTest,a,b,c\n"
        let fixture = try CLIFixtureDirectory(files: ["no-title.csv": csv])

        let arguments = [
            "convert", fixture.filePath("no-title.csv")
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        await #expect(throws: (any Error).self) {
            try await execute(command)
        }
    }

    @Test("Convert XLSX to .feature")
    func convertXLSX() async throws {
        let xlsx = MinimalXLSXBuilder.build(rows: [
            ["Scenario", "Given", "When", "Then"],
            ["Login", "a registered user", "I log in", "I see the dashboard"]
        ])
        let tempDir = NSTemporaryDirectory()
        let xlsxPath = (tempDir as NSString).appendingPathComponent("convert-\(UUID()).xlsx")
        let outputPath = (tempDir as NSString).appendingPathComponent("convert-\(UUID()).feature")
        defer {
            try? FileManager.default.removeItem(atPath: xlsxPath)
            try? FileManager.default.removeItem(atPath: outputPath)
        }

        try xlsx.write(to: URL(fileURLWithPath: xlsxPath))

        let arguments = [
            "convert", xlsxPath,
            "--title", "User Auth",
            "--output", outputPath
        ]
        let command = try GherkinGen.parseAsRoot(arguments)
        try await execute(command)

        let content = try String(contentsOfFile: outputPath, encoding: .utf8)
        #expect(content.contains("Feature: User Auth"))
        #expect(content.contains("Login"))
        #expect(content.contains("a registered user"))
    }

    @Test("XLSX without --title fails")
    func xlsxMissingTitle() async throws {
        let xlsx = MinimalXLSXBuilder.build(rows: [
            ["Scenario", "Given", "When", "Then"],
            ["Test", "a", "b", "c"]
        ])
        let xlsxPath = NSTemporaryDirectory() + "no-title-\(UUID()).xlsx"
        defer { try? FileManager.default.removeItem(atPath: xlsxPath) }
        try xlsx.write(to: URL(fileURLWithPath: xlsxPath))

        let arguments = ["convert", xlsxPath]
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

/// Temporary directory helper for CLI tests.
private final class CLIFixtureDirectory: @unchecked Sendable {
    let path: String

    init(files: [String: String]) throws {
        let tempDir = NSTemporaryDirectory()
        let dirName = "cli-convert-\(UUID().uuidString)"
        let dirPath = (tempDir as NSString).appendingPathComponent(dirName)
        try FileManager.default.createDirectory(
            atPath: dirPath, withIntermediateDirectories: true
        )
        self.path = dirPath
        for (name, content) in files {
            let filePath = (dirPath as NSString).appendingPathComponent(name)
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
    }

    func filePath(_ name: String) -> String {
        (path as NSString).appendingPathComponent(name)
    }

    deinit {
        try? FileManager.default.removeItem(atPath: path)
    }
}

// MARK: - Minimal XLSX Builder (for CLI tests)

/// Builds minimal `.xlsx` archives with stored entries for CLI convert tests.
private enum MinimalXLSXBuilder {

    static func build(rows: [[String]]) -> Data {
        var strings: [String] = []
        var index: [String: Int] = [:]
        for row in rows {
            for cell in row where index[cell] == nil {
                index[cell] = strings.count
                strings.append(cell)
            }
        }

        let ss = sharedStringsXML(strings)
        let sheet = sheetXML(rows, index)
        let ct = contentTypesXML()
        let rels = relsXML()
        let wb = workbookXML()
        let wbRels = workbookRelsXML()

        return zip([
            ("[Content_Types].xml", ct), ("_rels/.rels", rels),
            ("xl/workbook.xml", wb), ("xl/_rels/workbook.xml.rels", wbRels),
            ("xl/worksheets/sheet1.xml", sheet), ("xl/sharedStrings.xml", ss)
        ])
    }

    private static func sharedStringsXML(_ strings: [String]) -> Data {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        xml += "<sst xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"
        for s in strings { xml += "<si><t>\(esc(s))</t></si>" }
        xml += "</sst>"
        return Data(xml.utf8)
    }

    private static func sheetXML(_ rows: [[String]], _ index: [String: Int]) -> Data {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        xml += "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"
        xml += "<sheetData>"
        for (r, row) in rows.enumerated() {
            xml += "<row r=\"\(r + 1)\">"
            for (c, cell) in row.enumerated() {
                let ref = colLetter(c) + "\(r + 1)"
                if let idx = index[cell] { xml += "<c r=\"\(ref)\" t=\"s\"><v>\(idx)</v></c>" }
            }
            xml += "</row>"
        }
        xml += "</sheetData></worksheet>"
        return Data(xml.utf8)
    }

    private static func contentTypesXML() -> Data {
        Data(
            ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                + "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
                + "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
                + "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
                + "</Types>").utf8)
    }

    private static func relsXML() -> Data {
        Data(
            ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                + "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
                + "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>"
                + "</Relationships>").utf8)
    }

    private static func workbookXML() -> Data {
        Data(
            ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                + "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"
                + "<sheets><sheet name=\"Sheet1\" sheetId=\"1\" r:id=\"rId1\"/></sheets>"
                + "</workbook>").utf8)
    }

    private static func workbookRelsXML() -> Data {
        Data(
            ("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                + "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
                + "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>"
                + "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings\" Target=\"sharedStrings.xml\"/>"
                + "</Relationships>").utf8)
    }

    private static func zip(_ entries: [(String, Data)]) -> Data {
        var archive = Data()
        var cd = Data()
        for (name, content) in entries {
            let offset = UInt32(archive.count)
            let nameData = Data(name.utf8)
            let crc = crc32(content)
            // Local header
            archive.append(contentsOf: le32(0x0403_4b50))
            archive.append(contentsOf: le16(20) + le16(0) + le16(0) + le16(0) + le16(0))
            archive.append(contentsOf: le32(crc) + le32(UInt32(content.count)))
            archive.append(contentsOf: le32(UInt32(content.count)))
            archive.append(contentsOf: le16(UInt16(nameData.count)) + le16(0))
            archive.append(nameData)
            archive.append(content)
            // Central directory
            cd.append(contentsOf: le32(0x0201_4b50))
            cd.append(contentsOf: le16(20) + le16(20) + le16(0) + le16(0))
            cd.append(contentsOf: le16(0) + le16(0))
            cd.append(contentsOf: le32(crc) + le32(UInt32(content.count)))
            cd.append(contentsOf: le32(UInt32(content.count)))
            cd.append(contentsOf: le16(UInt16(nameData.count)) + le16(0) + le16(0))
            cd.append(contentsOf: le16(0) + le16(0) + le32(0) + le32(offset))
            cd.append(nameData)
        }
        let cdOffset = UInt32(archive.count)
        archive.append(cd)
        archive.append(contentsOf: le32(0x0605_4b50))
        archive.append(contentsOf: le16(0) + le16(0))
        archive.append(contentsOf: le16(UInt16(entries.count)) + le16(UInt16(entries.count)))
        archive.append(contentsOf: le32(UInt32(cd.count)) + le32(cdOffset) + le16(0))
        return archive
    }

    private static func le16(_ v: UInt16) -> [UInt8] {
        [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF)]
    }

    private static func le32(_ v: UInt32) -> [UInt8] {
        [
            UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF),
            UInt8((v >> 16) & 0xFF), UInt8((v >> 24) & 0xFF)
        ]
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = (crc >> 1) ^ (crc & 1 == 1 ? 0xEDB8_8320 : 0) }
        }
        return ~crc
    }

    private static func colLetter(_ i: Int) -> String {
        var r = ""
        var n = i
        repeat {
            guard let scalar = UnicodeScalar(65 + n % 26) else { break }
            r = String(Character(scalar)) + r
            n = n / 26 - 1
        } while n >= 0
        return r
    }

    private static func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
