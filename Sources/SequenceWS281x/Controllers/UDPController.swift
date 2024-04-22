//
//  UDPController.swift
//
//
//  Created by Christian Skaarup Enevoldsen on 18/04/2024.
//

import Foundation
import rpi_ws281x_swift

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

    var serverSources: [Int32: DispatchSourceRead] = [:]
    
    var lenTest: socklen_t?
    var paddr: UnsafeMutablePointer<sockaddr>?
    var sTest: Int32?

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
        let port: UInt16 = 24120

#if os(Linux)
        let serverSocket = CInt(socket(AF_INET, Int32(SOCK_DGRAM.rawValue), 0))
#else
        let serverSocket = CInt(socket(AF_INET, Int32(SOCK_DGRAM), 0))
#endif

        guard serverSocket != -1 else {
            perror("Could not create socket")
            exit(EXIT_FAILURE)
        }

        var serverAddress = sockaddr_in()
        serverAddress.sin_family = sa_family_t(AF_INET)
        serverAddress.sin_addr.s_addr = inet_addr("0.0.0.0") // Listen on all network interfaces
        serverAddress.sin_port = port.bigEndian

        let bindResult = withUnsafePointer(to: &serverAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addressPointer in
                bind(serverSocket, addressPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult != -1 else {
            perror("Could not bind socket to address and port")
            exit(EXIT_FAILURE)
        }

        print("UDP-serveren is started on port \(port)")

        let serverSource = DispatchSource.makeReadSource(fileDescriptor: serverSocket)
        serverSource.setEventHandler {

            var info = sockaddr_storage()
            var len = socklen_t(MemoryLayout<sockaddr_storage>.size)

            let s = Int32(serverSource.handle)
            var buffer = [UInt8](repeating: 0, count: 1024)

            withUnsafeMutablePointer(to: &info, { pinfo -> () in
                let paddr = UnsafeMutableRawPointer(pinfo).assumingMemoryBound(to: sockaddr.self)
                let received = recvfrom(s, &buffer, buffer.count, 0, paddr, &len)

                if received < 0 {
                    return
                }

                let text: String = String(cString: buffer)
                print("Client have conncted: \(text)")

                self.sTest = s
                self.lenTest = len
                self.paddr = paddr

//                        var totalSended = 0
//                        repeat {
//
//                            let sended = sendto(s, &buffer, received - totalSended, 0, paddr, len)
//                            if sended < 0 {
//                                return
//                            }
//                            totalSended += sended
//                        } while totalSended < received
            })
        }

        serverSources[serverSocket] = serverSource
        serverSource.resume()
    }

    func stopUDPServer() {
        for (socket, source) in serverSources {
            source.cancel()
            close(socket)
            print(socket, "\tclosed")
        }
        serverSources.removeAll()
    }

    func cancelSource() {
        guard let s = sTest else { return }
        let serverSource = serverSources.first(where: { $0.key == s })?.value
        serverSource?.cancel()
    }

    func sendColor() {
        guard let s = sTest, let paddr, let len = lenTest else { return }

        let data = self.buffer
        self.buffer = []

        let buffer: [UInt8] = data.flatMap({
            return [UInt8($0.row), UInt8($0.col), $0.color.red, $0.color.green, $0.color.blue, $0.color.white]
        })

        let chunks = buffer.chunked(into: 1032)

        chunks.forEach { buffer in
            let bytesSent = sendto(s, buffer, buffer.count, 0, paddr, len)
            if bytesSent == -1 {
                cancelSource()
                sTest = nil
                self.paddr = nil
                lenTest = nil
            }
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
