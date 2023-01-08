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

        let controller: WS281xController = .init(sequences: sequences, numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
        controller.start()

        while(true) {
            controller.runSequence()
        }
    }
}
