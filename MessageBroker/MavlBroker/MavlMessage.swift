//
//  MavMessage.swift
//  Example
//
//  Created by 龙格 on 2020/9/9.
//  Copyright © 2020 emqtt.io. All rights reserved.
//

import Foundation
import CocoaMQTT

enum MBDomainConfig {
    static let awsLB = "msgapi.adpub.co"
    static let awsHost1 = "54.205.75.48"  //im1.adpub.co
    static let localHost = "192.168.1.186"
    
    static let port: UInt16 = 9883
}

struct MavlMessageConfiguration {
    
    var appid: String
    private var appkey: String
    private var mUUID: String
    private var mToken: String
    var host: String = MBDomainConfig.awsHost1
    var port: UInt16 = MBDomainConfig.port
       
    var username: String {
        "\(appid)_\(mUUID)"
    }
    var clientID: String {
        "\(appid)_\(mUUID)"
    }
    var password: String {
        "\(mToken)_\(appkey)"
    }
    
    init(appid id: String, appkey key: String, uuid mUUID: String, token mToken: String) {
        appid = id
        appkey = key
        self.mUUID = mUUID
        self.mToken = mToken
    }
}

public protocol MavlMessageClient {
    func login()
    func createAGroup(withUsers users: [String])
    func addFriend(withUserName: String)
    func sendToChatRoom(message: String, isToGroup: Bool, toId: String)
    func logout()
}

protocol MavlMessageDelegate: class {
    func beginLogin()
    func loginSuccess()
    func joinedChatRoom(groupId gid: String)
    func addFriendSuccess(friendName name: String)
    func sendMessageSuccess()
    func mavlDidReceived(message msg: String?, topic t: String)
    func logoutSuccess()
}

extension MavlMessageClient {
    func addFriendSuccess(friendName name: String) {}
}

class MavlMessage {
    
    public weak var delegate: MavlMessageDelegate?
    
    private var config: MavlMessageConfiguration
    private var mqtt: CocoaMQTT?
    private var gid: String?
    
    private var _localMsgId: UInt16 = 0
    
    init(config: MavlMessageConfiguration) {
        self.config = config
        
        mqttSetting()
    }
    
    private func mqttSetting() {
        mqtt = CocoaMQTT(clientID: config.clientID, host: config.host, port: config.port)
        
        guard let mqtt = mqtt else { return }
        mqtt.username = config.username
        mqtt.password = config.password
        mqtt.keepAlive = 6000
        mqtt.delegate = self
        mqtt.enableSSL = true
        mqtt.allowUntrustCACertificate = true
    }
    
    fileprivate func nextMessageLocalID() -> UInt16 {
        if _localMsgId == UInt16.max {
            _localMsgId = 0
        }
        _localMsgId += 1
        return _localMsgId
    }
}

extension MavlMessage: MavlMessageClient {
    
    func createAGroup(withUsers users: [String]) {
        let payload = users.map{ "\(config.appid)_\($0.lowercased())" }.joined(separator: ",")
        
        createGroup(mesg: payload)
    }
    
    func addFriend(withUserName: String) {
        delegate?.addFriendSuccess(friendName: withUserName)
    }
    
    func sendToChatRoom(message: String, isToGroup: Bool, toId: String) {
        if isToGroup {
            sendToGroup(msg: message, to: toId)
        }else {
            send(msg: message, to: toId)
        }
    }
    
    func login() {
        guard let mqtt = mqtt else { return }
        
        self.delegate?.beginLogin()
        _ = mqtt.connect()
    }
    
    func logout() {
        guard let mqtt = mqtt else { return }
            
        mqtt.disconnect()
    }
    
    // 1v1
    private func send(msg: String, to someone: String) {
        let localId = nextMessageLocalID()
        let msg_1v1 = Mesg_1v1(text: msg, localId: localId, to: someone)
        _send(msg: msg_1v1)
    }
    
    private func sendToGroup(msg: String, to group: String) {
        let localId = nextMessageLocalID()
        let msg_1vN = Mesg_1vN(text: msg, localId: localId, to: group)
        _send(msg: msg_1vN)
    }
    
    private func createGroup(mesg: String) {
        let localId = nextMessageLocalID()
        let msg_1vN = Mesg_1vN(text: mesg, localId: localId, operation: 0)
        _send(msg: msg_1vN)
    }
    
    private func _send(msg: MesgProtocol & MQTTMesgProtocol) {
        let topic = "\(config.appid)\(msg.sufixTopic)"
        
        // 改版思路：直接扩展CocoaMQTTMessage，而不需要自己构建Mesg_1vN消息模型
        mqtt?.publish(topic, withString: msg.text, qos: CocoaMQTTQOS(rawValue: UInt8(msg.qos))!, retained: msg.retained)
    }
}

extension MavlMessage: CocoaMQTTDelegate {

    // Optional ssl CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
       TRACE("trust: \(trust)")
       /// Validate the server certificate
       ///
       /// Some custom validation...
       ///
       /// if validatePassed {
       ///     completionHandler(true)
       /// } else {
       ///     completionHandler(false)
       /// }
       completionHandler(true)
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
       TRACE("ack: \(ack)")
       
        if ack == .accept {
            delegate?.loginSuccess()
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
       TRACE("new state: \(state)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message pub: \(message.string.value), id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
       TRACE("id: \(id)")
        delegate?.sendMessageSuccess()
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        TRACE("message receive: \(message.string.value), id: \(id)")
        let topic = message.topic
        let c = topic.components(separatedBy: "/")
        if c.count > 3, c[1] == "0" {
            self.gid = c[3];
            
            delegate?.joinedChatRoom(groupId: self.gid!)
        }else {
            delegate?.mavlDidReceived(message: message.string, topic: topic)
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topics: [String]) {
        TRACE("subscribed: \(topics)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        TRACE("topic: \(topic)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
       TRACE()
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
       TRACE()
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        TRACE("\(err?.localizedDescription ?? "")")
        delegate?.logoutSuccess()
    }
}


fileprivate extension MavlMessage {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count == 2 {
            prettyName = names[0]
        } else {
            prettyName = names[1]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}
