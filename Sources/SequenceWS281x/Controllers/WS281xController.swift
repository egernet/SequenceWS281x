//
//  WS281xController.swift
//
//  Created by Christian Skaarup Enevoldsen on 07/01/2023.
//

import Foundation
import rpi_ws281x_swift

class WS281xController: LedControllerProtocol {
    private let strip: PixelStrip
    let numberOfLeds: Int
    let matrixWidth: Int
    let sequences: [SequenceType]
    let stop = false

    init(sequences: [SequenceType], numberOfLeds: Int, matrixWidth: Int) {
        self.numberOfLeds = numberOfLeds
        self.matrixWidth = matrixWidth
        self.sequences = sequences
        
        let strip = PixelStrip(
            numLEDs: Int32(numberOfLeds),
            pin: 18,
            stripType: .WS2812B
        )

        self.strip = strip

        setup()
    }

    func setup() {
        for var sequence in sequences {
            sequence.delegate = self
        }
    }

    func start() {
        strip.begin()

        while stop == false {
            runSequence()
        }
    }

    func runSequence() {
        for sequence in sequences {
            sequence.runSequence()
        }
    }

    private func updatePixels() {
        strip.show()
    }

    private func setPixelColor(point: Point, color: Color) {
        let count = numberOfLeds / matrixWidth
        let postion = point.x + (count * point.y)
        strip.setPixelColor(pos: postion, color: color)
    }

    private func setPixelColor(pos: Int, color: Color) {
        let count = numberOfLeds / matrixWidth
        let y = pos / count
        let x = pos - (y * count)
        setPixelColor(point: .init(x: x, y: y), color: color)
    }
}

extension WS281xController: SequenceDelegate {
    func sequenceUpdatePixels(_ sequence: SequenceType) {
        updatePixels()
    }

    func sequenceSetPixelColor(_ sequence: SequenceType, point: Point, color: rpi_ws281x_swift.Color) {
        setPixelColor(point: point, color: color)
    }

    func sequenceSetPixelColor(_ sequence: SequenceType, pos: Int, color: rpi_ws281x_swift.Color) {
        setPixelColor(pos: pos, color: color)
    }
}
