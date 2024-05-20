import NIOCore
import NIOPosix

class FindClientController {
    let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    var bootstrap: DatagramBootstrap
    var channel: Channel?

    init() {
        self.bootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(UDPHandler())
            }
    }

    func start(port: Int) throws {
        self.channel = try bootstrap.bind(host: "0.0.0.0", port: port).wait()
        print("UDP-server started on port \(port)")
        try channel?.closeFuture.wait()
    }

    func stop() throws {
        try channel?.close().wait()
        try group.syncShutdownGracefully()
        print("UDP-server stopped")
    }
}

class UDPHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let addressedEnvelope = self.unwrapInboundIn(data)
        let buffer = addressedEnvelope.data
        let clientAddress = addressedEnvelope.remoteAddress

        if let message = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) {
            print("Client ask for IP: \(message) from \(clientAddress)")
        }

        let response = "Serverens IP: \(getIPAddress())"
        let responseBuffer = context.channel.allocator.buffer(string: response)
        let envelope = AddressedEnvelope(remoteAddress: clientAddress, data: responseBuffer)

        context.writeAndFlush(self.wrapOutboundOut(envelope), promise: nil)
    }

//    private func getIPAddress() -> String {
//        var ifaddr: UnsafeMutablePointer<ifaddrs>?
//        guard getifaddrs(&ifaddr) == 0 else { return "Kunne ikke hente IP-adresse" }
//        guard let firstAddr = ifaddr else { return "Kunne ikke hente IP-adresse" }
//
//        var ip: String?
//
//        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
//            let flags = Int32(ptr.pointee.ifa_flags)
//            if (flags & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING) {
//                if let sa = ptr.pointee.ifa_addr {
//                    switch sa.pointee.sa_family {
//                    case UInt8(AF_INET):
//                        var addr = sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
//                        var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
//                        inet_ntop(AF_INET, &addr.sin_addr, &buf, socklen_t(INET_ADDRSTRLEN))
//                        ip = String(cString: buf)
//                    case UInt8(AF_INET6):
//                        var addr = sa.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
//                        var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
//                        inet_ntop(AF_INET6, &addr.sin6_addr, &buf, socklen_t(INET6_ADDRSTRLEN))
//                        ip = String(cString: buf)
//                    default:
//                        continue
//                    }
//                }
//                if ip != nil {
//                    break
//                }
//            }
//        }
//        freeifaddrs(ifaddr)
//        return ip ?? "Kunne ikke finde IP-adresse"
//    }

    private func getIPAddress() -> String {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return "Kunne ikke hente IP-adresse" }
        guard let firstAddr = ifaddr else { return "Kunne ikke hente IP-adresse" }

        var ip: String?

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let a = Int32(IFF_UP | IFF_RUNNING | IFF_LOOPBACK)
            let b = Int32(IFF_UP | IFF_RUNNING)
            if (flags & a) == b {
                if let sa = ptr.pointee.ifa_addr {
                    switch UInt8(sa.pointee.sa_family) {
                    case UInt8(AF_INET):
                        var addr = sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                        var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                        inet_ntop(AF_INET, &addr.sin_addr, &buf, socklen_t(INET_ADDRSTRLEN))
                        ip = String(cString: buf)
                    default:
                        continue
                    }
                }
                if ip != nil {
                    break
                }
            }
        }
        freeifaddrs(ifaddr)
        return ip ?? "Kunne ikke finde IPv4-adresse"
    }
}
