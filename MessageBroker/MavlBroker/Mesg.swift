//
//  Mesg.swift
//  Example
//
//  Created by 龙格 on 2020/9/19.
//  Copyright © 2020 emqtt.io. All rights reserved.
//

import Foundation

protocol MesgProtocol {
    var text: String { get set }
    var localId: UInt16 { get set }
    var serverId: String? { get set }
    var receiverId: String? { get set }
    var operation: Int { get }
    
    var sufixTopic: String { get }
    
    init(text: String, localId: UInt16, to receiver:String, operation: Int)
}

extension MesgProtocol {
    var sufixTopic: String {
        let tempTopic = "/\(operation)/\(localId)"
        if operation == 0 {
            return tempTopic
        }else {
            return "\(tempTopic)/\(receiverId.value)"
        }
    }
}

protocol MQTTMesgProtocol {
    var qos: Int { get }
    var retained: Bool { get }
}

struct Mesg_1v1: MesgProtocol, MQTTMesgProtocol {
    
    var text: String
    var localId: UInt16
    var serverId: String?
    var receiverId: String?
    
    var operation: Int = 1
    var qos: Int = 1
    var retained: Bool = true
    
    init(text: String = "", localId: UInt16 = 0, to receiver:String, operation: Int = 1) {
        self.text = text
        self.localId = localId
        self.receiverId = receiver
        self.operation = operation
    }
}

public struct Mesg_1vN: MesgProtocol, MQTTMesgProtocol {
    
    var text: String
    var localId: UInt16
    var serverId: String?
    var receiverId: String?
    
    var operation: Int = 2
    var qos: Int = 1
    var retained: Bool = true
    
    init(text: String = "", localId: UInt16 = 0, to receiver: String = "", operation: Int = 2) {
        self.text = text
        self.localId = localId
        self.receiverId = receiver
        self.operation = operation
    }
}

// MARK: OptionalExtension--String
extension Optional where Wrapped == String {
    public var value: String {
        switch self {
        case .none:
            return ""
        case .some(let v):
            return v;
        }
    }
}
