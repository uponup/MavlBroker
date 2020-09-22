//
//  Global.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

enum GlobalConfig {
    static let xnAppId = "56"
    static let xnAppKey = "c90265a583aaea81"
}

extension Notification.Name {
    static let selectedContacts = Notification.Name("selectedContacts")
    static let didReceiveMesg = Notification.Name(rawValue: "didReceiveMesg")
    static let friendStatusDidUpdated = Notification.Name("friendStatusDidUpdated")
}
