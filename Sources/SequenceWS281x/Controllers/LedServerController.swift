import Foundation
import rpi_ws281x_swift

import NIOCore
import NIOPosix
import NIOTransportServices

struct LEDInfo {
    let row: Int
    let col: Int
    let color: Color
}

class LedServerController: LedControllerProtocol {
    enum BindTo {
        case ip(host: String, port: Int)
        case unixDomainSocket(path: String)
    }

    let matrixHeight: Int
    let matrixWidth: Int
    let sequences: [SequenceType]
    let stop = false
    var timer: Timer?

    var buffer: [LEDInfo] = []

    let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    var serverChannel: Channel?
    
    let tcpHandler = TCPHandler()

    let ipEchoController: FindClientController = .init()

    init(sequences: [SequenceType], matrixWidth: Int, matrixHeight: Int) {
        self.matrixHeight = matrixHeight
        self.matrixWidth = matrixWidth
        self.sequences = sequences

        setup()
    }

    deinit {
        stopTCPServer()
    }

    func setup() {
        for var sequence in sequences {
            sequence.delegate = self
        }
    }

    func start() {
        DispatchQueue.global().async { [weak self] in
            do {
                try self?.ipEchoController.start(port: 3112)
            } catch {
                print("Failed to start UDP-server: \(error)")
            }
        }

        Task {
            await self.startTCPServer()
        }

        Task {
            while stop == false {
                runSequence()
            }
        }

        while stop == false {
            sendColor()
            sleep(forTimeInterval: 0.033)
        }
    }

    func runSequence() {
        for sequence in sequences {
            print("Run sequence: \(sequence.name)")
            sequence.runSequence()
        }
    }

    private func updatePixels() {
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

extension LedServerController: SequenceDelegate {
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

extension LedServerController {
    private func startTCPServer() async {
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)

            .childChannelInitializer { channel in
                channel.pipeline.addHandler(self.tcpHandler)
            }
            
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

        do {
            serverChannel = try await bootstrap.bind(host: "0.0.0.0", port: 2412).get()
            print("Server started and listening on \(serverChannel!.localAddress!)")

            try await serverChannel?.closeFuture.get()
        } catch {
            print("Failed to start TCP-server: \(error)")
        }

        print("Server closed")
        exit(0)
    }

    func stopTCPServer() {
        try? serverChannel?.close().wait()
        try? group.syncShutdownGracefully()
        print("Connection is cancelled")
    }

    func sendColor() {
        let data = self.buffer.filter({ $0.col == 4 })
//        self.buffer = []

        let buffer: [UInt8] = data.flatMap({
            return [UInt8($0.row), UInt8($0.col), $0.color.red, $0.color.green, $0.color.blue, $0.color.white]
        })

        tcpHandler.sendFrameToAll(buffer)
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

class TCPHandler: ChannelInboundHandler {
    enum Command: UInt8 {
        case timestamp = 128
        case frame = 129
        case title = 130
        case restart = 131
    }

    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private let channelsSyncQueue = DispatchQueue(label: "channelsQueue")
    private var channels: [ObjectIdentifier: Channel] = [:]

    var timestamp: TimeInterval {
        return Date().timeIntervalSince1970
    }

    public func channelActive(context: ChannelHandlerContext) {
        let channel = context.channel
        self.channelsSyncQueue.async {
            self.channels[ObjectIdentifier(channel)] = channel
        }
    }

    public func channelInactive(context: ChannelHandlerContext) {
        let channel = context.channel
        self.channelsSyncQueue.async {
            if self.channels.removeValue(forKey: ObjectIdentifier(channel)) != nil { }
        }
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = self.unwrapInboundIn(data)
        let message = String(buffer: buffer)

        print("Client is conneced: \(message)")

        let channel = context.channel
        context.eventLoop.scheduleRepeatedTask(initialDelay: .zero, delay: .milliseconds(30)) { task in
            if channel.isActive == false {
                task.cancel()
            }
        }

        sendTimestampToChannel(channel)
    }

    func sendFrameToAll(_ dataBuffer: [UInt8]) {
        let chunks = dataBuffer.chunked(into: 252)

        chunks.forEach { dataBuffer in
            let byte: [UInt8] = [Command.frame.rawValue, UInt8(dataBuffer.count)] + dataBuffer
            sendDataToAll(byte)
        }
    }

    func sendDataToAll(_ dataBuffer: [UInt8]) {
        var buffer = ByteBufferAllocator().buffer(capacity: dataBuffer.count)
        buffer.writeBytes(dataBuffer)

        channels.values.forEach { channel in
            channel.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
        }
    }

    func sendTimestampToChannel(_ channel: any Channel) {
        let bytes = timestamp.timeIntervalToBytes()
        let dataBuffer: [UInt8] = [Command.timestamp.rawValue, UInt8(bytes.count)] + bytes

        var buffer = ByteBufferAllocator().buffer(capacity: dataBuffer.count)
        buffer.writeBytes(dataBuffer)

        channel.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
    }
}

extension TimeInterval {
    func timeIntervalToBytes() -> [UInt8] {
        var timeInterval = self
        let size = MemoryLayout<TimeInterval>.size
        var byteArray = [UInt8](repeating: 0, count: size)

        withUnsafeBytes(of: &timeInterval) { buffer in
            for (index, byte) in buffer.enumerated() {
                byteArray[index] = byte
            }
        }

        return byteArray
    }
}
