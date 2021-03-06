import Foundation

/// The socket which encapsulates the logic to handle connection to proxies.
public class ProxySocket: NSObject, SocketProtocol, RawTCPSocketDelegate {
    /// Received `ConnectRequest`.
    public var request: ConnectRequest?

    public var observer: Observer<ProxySocketEvent>?

    /// If the socket is disconnected.
    public var isDisconnected: Bool {
        return state == .Closed || state == .Invalid
    }

    /**
     Init a `ProxySocket` with a raw TCP socket.

     - parameter socket: The raw TCP socket.
     */
    init(socket: RawTCPSocketProtocol) {
        self.socket = socket
        super.init()
        self.socket.delegate = self

        self.observer = ObserverFactory.currentFactory?.getObserverForProxySocket(self)
    }

    /**
     Begin reading and processing data from the socket.
     */
    func openSocket() {
        observer?.signal(.SocketOpened(self))
    }

    /**
     Response to the `ConnectResponse` from `AdapterSocket` on the other side of the `Tunnel`.

     - parameter response: The `ConnectResponse`.
     */
    func respondToResponse(response: ConnectResponse) {
        observer?.signal(.ReceivedResponse(response, on: self))
    }

    /**
     Read data from the socket.

     - parameter tag: The tag identifying the data in the callback delegate method.
     - warning: This should only be called after the last read is finished, i.e., `delegate?.didReadData()` is called.
     */
    public func readDataWithTag(tag: Int) {
        socket.readDataWithTag(tag)
    }

    /**
     Send data to remote.

     - parameter data: Data to send.
     - parameter tag:  The tag identifying the data in the callback delegate method.
     - warning: This should only be called after the last write is finished, i.e., `delegate?.didWriteData()` is called.
     */
    public func writeData(data: NSData, withTag tag: Int) {
        socket.writeData(data, withTag: tag)
    }

    //    func readDataToLength(length: Int, withTag tag: Int) {
    //        socket.readDataToLength(length, withTag: tag)
    //    }
    //
    //    func readDataToData(data: NSData, withTag tag: Int) {
    //        socket.readDataToData(data, withTag: tag)
    //    }

    /**
     Disconnect the socket elegantly.
     */
    public func disconnect() {
        state = .Disconnecting
        socket.disconnect()
        observer?.signal(.DisconnectCalled(self))
    }

    /**
     Disconnect the socket immediately.
     */
    public func forceDisconnect() {
        state = .Disconnecting
        socket.forceDisconnect()
        observer?.signal(.ForceDisconnectCalled(self))
    }


    // MARK: SocketProtocol Implemention

    /// The underlying TCP socket transmitting data.
    public var socket: RawTCPSocketProtocol!

    /// The delegate instance.
    weak public var delegate: SocketDelegate?

    /// Every delegate method should be called on this dispatch queue. And every method call and variable access will be called on this queue.
    public var queue: dispatch_queue_t! {
        didSet {
            socket.queue = queue
        }
    }

    /// The current connection status of the socket.
    public var state: SocketStatus = .Established


    // MARK: RawTCPSocketDelegate Protocol Implemention
    /**
     The socket did disconnect.

     - parameter socket: The socket which did disconnect.
     */
    public func didDisconnect(socket: RawTCPSocketProtocol) {
        state = .Closed
        observer?.signal(.Disconnected(self))
        delegate?.didDisconnect(self)
    }

    /**
     The socket did read some data.

     - parameter data:    The data read from the socket.
     - parameter withTag: The tag given when calling the `readData` method.
     - parameter from:    The socket where the data is read from.
     */
    public func didReadData(data: NSData, withTag tag: Int, from: RawTCPSocketProtocol) {
        observer?.signal(.ReadData(data, tag: tag, on: self))
    }

    /**
     The socket did send some data.

     - parameter data:    The data which have been sent to remote (acknowledged). Note this may not be available since the data may be released to save memory.
     - parameter withTag: The tag given when calling the `writeData` method.
     - parameter from:    The socket where the data is sent out.
     */
    public func didWriteData(data: NSData?, withTag tag: Int, from: RawTCPSocketProtocol) {
        observer?.signal(.WroteData(data, tag: tag, on: self))
    }

    /**
     The socket did connect to remote.

     - note: This never happens for `ProxySocket`.

     - parameter socket: The connected socket.
     */
    public func didConnect(socket: RawTCPSocketProtocol) {

    }


}
