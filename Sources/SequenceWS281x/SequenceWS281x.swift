import ArgumentParser
import Foundation

@main
struct SequenceWS281x: ParsableCommand {
    enum SequenceWS281xMode: String {
        case real
        case app
        case console

        static func mode(_ string: String?) -> SequenceWS281xMode {
            switch string {
            case SequenceWS281xMode.real.rawValue:
                return .real
            case SequenceWS281xMode.app.rawValue:
                return .app
            case SequenceWS281xMode.console.rawValue:
                return .console
            default:
                return .real
            }
        }
    }

    static var configuration = CommandConfiguration(
        commandName: "sequenceWS281x",
        abstract: "Run sequence for WS281x",
        version: "1.0",
        subcommands: []
    )

    @Option(help: "Executes mode: [real, app, console]")
    var mode: String = "real"

    @Option(help: "Matrix width")
    var matrixWidth: Int = 1

    @Option(help: "Number of leds")
    var numberOfLeds: Int = 20

    func run() {
        print("\u{1B}[2J")
        print("\u{1B}[\(1);\(0)HLED will start:")

        let sequences: [SequenceType] = [
            TestColorSequence(numberOfLeds: numberOfLeds, matrixWidth: matrixWidth),
            RainbowCycleSequence(numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
        ]

        let executesMode: SequenceWS281xMode = .mode(mode)

        let controller: LedControllerProtocol

        switch executesMode {
        case .real:
            controller = WS281xController(sequences: sequences, numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
        case .app:
            controller = WindowController(sequences: sequences, numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
        case .console:
            controller = ConsoleController(sequences: sequences, numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
        }

        controller.start()
    }
}
