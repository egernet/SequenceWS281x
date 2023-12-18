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
    var matrixWidth: Int = 3

    @Option(help: "Matrix height")
    var matrixHeight: Int = 55

    func run() {
        print("\u{1B}[2J")
        print("\u{1B}[\(1);\(0)HLED will start:")

        let sequences: [SequenceType] = [
//            TestColorSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight),
            TwistSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight),
            StarSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, color: .white),
            TwistSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight),
            MatrixSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, colors: [.green], numberOfmatrixs: 150),
            TwistSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight),
            MatrixSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, colors: [.green, .green, .red, .green, .green, .white, .yallow], numberOfmatrixs: 200),
            TwistSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight),
            RainbowCycleSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, iterations: 5),
            TwistSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight),
            MatrixSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, colors: [.red, .red, .red, .red, .white], numberOfmatrixs: 200)
        ]

        let executesMode: SequenceWS281xMode = .mode(mode)

        let controller: LedControllerProtocol

        switch executesMode {
        case .real:
            controller = WS281xController(sequences: sequences, matrixWidth: matrixWidth, matrixHeight: matrixHeight)
        case .app:
            controller = WindowController(sequences: sequences, matrixWidth: matrixWidth, matrixHeight: matrixHeight)
        case .console:
            controller = ConsoleController(sequences: sequences, matrixWidth: matrixWidth, matrixHeight: matrixHeight)
        }

        controller.start()
    }
}
