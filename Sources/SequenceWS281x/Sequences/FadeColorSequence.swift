//
//  FadeColorSequence.swift
//
//  Created by Christian Skaarup Enevoldsen on 08/01/2023.
//

import Foundation
import rpi_ws281x_swift

final class FadeColorSequence: SequenceType {
    var delegate: SequenceDelegate?
    let numberOfLeds: Int
    let matrixWidth: Int
    var color: Color = .black
    var goUp: Bool = true
    var ledInLive: Int = 0

    init(numberOfLeds: Int, matrixWidth: Int) {
        self.numberOfLeds = numberOfLeds
        self.matrixWidth = matrixWidth
    }

    func runSequence() {
        while true {
            switchColor()
        }
    }

    private func switchColor() {
        for i in 0..<numberOfLeds {
            if i.isMultiple(of: 2) {
                delegate?.sequenceSetPixelColor(self, pos: i, color: color)
            } else {
                delegate?.sequenceSetPixelColor(self, pos: i, color: .green)
            }
        }

        delegate?.sequenceUpdatePixels(self)
        Thread.sleep(forTimeInterval: 0.01)

        ledInLive = ledInLive + 1
        if ledInLive == numberOfLeds {
            ledInLive = 0
        }

        var colorInt: Int = Int(color.red)

        if goUp {
            colorInt = colorInt + 1
        } else {
            colorInt = colorInt - 1
        }

        if colorInt >= 255 {
            colorInt = 255
            goUp = false
        } else if colorInt <= 0 {
            colorInt = 0
            goUp = true
        }

        color.red = UInt8(colorInt)
    }
}
