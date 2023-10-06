import Foundation

@main
public struct SequenceWS281x {
    public static func main() {
        print("\u{1B}[2J")
        print("\u{1B}[\(1);\(0)HLED will start:")

        let numberOfLeds = 55 * 3
        let matrixWidth = 3
        let sequences: [SequenceType] = [
            TestColorSequence(numberOfLeds: numberOfLeds, matrixWidth: matrixWidth),
            RainbowCycleSequence(numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
        ]

#if os(OSX)
        let controller: LedControllerProtocol = WindowController(sequences: sequences, numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
//        let controller: LedControllerProtocol = ConsoleController(sequences: sequences, numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
#else
        let controller: LedControllerProtocol = WS281xController(sequences: sequences, numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
#endif

        controller.start()
    }
}
