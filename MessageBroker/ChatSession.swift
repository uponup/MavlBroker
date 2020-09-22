//
//  ChatSession.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

struct ChatSession {
    var gid: String = ""
    var sessionName: String
    var isGroup: Bool
    
    init(gid: String, sessionName: String = "", isGroup: Bool = true) {
        self.gid = gid
        self.sessionName = sessionName
        self.isGroup = isGroup
    }
}
