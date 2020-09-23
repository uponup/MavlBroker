//
//  MavlMesgUserDefault.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/23.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

private let CONSTANT_KEY_PUSH_TOKEN_STRING = "CONSTANT_KEY_PUSH_TOKEN_STRING"

extension MavlMessage {
    static func setDeviceToken(token: Data) {
        let pushToken = token.map { String(format: "%02.2hhx", $0) }.joined()
        MavlUserdefault.savePushToken(tokenString: pushToken)
    }
    
    static func setDeviceToken(tokenString: String) {
        MavlUserdefault.savePushToken(tokenString: tokenString)
    }
    
    func getDeviceToken() -> String? {
        MavlUserdefault.getPushTokenString()
    }
}

fileprivate struct MavlUserdefault {
    static func savePushToken(tokenString token: String) {
        UserDefaults.standard.setValue(token, forKey: CONSTANT_KEY_PUSH_TOKEN_STRING)
        UserDefaults.standard.synchronize()
    }

    static func getPushTokenString() -> String? {
        UserDefaults.standard.value(forKey: CONSTANT_KEY_PUSH_TOKEN_STRING) as? String
    }
    
    static func removePushToken() {
        
    }
}
