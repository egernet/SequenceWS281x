//
//  File.swift
//  
//
//  Created by Christian Skaarup Enevoldsen on 07/01/2023.
//

import Foundation
import rpi_ws281x_swift

class WS281xController {
    private let strip: PixelStrip?
    let numberOfLeds: Int
    let matrixWidth: Int
    let sequences: [SequenceType]

    init(sequences: [SequenceType], numberOfLeds: Int, matrixWidth: Int) {
        self.numberOfLeds = numberOfLeds
        self.matrixWidth = matrixWidth
        self.sequences = sequences
        
        #if os(OSX)
        self.strip = nil
        #else
        let strip = PixelStrip(numLEDs: Int32(numberOfLeds),
                               pin: 18,
                               stripType: .WS2812B,
                               brightness: 40)

        self.strip = strip
        #endif

        setup()
    }

    func setup() {
        for var sequence in sequences {
            sequence.delegate = self
        }
    }

    func start() {
        strip?.begin()
    }

    func runSequence() {
        for sequence in sequences {
            sequence.runSequence()
        }
    }

    private func updatePixels() {
        if let strip = strip {
            strip.show()
        } else {
            let point = Point(x: 0, y: 1)
            Console.moveCursor(point)
        }
    }

    private func setPixelColor(point: Point, color: Color) {
        if let strip = strip {
            let count = numberOfLeds / matrixWidth
            let postion = point.x + (count * point.y)
            strip.setPixelColor(pos: postion, color: color)
        } else {
            if point.x == 0 && point.y > 0 {
                Console.writeLine("")
            }
            Console.write("● ", color: color)
        }
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
