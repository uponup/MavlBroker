//
//  MavMessage.swift
//  Example
//
//  Created by 龙格 on 2020/9/9.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation
import CocoaMQTT

enum MBDomainConfig {
    static let awsLB = "msgapi.adpub.co"
    static let awsHost1 = "54.205.75.48"  //im1.adpub.co
    static let localHost = "192.168.1.186"
    
    static let port: UInt16 = 9883
}

public struct MavlMessageConfiguration {
    
    var appid: String
    var appkey: String
    var host: String = MBDomainConfig.awsHost1
    var port: UInt16 = MBDomainConfig.port
       
    init(appid id: String, appkey key: String) {
        appid = id
        appkey = key
    }
}

/**
    Message相关功能的协议
    TODO: 将方法归类成required和optional
 */
public protocol MavlMessageClient {
    func login(userName name: String, password pwd: String)
    func logout()
    
    func createAGroup(withUsers users: [String])
    func joinGroup(withGroupId gid: String)
    func quitGroup(withGroupId gid: String)
    
    func addFriend(withUserName: String)
    func sendToChatRoom(message: String, isToGroup: Bool, toId: String)
    
    func fetchMessages(msgId: String, from: String, type: FetchMessagesType, offset: Int)
}

/**
    Status相关功能的协议
 */
public protocol MavlMessageClientStatus {
    func checkStatus(withUserName username: String)
}

/**
    Config相关功能的协议
 */
public protocol MavlMessageClientConfig {
    func uploadToken()
}


/**
    SDK登录状态的回调
 */
public protocol MavlMessageDelegate: class {
    func beginLogin()
    func loginSuccess()
    func logout(withError: Error?)
}

/**
    SDK用户关系的回调
    1、群组管理，2、好友管理
 */
public protocol MavlMessageGroupDelegate: class {
    func createGroupSuccess(groupId gid: String, isLauncher: Bool)
    func joinedGroup(groupId gid: String, someone: String)
    func quitGroup(gid: String, error: Error?)
    
    
    func addFriendSuccess(friendName name: String)
    func friendStatus(_ status: String, friendId: String)
}

/**
    SDK消息状态的回调
    将要发送、发送成功、收到信息
 */
public protocol MavlMessageStatusDelegate: class {
    func mavl(willSend: Mesg)
    func mavl(didSend: Mesg, error: Error?)
    func mavl(didRevceived messages: [Mesg], isLoadMore: Bool)
}

extension MavlMessageStatusDelegate {
    func mavl(willSend: Mesg) {}
    func mavl(didSend: Mesg, error: Error?) {}
    func mavl(didRevceived messages: [Mesg], isLoadMore: Bool) {}
}

class MavlMessage {
    static let shared = MavlMessage()
    var passport: Passport? {
        return _passport
    }
    var appid: String {
        guard let config = config else { return "" }
        return config.appid
    }
    
    var isLogin: Bool {
        guard let value = _isLogin else {
            return false
        }
        return value
    }
    
    
    public weak var delegateLogin: MavlMessageDelegate?
    public weak var delegateMsg: MavlMessageStatusDelegate?
    public weak var delegateGroup: MavlMessageGroupDelegate?
    
    private var config: MavlMessageConfiguration?
    private var _passport: Passport?
    private var _isLogin: Bool?
    private var mqtt: CocoaMQTT?
    
    private var _localMsgId: UInt16 = 0
    private var _sendingMessages: [String: MavlTimer] = [:]
    
    func initializeSDK(config: MavlMessageConfiguration) {
        self.config = config
    }
    
