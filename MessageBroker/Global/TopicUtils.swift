//
//  TopicUtils.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/22.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

//发送 appid/0/localid/gid            create group
//    appid/1/localid/toid           1v1
//    appid/2/clientmsgid/togid      1vN

//收到 appid/0/localid/togid/serverid/fromid
//    appid/1/localid/touid/serverid/fromuid
//    appid/2/localid/togid/serverid/fromuid

//用户状态  appid/userstatus/uid/online
    

struct TopicModel {
    var appid: String
    var operation: Int
    var localId: String
    var to: String
    var from: String
    var serverId: String
    var isGroupMsg: Bool {
        operation != 1
    }
    
    
    init?(_ topic: String) {
        let segments = topic.components(separatedBy: "/")
        guard segments.count >= 6, let op = Int(segments[1]) else { return nil }
        
        appid = segments[0]
        operation = op
        localId = segments[2]
        to = segments[3].replacingOccurrences(of: "\(appid)_", with: "")
        serverId = segments[4]
        from = segments[5].replacingOccurrences(of: "\(appid)_", with: "")
    }
}

struct StatusTopicModel {
    var appid: String
    var friendId: String
    
    init?(_ topic: String) {
        let segments = topic.components(separatedBy: "/")
        guard segments.count == 4 else { return nil }
        
        let status: String = segments[1]
        let type: String = segments[3]
        
        guard status == "userstatus" && type == "online" else { return nil }
        self.appid = segments[0]
        self.friendId = segments[2].replacingOccurrences(of: "\(appid)_", with: "")
    }
}


extension String {
    subscript (range: CountableRange<Int>) -> String {
        get {
            if self.count < range.upperBound { return "" }
            let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
            return self[startIndex..<endIndex].toString()
        }
        set {
            if self.count < range.upperBound { return }
            let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
            self.replaceSubrange(startIndex..<endIndex, with: newValue)
        }
    }
    
    subscript (range: CountableClosedRange<Int>) -> String {
        get {
            return self[range.lowerBound..<(range.upperBound + 1)]
        }
        set {
            self[range.lowerBound..<(range.upperBound + 1)] = newValue
        }
    }
    
    subscript (index: Int) -> String {
        get {
            guard index < count else { return "" }
            let str = self[self.index(startIndex, offsetBy: index)]
            return String(str)
        }
        set {
            self[index...index] = newValue
        }
    }
}

extension Substring {
    public func toString() -> String {
        return String(self)
    }
}
