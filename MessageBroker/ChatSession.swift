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
    var sessionName = ""
    
    init(gid: String) {
        self.gid = gid
    }
}
