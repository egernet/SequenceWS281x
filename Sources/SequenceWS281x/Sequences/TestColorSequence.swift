//
//  TestColorSequence.swift
//  
//
//  Created by Christian Skaarup Enevoldsen on 08/01/2023.
//

import Foundation
import rpi_ws281x_swift

final class TestColorSequence: SequenceType {
    var delegate: SequenceDelegate?
    let numberOfLeds: Int
    let matrixWidth: Int
    let colors: [Color] = [.red, .green, .blue, .white, .black]

    init(numberOfLeds: Int, matrixWidth: Int) {
        self.numberOfLeds = numberOfLeds
        self.matrixWidth = matrixWidth
    }

    func runSequence() {
        switchColor()
    }

    private func switchColor() {
        for color in colors {
            for i in 0..<numberOfLeds {
                delegate?.sequenceSetPixelColor(self, pos: i, color: color)
            }

            delegate?.sequenceUpdatePixels(self)
            Thread.sleep(forTimeInterval: 1)
        }
    }

    private func staticColor() {
        for i in 0..<numberOfLeds {
            delegate?.sequenceSetPixelColor(self, pos: i, color: colors[i % 5])
        }

        delegate?.sequenceUpdatePixels(self)
        Thread.sleep(forTimeInterval: 1)
    }
}
