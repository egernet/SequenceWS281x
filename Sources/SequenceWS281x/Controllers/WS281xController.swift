//
//  WS281xController.swift
//
//  Created by Christian Skaarup Enevoldsen on 07/01/2023.
//

import Foundation
import rpi_ws281x_swift

#if os(Linux)
    import Glibc
    import SwiftyGPIO
#endif

class WS281xController: LedControllerProtocol {
    private let strip: PixelStrip

#if os(Linux)
    private let gpios = SwiftyGPIO.GPIOs(for: .RaspberryPi4)
    private var addressGPIO: [GPIO] = []
#endif

    private var colors: [[Color]]

    let numberOfLeds: Int
    let matrixWidth: Int
    let sequences: [SequenceType]
    let stop = false

    init(sequences: [SequenceType], numberOfLeds: Int, matrixWidth: Int) {
        self.numberOfLeds = numberOfLeds
        self.matrixWidth = matrixWidth
        self.sequences = sequences

        let ledCount = numberOfLeds / matrixWidth
        let strip = PixelStrip(
            numLEDs: Int32(ledCount),
            pin: 18,
            stripType: .WS2812B
        )

        self.strip = strip

        var colors: [[Color]] = []
        for i in 0..<matrixWidth {
            var leds: [Color] = []
            for _ in 0..<ledCount {
                leds.append(.black)
            }
            colors.insert(leds, at: i)
        }

        self.colors = colors

        setup()
    }

    func setup() {
        setupGPIO()

        for var sequence in sequences {
            sequence.delegate = self
        }
    }

    private func setupGPIO() {
    #if os(Linux)
        let gp21 = gpios[.P21]!
        gp21.direction = .OUT
        gp21.value = 0
        addressGPIO.append(gp21)

        let gp20 = gpios[.P20]!
        gp20.direction = .OUT
        gp20.value = 0
        addressGPIO.append(gp20)

        let gp16 = gpios[.P16]!
        gp16.direction = .OUT
        gp16.value = 0
        addressGPIO.append(gp16)
    #endif
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
        for (channel, stripColors) in colors.enumerated() {
            setChannel(channel)
            for (index, color) in stripColors.enumerated() {
                strip.setPixelColor(pos: index, color: color)
            }
            strip.show()
            Thread.sleep(forTimeInterval: 0.001)
        }
    }

    private func setPixelColor(point: Point, color: Color) {
        colors[point.y][point.x] = color
    }

    private func setPixelColor(pos: Int, color: Color) {
        let count = numberOfLeds / matrixWidth
        let y = pos / count
        let x = pos - (y * count)
        setPixelColor(point: .init(x: x, y: y), color: color)
    }

    private func setChannel(_ channel: Int) {
    #if os(Linux)
        let number: UInt8 = UInt8(channel)
        addressGPIO[0].value = Int(number & 1) != 0 ? 1 : 0
        addressGPIO[1].value = Int(number & 1 << 1) != 0 ? 1 : 0
        addressGPIO[2].value = Int(number & 1 << 2) != 0 ? 1 : 0
    #endif
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
