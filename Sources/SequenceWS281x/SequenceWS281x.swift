import ArgumentParser
import Foundation

@main
struct SequenceWS281x: ParsableCommand {
    enum SequenceWS281xMode: String {
        case real
        case app
        case console
        case server

        static func mode(_ string: String?) -> SequenceWS281xMode {
            switch string {
            case SequenceWS281xMode.real.rawValue:
                return .real
            case SequenceWS281xMode.app.rawValue:
                return .app
            case SequenceWS281xMode.console.rawValue:
                return .console
            case SequenceWS281xMode.server.rawValue:
                return .server
            default:
                return .real
            }
        }
    }

    static var configuration = CommandConfiguration(
        commandName: "sequenceWS281x",
        abstract: "Run sequence for WS281x",
        version: "1.3",
        subcommands: []
    )

    @Option(help: "Executes mode: [real, app, console, server]")
    var mode: String = "real"

    @Option(help: "Matrix width")
    var matrixWidth: Int = 8

    @Option(help: "Matrix height")
    var matrixHeight: Int = 55

    func run() {
        print("\u{1B}[2J")
        print("\u{1B}[\(1);\(0)HLED will start:")

        let sequences: [SequenceType] = [
//            JSSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, jsFile: "rainbow.js"),
            TestColorSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight)//,
//            TwistSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight),
//            FireworksSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, colors: [.pink, .green, .blue, .red, .yallow, .trueWhite, .purple, .magenta, .orange]),
//
//            TwistSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight),
//            StarSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, color: .trueWhite),
//            MatrixSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, colors: [.green], numberOfmatrixs: 150),
//            MatrixSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, colors: [.green, .green, .red, .green, .green, .trueWhite, .yallow], numberOfmatrixs: 200),
//            MatrixSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, colors: [.red, .red, .red, .red, .trueWhite], numberOfmatrixs: 200),
//            RainbowCycleSequence(matrixWidth: matrixWidth, matrixHeight: matrixHeight, iterations: 5)
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
        case .server:
            controller = LedServerController(sequences: sequences, matrixWidth: matrixWidth, matrixHeight: matrixHeight)
        }

        controller.start()
    }
}
