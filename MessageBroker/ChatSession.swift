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
    
    init(dict: [String: Any]) {
        self.gid = dict["gid"] as! String
        self.sessionName = dict["session"] as! String
        self.isGroup = dict["isGroup"] as! Bool
    }
    
    func toDic() -> [String: Any] {
        return [
            "gid": gid,
            "session": sessionName,
            "isGroup": isGroup
        ]
    }
}
