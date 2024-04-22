//
//  UDPController.swift
//
//
//  Created by Christian Skaarup Enevoldsen on 18/04/2024.
//

import Foundation
import rpi_ws281x_swift
import Network

struct LEDInfo {
    let row: Int
    let col: Int
    let color: Color
}

class UDPController: LedControllerProtocol {
    let matrixHeight: Int
    let matrixWidth: Int
    let sequences: [SequenceType]
    let stop = false

    var buffer: [LEDInfo] = []

    var connection: NWConnection?
    var listener: NWListener?

    init(sequences: [SequenceType], matrixWidth: Int, matrixHeight: Int) {
        self.matrixHeight = matrixHeight
        self.matrixWidth = matrixWidth
        self.sequences = sequences

        setup()
    }

    deinit {
        stopUDPServer()
    }

    func setup() {
        for var sequence in sequences {
            sequence.delegate = self
        }
    }

    func start() {
        startUDPServer()

        while stop == false {
            runSequence()
        }
    }

    func runSequence() {
        for sequence in sequences {
            print("Run sequence: \(sequence.name)")
            sequence.runSequence()
        }
    }

    private func updatePixels() {
        self.sendColor()
        sleep()
    }

    private func setPixelColor(point: Point, color: Color) {
        guard point.x >= 0, point.y >= 0 else { return }

        let info = LEDInfo(row: point.x, col: point.y, color: color)
        buffer.append(info)
    }

    private func setPixelColor(pos: Int, color: Color) {
        let point = fromPostionToPoint(pos)
        setPixelColor(point: point, color: color)
    }
}

extension UDPController: SequenceDelegate {
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

extension UDPController {

    private func startUDPServer() {
        let port: NWEndpoint.Port = 2412

        let udpQueue = DispatchQueue(label: "udpQueue")
        guard let listener = try? NWListener(using: .udp, on: port) else { return }

        listener.newConnectionHandler = { [weak self] connection in
            connection.start(queue: udpQueue)

            connection.receiveMessage { data, _, _, _ in
                if let data = data, !data.isEmpty {
                    let message = String(decoding: data, as: UTF8.self)
                    print("Client have conncted: \(message)")
                }
            }

            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    print("Connection is ready to use")
                case .cancelled:
                    print("Connection cancelled")
                case .failed(let error):
                    print("Connection failed: \(error)")
                default:
                    break
                }
            }

            self?.connection = connection
        }

        listener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                print("The UDP server is started on port \(port)")
            case .failed(let error):
                print("Error starting the listener: \(error)")
            default:
                break
            }
        }
        listener.start(queue: .global())

        self.listener = listener
    }

    func stopUDPServer() {
        listener?.cancel()
        print("Connection is cancelled")
    }

    func sendColor() {
        guard let connection else { return }

        let data = self.buffer
        self.buffer = []

        let buffer: [UInt8] = data.flatMap({
            return [UInt8($0.row), UInt8($0.col), $0.color.red, $0.color.green, $0.color.blue, $0.color.white]
        })

        let chunks = buffer.chunked(into: 1032)

        chunks.forEach { buffer in
            connection.send(content: Data(buffer), completion: .contentProcessed { error in
                if let error = error {
                    print("Error sending response: \(error)")
                }
            })
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        var result = [[Element]]()
        for index in stride(from: 0, to: count, by: size) {
            let chunk = Array(self[index..<Swift.min(index + size, count)])
            result.append(chunk)
        }
        return result
    }
}
