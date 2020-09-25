//
//  ChatMessage.swift
//  Example
//
//  Created by CrazyWisdom on 16/1/1.
//  Copyright © 2016年 emqtt.io. All rights reserved.
//

import Foundation

class ChatMessage {
    
    let sender: String
    let content: String
    let uuid: String
    
    init(sender: String, content: String, uuid: String) {
        self.sender = sender
        self.content = content
        self.uuid = uuid
    }
}
