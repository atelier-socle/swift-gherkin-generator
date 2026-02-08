import GherkinGenCLICore

@main
enum CLI {
    static func main() async {
        await GherkinGen.main()
    }
}
