//
//  Mesg.swift
//  Example
//
//  Created by 龙格 on 2020/9/19.
//  Copyright © 2020 emqtt.io. All rights reserved.
//

import Foundation

/**
    接收到的信息数据模型
 */
struct Mesg {
    var fromUid: String
    var toUid: String
    var groupId: String
    var serverId: String
    var text: String
    var status: Int
    var timestamp: TimeInterval
    
//    56_peter,56_peter,05aff857d249c2DS,1600935023224, 2,   1600935023,9090##
//    Fromuid，Touid，   Gid，            Servermsgid，Status，Timestamp， Msg
    init?(payload: String) {
        let segments = payload.components(separatedBy: ",")
        guard segments.count > 6 else { return nil }
        
        let appid = MavlMessage.shared.appid
        fromUid = segments[0].replacingOccurrences(of: "\(appid)_", with: "")
        toUid = segments[1].replacingOccurrences(of: "\(appid)_", with: "")
        groupId = segments[2]
        serverId = segments[3]
        status = Int(segments[4]) ?? 0
        timestamp = TimeInterval(segments[5])!
        let index = segments.count
        text = segments[6..<index].joined(separator: ",")
    }
    
    init(fromUid: String, toUid: String, groupId: String, serverId: String, text: String, timestamp: TimeInterval, status: Int) {
        self.fromUid = fromUid
        self.toUid = toUid
        self.groupId = groupId
        self.serverId = serverId
        self.text = text
        self.timestamp = timestamp
        self.status = status
    }
}



public enum FetchMessagesType: Int {
    case one = 1
    case more
}

enum Operation {
    case createGroup
    case oneToOne(_ localId: UInt16, _ toUid: String)
    case oneToMany(_ localId: UInt16, _ toGid: String)
    case vitualGroup(_ toGid: String)
    
    case joinGroup(_ toGid: String)
    case quitGroup(_ toGid: String)
    
    case uploadToken
    
    case fetchMsgs(_ from: String, _ type: FetchMessagesType, _ cursor: String, _ offset: Int)
    
    var value: Int {
        switch self {
        case .createGroup:  return 0
        case .oneToOne:     return 1
        case .oneToMany:    return 2
        case .vitualGroup:  return 3
            
        case .joinGroup:    return 201
        case .quitGroup:    return 202
            
        case .uploadToken:  return 300
            
        case .fetchMsgs:    return 401
        }
    }
    
    
    var topic: String {
        let topicPrefix = "\(MavlMessage.shared.appid)/\(value)/\(localId)"
        
        switch self {
        case .createGroup:
            return "\(topicPrefix)/_"
        case .oneToOne(_, let uid):
            return "\(topicPrefix)/\(uid)"
        case .oneToMany(_, let gid):
            return "\(topicPrefix)/\(gid)"
        case .vitualGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .joinGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .quitGroup(let gid):
            return "\(topicPrefix)/\(gid)"
        case .uploadToken:
            return "\(topicPrefix)/_"
        case .fetchMsgs(let from, let type, let cursor, let offset):
            return "\(topicPrefix)/\(from)/\(type.rawValue)/\(cursor)/\(offset)"
        }
    }
    
    private var localId: String {
        switch self {
        case .createGroup, .vitualGroup, .joinGroup, .quitGroup, .uploadToken, .fetchMsgs:
            return "0"
        case .oneToOne(let localId, _):
            return "\(localId)"
        case .oneToMany(let localId, _):
            return "\(localId)"
        }
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
