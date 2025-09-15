//
//  SPIBasedLedController.swift
//  SequenceWS281x
//
//  Created by Christian Skaarup Enevoldsen on 13/09/2025.
//

import Foundation
import SPI

final class SPIBasedLedController: LedControllerProtocol {
    let matrixWidth: Int
    let matrixHeight: Int
    let sequences: [SequenceType]

    private var buffer: [UInt8]
    private let spi: UnsafeMutablePointer<spi_t>
    private let spiPath: String
    private let baudRate: Int
    private let lock = NSLock()
    private var isRunning = false

    init(width: Int, height: Int, sequences: [SequenceType], spiPath: String = "/dev/spidev1.1", baudRate: Int = 2_500_000) {
        self.matrixWidth = width
        self.matrixHeight = height
        self.sequences = sequences
        self.spiPath = spiPath
        self.baudRate = baudRate
        self.buffer = [UInt8](repeating: 0, count: width * height * 4)
        self.spi = .allocate(capacity: 1)
    }

    func start() {
        let result = spi_init(spi, spiPath, 0, 0, baudRate)

        guard result == 0 else {
            print("❌ SPI init failed with error: \(result)")
            return
        }

        isRunning = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.spiLoop()
        }
    }

    func runSequence() {
        for sequence in sequences {
            sequence.delegate = self
            sequence.runSequence()
        }
    }

    private func setPixel(x: Int, y: Int, color: Color) {
        guard x < matrixWidth, y < matrixHeight else { return }
        let index = (y * matrixWidth + x) * 4

        lock.lock()
        buffer[index + 0] = color.green
        buffer[index + 1] = color.red
        buffer[index + 2] = color.blue
        buffer[index + 3] = color.white
        lock.unlock()
    }

    private func spiLoop() {
        while isRunning {
            lock.lock()
            let frame = buffer
            lock.unlock()

            frame.withUnsafeBytes { ptr in
                _ = spi_write(spi, ptr.baseAddress, Int32(frame.count))
            }

            Thread.sleep(forTimeInterval: 1.0 / 30.0) // 30 fps
        }
    }

    deinit {
        isRunning = false
        spi.deallocate()
    }
}

extension SPIBasedLedController: SequenceDelegate {
    func sequenceUpdatePixels(_ sequence: SequenceType) {}

    func sequenceSetPixelColor(_ sequence: SequenceType, point: Point, color: Color) {
        setPixel(x: point.x, y: point.y, color: color)
    }

    func sequenceSetPixelColor(_ sequence: SequenceType, pos: Int, color: Color) {
        let point = fromPostionToPoint(pos)
        setPixel(x: point.x, y: point.y, color: color)
    }
}
