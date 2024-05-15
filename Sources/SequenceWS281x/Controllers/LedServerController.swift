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
        Task {
            try? ipEchoController.start(port: 3112)
        }

        Task {
            await self.startTCPServer()
        }

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
        let data = self.buffer
        self.buffer = []

        let buffer: [UInt8] = data.flatMap({
            return [UInt8($0.row), UInt8($0.col), $0.color.red, $0.color.green, $0.color.blue, $0.color.white]
        })

        let chunks = buffer.chunked(into: 1032)

        chunks.forEach { dataBuffer in
            tcpHandler.sendDataToAll(dataBuffer)
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

//extension UDPController: ChannelInboundHandler {
//    typealias InboundIn = AddressedEnvelope<ByteBuffer>
//    typealias OutboundOut = AddressedEnvelope<ByteBuffer>
//
//    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
//        let envelope = unwrapInboundIn(data)
//        let message = envelope.data.getString(at: 0, length: envelope.data.readableBytes) ?? "No text"
//        print("Message from client: \(message)")
//
//        var isGoUp = true
//        var count: UInt8 = 0
//        context.eventLoop.scheduleRepeatedTask(initialDelay: .zero, delay: .milliseconds(30)) { _ in
//            let dataBuffer: [UInt8] = [4, 4, 0, 0, count, 0]
//            var buffer = ByteBufferAllocator().buffer(capacity: dataBuffer.count)
//            buffer.writeBytes(dataBuffer)
//
//            let response = AddressedEnvelope(remoteAddress: envelope.remoteAddress, data: buffer)
//
//            context.writeAndFlush(self.wrapOutboundOut(response), promise: nil)
//
//            if count == 0 && isGoUp == false {
//                isGoUp = true
//            } else if count == 255 {
//                isGoUp = false
//            }
//
//            if isGoUp {
//                count += 1
//            } else {
//                count -= 1
//            }
//        }
//    }
//
//    public func channelReadComplete(context: ChannelHandlerContext) {
//        // As we are not really interested getting notified on success or failure we just pass nil as promise to
//        // reduce allocations.
//        context.flush()
//    }
//
//    public func errorCaught(context: ChannelHandlerContext, error: Error) {
//        print("error: ", error)
//
//        // As we are not really interested getting notified on success or failure we just pass nil as promise to
//        // reduce allocations.
//        context.close(promise: nil)
//    }
//}

class TCPHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private let channelsSyncQueue = DispatchQueue(label: "channelsQueue")
    private var channels: [ObjectIdentifier: Channel] = [:]

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
    }

    func sendDataToAll(_ dataBuffer: [UInt8]) {
        var buffer = ByteBufferAllocator().buffer(capacity: dataBuffer.count)
        buffer.writeBytes(dataBuffer)

        channels.values.forEach { channel in
            channel.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
        }
    }
}
