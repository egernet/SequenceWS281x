//
//  RainbowCycleSequence.swift
//  
//
//  Created by Christian Skaarup Enevoldsen on 08/01/2023.
//

import Foundation
import rpi_ws281x_swift

final class RainbowCycleSequence: SequenceType {
    var delegate: SequenceDelegate?
    let numberOfLeds: Int
    let matrixWidth: Int

    init(numberOfLeds: Int, matrixWidth: Int) {
        self.numberOfLeds = numberOfLeds
        self.matrixWidth = matrixWidth
    }

    func runSequence() {
        rainbowCycle(numberOfLeds: numberOfLeds, matrixWidth: matrixWidth)
    }

    private func rainbowCycle(numberOfLeds: Int, matrixWidth: Int, iterations: Int = 1) {
        let count = numberOfLeds / matrixWidth
        for i in 0..<255 * iterations {
            for y in 0..<matrixWidth {
                for x in 0..<count {
                    let index = ((x * 255 / count) + i) & 255
                    let color = wheel(index)
                    delegate?.sequenceSetPixelColor(self, point: .init(x: x, y: y), color: color)
                }
            }
            Thread.sleep(forTimeInterval: 0.01)
            delegate?.sequenceUpdatePixels(self)
        }
    }

    private func wheel(_ position: Int) -> Color {
        var position: UInt8 = UInt8(position)

        if (position < 85) {
            return .init(red: position * 3, green: 255 - position * 3, blue: 0)
        }
        else if (position < 170) {
            position -= 85
            return .init(red: 255 - position * 3, green: 0, blue: position * 3)
        }
        else {
            position -= 170
            return .init(red: 0, green: position * 3, blue: 255 - position * 3)
        }
    }
}