    private func mqttSetting() {
        guard let config = config else {
            TRACE("请先初始化SDK，然后再登录")
            return
        }
        
        guard let passport = passport else {
            TRACE("请输入帐号密码")
            return
        }
        
        let clientId = "\(config.appid)_\(passport.uid)"
        let mqttUserName = "\(config.appid)_\(passport.uid)"
        let mqttPassword = "\(passport.pwd)_\(config.appkey)"
    
        mqtt = CocoaMQTT(clientID: clientId, host: config.host, port: config.port)
        guard let mqtt = mqtt else { return }
        mqtt.username = mqttUserName
        mqtt.password = mqttPassword
        mqtt.keepAlive = 60
        mqtt.delegate = self
        mqtt.enableSSL = true
        mqtt.autoReconnect = true
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
    
    func login(userName name: String, password pwd: String) {
        let passport = Passport(name, pwd)
        _passport = passport
        
        mqttSetting()
        
        guard let mqtt = mqtt else { return }
        
        delegateLogin?.beginLogin()
        _ = mqtt.connect()
    }
    
    func logout() {
        guard let mqtt = mqtt else { return }
            
        mqtt.disconnect()
    }
    
    func createAGroup(withUsers users: [String]) {
        let payload = users.map{ "\(appid)_\($0.lowercased())" }.joined(separator: ",")
        let operation = Operation.createGroup
        _send(msg: payload, operation: operation)
    }
    
    func joinGroup(withGroupId gid: String) {
        let operation = Operation.joinGroup(gid)
        _send(msg: "", operation: operation)
    }
 
    func quitGroup(withGroupId gid: String) {
        let operation = Operation.quitGroup(gid)
        _send(msg: "", operation: operation)
    }
    
    func addFriend(withUserName: String) {
        // TODO: 目前没有好友管理，只要输入userID就可以加为好友
        delegateGroup?.addFriendSuccess(friendName: withUserName)
    }
    
    func sendToChatRoom(message: String, isToGroup: Bool, toId: String) {
        let localId = nextMessageLocalID()
        var operation: Operation
        
        if isToGroup {
            operation = .oneToMany(localId ,toId)
        }else {
            let uid = "\(appid)_\(toId.lowercased())"
            operation = .oneToOne(localId, uid)
        }
        
        _send(msg: message, operation: operation)
    }
    
    func fetchMessages(msgId: String, from: String, type: FetchMessagesType, offset: Int = 20) {
        let operation = Operation.fetchMsgs(from, type, msgId, offset)
        _send(msg: "", operation: operation)
    }
    
    private func _send(msg: String, operation: Operation) {
        
        let message = CocoaMQTTMessage(topic: operation.topic, string: msg, qos: .qos0)
        mqtt?.publish(message)
        
        guard operation.localId != "0",
            let topicModel = SendingTopicModel(operation.topic),
            let passport = passport else { return }
        let sendingTimer = MavlTimer.after(3) { [unowned self] in
            var msg = Mesg(fromUid: passport.uid, toUid: topicModel.to, groupId: topicModel.gid, serverId: "", text: message.string.value, timestamp: Date().timeIntervalSince1970, status: 2)
            msg.localId = operation.localId
            self.delegateMsg?.mavl(didSend: msg, error: MavlMessageError.sendFailed)
        }
        _sendingMessages[operation.localId] = sendingTimer
    }
}

extension MavlMessage: MavlMessageClientStatus {
    func checkStatus(withUserName username: String) {
        let topic = "\(appid)/userstatus/\(appid)_\(username)/online"
        
        mqtt?.subscribe(topic)
    }
}

extension MavlMessage: MavlMessageClientConfig {
    func uploadToken() {
        guard let deviceToken = getDeviceToken() else {
            TRACE("上传token失败，无法获取token")
            return
        }
        
        let msgId = nextMessageLocalID()
        let topic = "\(appid)/300/\(msgId)/"
        
        mqtt?.publish(topic, withString: deviceToken)
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
            delegateLogin?.loginSuccess()
            
            _isLogin = true
            // 成功建立连接，上传token
            uploadToken()
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        TRACE("new state: \(state)")
        if state == .initial {
            TRACE("正常断开连接")
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        TRACE("message pub: \(message.string.value), id: \(id)")
        guard let topicModel = SendingTopicModel(message.topic) else { return }
        guard let passport = passport else { return }
        
        if topicModel.operation == 1 || topicModel.operation == 2 {
            var msg = Mesg(fromUid: passport.uid, toUid: topicModel.to, groupId: topicModel.gid, serverId: "", text: message.string.value, timestamp: Date().timeIntervalSince1970, status: 2)
            msg.localId = topicModel.localId
            delegateMsg?.mavl(willSend: msg)
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        TRACE("id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        TRACE("message receive: \(message.string.value), id: \(id)")
        
        let topic = message.topic
        
        if let topicModel = StatusTopicModel(topic) {
            delegateGroup?.friendStatus(message.string ?? "offline", friendId: topicModel.friendId)
        }else if let topicModel = TopicModel(message.topic) {
            if topicModel.operation == 0 {
                // create a group
                guard let passport = passport else { return }
                
                let isLauncher = passport.uid == topicModel.from
                delegateGroup?.createGroupSuccess(groupId: topicModel.to, isLauncher: isLauncher)
            }else if topicModel.operation == 201 {
                delegateGroup?.joinedGroup(groupId: topicModel.to, someone: topicModel.from)
            }else if topicModel.operation == 202 {
                delegateGroup?.quitGroup(gid: topicModel.to, error: nil)
            }else if topicModel.operation == 401 {
                let msgs = message.string.value.components(separatedBy: "##").compactMap{
                    Mesg(payload: $0)
                }
                delegateMsg?.mavl(didRevceived: msgs, isLoadMore: true)
            }else {
                var msg = Mesg(fromUid: topicModel.from, toUid: topicModel.to, groupId: topicModel.gid, serverId: topicModel.serverId, text: message.string.value, timestamp: Date().timeIntervalSince1970, status: 2)
                msg.localId = topicModel.localId
                delegateMsg?.mavl(didRevceived: [msg], isLoadMore: false)
                
                let sendingTimer = _sendingMessages[topicModel.localId]
                sendingTimer?.suspend()
                _sendingMessages.removeValue(forKey: topicModel.localId)
            }
        }else {
            TRACE("收到的信息Topic不符合规范：\(topic)")
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
        
        delegateLogin?.logout(withError: err)
        _isLogin = false
    }
}


fileprivate extension MavlMessage {
    func TRACE(_ message: String = "", fun: String = #function) {
        let names = fun.components(separatedBy: ":")
        var prettyName: String
        if names.count > 2 {
            prettyName = names[1]
        } else {
            prettyName = names[0]
        }
        
        if fun == "mqttDidDisconnect(_:withError:)" {
            prettyName = "didDisconnect"
        }

        print("[TRACE] [\(prettyName)]: \(message)")
    }
}

public enum MavlMessageError: Error, CustomStringConvertible {
    case sendFailed
    
    public var description: String {
        switch self {
        case .sendFailed:
            return "send failed"
        }
    }
}
