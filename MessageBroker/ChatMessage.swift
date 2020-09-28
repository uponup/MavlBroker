//
//  ChatMessage.swift
//  Example
//
//  Created by CrazyWisdom on 16/1/1.
//  Copyright © 2016年 emqtt.io. All rights reserved.
//

import Foundation

enum SendingStatus {
    case sending
    case send           // 已发出
    case sendfail
    case sendSuccess    // 发送成功
}

class ChatMessage {
    
    private var mesg: Mesg?
    var status: SendingStatus
    
    var sender: String {
        guard let mesg = mesg else {
            return ""
        }
        return mesg.fromUid.capitalized
    }
    var content: String {
        guard let mesg = mesg else {
            return ""
        }
        return mesg.text
    }
    
    var uuid: String {
        guard let mesg = mesg else {
            return ""
        }
        return mesg.serverId
    }
    
    var localId: String {
        guard let mesg = mesg else {
            return ""
        }
        return mesg.localId.value
    }
    
    
    init(status: SendingStatus = .send, mesg: Mesg? = nil) {
        self.mesg = mesg
        self.status = status
    }
}

extension ChatMessage: Equatable {
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    static func < (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        guard let lhsMesg = lhs.mesg, let rhsMesg = rhs.mesg else {
            return false
        }
        return lhsMesg.timestamp < rhsMesg.timestamp
    }
}
