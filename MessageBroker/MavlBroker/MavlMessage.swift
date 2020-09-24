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
    
    func fetchMessages(msgId: String, from: String, type: String, offset: Int)
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


protocol MavlMessageDelegate: class {
    func beginLogin()
    func loginSuccess()
    func joinedChatRoom(groupId gid: String)
    func quitGroup(gid: String, error: Error?)
    func addFriendSuccess(friendName name: String)
    func sendMessageSuccess()
    func mavlDidReceived(message msg: Mesg)
    func mavlDidReceived(messages msgs: [Mesg])
    func logout(withError: Error?)
    func friendStatus(_ status: String?, friendId: String)
}

extension MavlMessageDelegate {
    func friendStatus(_ status: String?, friendId: String) {}
    func quitGroup(gid: String, error: Error? = nil) { }
}

struct MavlPassport {
    var uid: String
    var password: String
}

class MavlMessage {
    static let shared = MavlMessage()
    var passport: Passport? {
        return _passport
    }
    private var appid: String {
        guard let config = config else { return "" }
        return config.appid
    }
    
    public weak var delegate: MavlMessageDelegate?
    
    private var config: MavlMessageConfiguration?
    private var _passport: Passport?
    private var mqtt: CocoaMQTT?
    
    private var _localMsgId: UInt16 = 0
    
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
        
        self.delegate?.beginLogin()
        _ = mqtt.connect()
    }
    
    func createAGroup(withUsers users: [String]) {
        let payload = users.map{ "\(appid)_\($0.lowercased())" }.joined(separator: ",")
        
        createGroup(mesg: payload)
    }
    
    func joinGroup(withGroupId gid: String) {
        let localId = nextMessageLocalID()
        let topic = "\(appid)/201/\(localId)/\(gid)"
        mqtt?.publish(topic, withString: "")
    }
 
    func quitGroup(withGroupId gid: String) {
        let localId = nextMessageLocalID()
        let topic = "\(appid)/202/\(localId)/\(gid)"
        mqtt?.publish(topic, withString: "")
    }
    
    func addFriend(withUserName: String) {
        // TODO: 目前没有好友管理，addFriend其实是直接向对方发起1v1的聊天
        delegate?.addFriendSuccess(friendName: withUserName)
    }
    
    func sendToChatRoom(message: String, isToGroup: Bool, toId: String) {
        if isToGroup {
            sendToGroup(msg: message, to: toId)
        }else {
            send(msg: message, to: toId)
        }
    }
    
    func logout() {
        guard let mqtt = mqtt else { return }
            
        mqtt.disconnect()
    }
    
    func fetchMessages(msgId: String, from: String, type: String, offset: Int = 20) {
        //历史信息  appid/401/clientmsgid/from/type/cursor/offset
        let localId = nextMessageLocalID()
        let topic = "\(appid)/401/\(localId)/\(from)/\(type)/\(type)/\(offset)"
        mqtt?.publish(topic, withString: "")
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
        let topic = "\(appid)\(msg.sufixTopic)"
        
        // 改版思路：直接扩展CocoaMQTTMessage，而不需要自己构建Mesg_1vN消息模型
        mqtt?.publish(topic, withString: msg.text, qos: CocoaMQTTQOS(rawValue: UInt8(msg.qos))!, retained: msg.retained)
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
        
        if let topicModel = StatusTopicModel(topic) {
            delegate?.friendStatus(message.string, friendId: topicModel.friendId)
        }else if let topicModel =  TopicModel(message.topic) {
            if topicModel.operation == 0 {
                // create a group
                delegate?.joinedChatRoom(groupId: topicModel.to)
            }else if topicModel.operation == 201 {
                TRACE("加入群成功")
                delegate?.joinedChatRoom(groupId: topicModel.to)
            }else if topicModel.operation == 202 {
                TRACE("退出群聊成功")
                delegate?.quitGroup(gid: topicModel.to, error: nil)
            }else if topicModel.operation == 401 {
                TRACE("获取历史信息")
                let msgs = message.string.value.components(separatedBy: "##").compactMap{
                    Mesg(payload: $0)
                }
                delegate?.mavlDidReceived(messages: msgs)
            }else {
                let msg = Mesg(fromUid: topicModel.from, toUid: topicModel.to, groupId: topicModel.gid, serverId: topicModel.serverId, text: message.string.value, timestamp: Date().timeIntervalSince1970)
                delegate?.mavlDidReceived(message: msg)
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
        delegate?.logout(withError: err)
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
