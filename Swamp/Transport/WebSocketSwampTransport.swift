//
//  WebSocketTransport.swift
//  swamp
//
//  Created by Yossi Abraham on 18/08/2016.
//  Copyright © 2016 Yossi Abraham. All rights reserved.
//

import Foundation
import Starscream

open class WebSocketSwampTransport: SwampTransport, WebSocketDelegate {
    
    public enum WampProtocol : String {
        case json = "wamp.2.json"
        case msgpack = "wamp.2.msgpack"
        case jsonBatched = "wamp.2.json.batched"
        case msgpackBatched = "wamp.2.msgpack.batched"
    }

    enum WebsocketMode {
        case binary, text
    }

    open var delegate: SwampTransportDelegate?
    let socket: WebSocket
    let mode: WebsocketMode
    
    fileprivate var disconnectionReason: String?
    
    public init(wsEndpoint: URL, protocols: [WampProtocol]) {
        self.socket = WebSocket(url: wsEndpoint, protocols: protocols.map({$0.rawValue}) )
        self.mode = .text
        socket.delegate = self
    }

    convenience public init(wsEndpoint: URL){
        self.init(wsEndpoint: wsEndpoint, protocols: [.json])
    }
    
    // MARK: Transport
    open func connect() {
        self.socket.connect()
    }
    
    open func disconnect(_ reason: String) {
        self.disconnectionReason = reason
        self.socket.disconnect()
    }
    
    open func sendData(_ data: Data) {
        if self.mode == .text {
            self.socket.write(string: String(data: data, encoding: String.Encoding.utf8)!)
        } else {
            self.socket.write(data: data)
        }
    }
    
    // MARK: WebSocketDelegate
    
    open func websocketDidConnect(socket: WebSocket) {
        print(socket.headers)
        // TODO: Check which serializer is supported by the server, and choose self.mode and serializer
        delegate?.swampTransportDidConnectWithSerializer(JSONSwampSerializer())
    }
    
    open func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        delegate?.swampTransportDidDisconnect(error, reason: self.disconnectionReason)
    }
    
    open func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if let data = text.data(using: String.Encoding.utf8) {
            self.websocketDidReceiveData(socket: socket, data: data)
        }
    }
    
    open func websocketDidReceiveData(socket: WebSocket, data: Data) {
        delegate?.swampTransportReceivedData(data)
    }
}
