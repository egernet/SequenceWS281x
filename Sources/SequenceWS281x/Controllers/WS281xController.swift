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

    var matrixHeight: Int
    let matrixWidth: Int
    let sequences: [SequenceType]
    let stop = false

    init(sequences: [SequenceType], matrixWidth: Int, matrixHeight: Int) {
        self.matrixHeight = matrixHeight
        self.matrixWidth = matrixWidth
        self.sequences = sequences

        let strip = PixelStrip(
            numLEDs: Int32(matrixHeight),
            pin: 18,
            stripType: .WS2812B
        )

        self.strip = strip

        var colors: [[Color]] = []
        for i in 0..<matrixWidth {
            var leds: [Color] = []
            for _ in 0..<matrixHeight {
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
            sleep()
        }
    }

    private func setPixelColor(point: Point, color: Color) {
        guard point.y >= 0 && point.x >= 0 else {
            return
        }
        guard point.y < matrixWidth && point.x < matrixHeight else {
            return
        }
        colors[point.y][point.x] = color
    }

    private func setPixelColor(pos: Int, color: Color) {
        let point = fromPostionToPoint(pos)
        setPixelColor(point: point, color: color)
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

extension WS281xController {
    private func setChannel(_ channel: Int) {
    #if os(Linux)
        let number: UInt8 = UInt8(channel + 1) // Channel 0 is defect
        for i in 0..<3 {
            addressGPIO[i].value = Int(number >> i) & 1
        }
    #endif
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
}
