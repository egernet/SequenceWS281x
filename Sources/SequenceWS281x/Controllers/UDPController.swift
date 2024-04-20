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

        var temp = [CChar](repeating: 0, count: 255)

        gethostname(&temp, temp.count)

        var port: UInt16 = 24120
        let hosts = ["localhost", String(cString: temp)]
        var hints = addrinfo()
        hints.ai_flags = 0
        hints.ai_family = PF_UNSPEC
        hints.ai_socktype = SOCK_DGRAM
        hints.ai_protocol = IPPROTO_UDP

        for host in hosts {

            print("\t\(host)")
            print()

            var info: UnsafeMutablePointer<addrinfo>?
            defer {
                if info != nil {
                    freeaddrinfo(info)
                }
            }

            let status: Int32 = getaddrinfo(host, String(port), nil, &info)
            guard status == 0 else {
                print(errno, String(cString: gai_strerror(errno)))
                return
            }

            var p = info
            var i = 0
            var ipFamily = ""

            while p != nil {

                i += 1

                var _info = p!.pointee
                p = _info.ai_next

                let serverSocket = socket(_info.ai_family, _info.ai_socktype, _info.ai_protocol)
                if serverSocket < 0 {
                    continue
                }

                switch _info.ai_family {
                case PF_INET:
                    _info.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { p in
                        p.pointee.sin_port = port.bigEndian
                    })
                case PF_INET6:
                    _info.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1, { p in
                        p.pointee.sin6_port = port.bigEndian
                    })
                default:
                    continue
                }

                if bind(serverSocket, _info.ai_addr, _info.ai_addrlen) < 0 {
                    close(serverSocket)
                    continue
                }

                if getsockname(serverSocket, _info.ai_addr, &_info.ai_addrlen) < 0 {
                    close(serverSocket)
                    continue
                }

                switch _info.ai_family {
                case PF_INET:
                    _info.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1, { p in
                        inet_ntop(AF_INET, &p.pointee.sin_addr, &temp, socklen_t(temp.count))
                        ipFamily = "IPv4"
                        port = p.pointee.sin_port.bigEndian
                    })
                case PF_INET6:
                    _info.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1, { p in
                        inet_ntop(AF_INET6, &p.pointee.sin6_addr, &temp, socklen_t(temp.count))
                        ipFamily = "IPv6"
                        port = p.pointee.sin6_port.bigEndian
                    })
                default:
                    break
                }

                if listen(serverSocket, 5) < 0 {} else {
                    close(serverSocket)
                    continue
                }

                print("\tsocket \(serverSocket)\t\(ipFamily)\t\(String(cString: temp))/\(port)")

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
        }
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
                sTest = nil
                self.paddr = nil
                lenTest = nil
                cancelSource()
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
