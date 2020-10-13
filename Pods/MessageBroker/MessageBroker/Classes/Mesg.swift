//
//  Mesg.swift
//  Example
//
//  Created by 龙格 on 2020/9/19.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

/**
    接收到的信息数据模型
 */
public struct Mesg {
    var fromUid: String
    var toUid: String
    var groupId: String
    var serverId: String
    var text: String
    var status: Int
    var timestamp: TimeInterval
    var localId: String?
    
    var isGroup: Bool {
        fromUid == groupId
    }
    
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

// MARK: - Mesg数模转化
extension Mesg {
    
    func toDict() -> [String: Any] {
        return [
            "fromUid": fromUid,
            "toUid": toUid,
            "groupId": groupId,
            "serverId": serverId,
            "text": text,
            "status": status,
            "timestamp": timestamp,
            "localId": localId ?? ""
        ]
    }
    
    init(dict: [String: Any]) {
        self.fromUid = dict["fromUid"] as! String
        self.toUid = dict["toUid"] as! String
        self.groupId = dict["groupId"] as! String
        self.serverId = dict["serverId"] as! String
        self.text = dict["text"] as! String
        self.status = dict["status"] as! Int
        self.timestamp = dict["timestamp"]  as! TimeInterval
        self.localId = dict["localId"] as? String
    }
}
