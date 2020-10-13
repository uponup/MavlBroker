//
//  Passport.swift
//  CocoaAsyncSocket
//
//  Created by 龙格 on 2020/10/8.
//

import Foundation

public struct Passport {
    var uid: String
    var pwd: String
    
    init(_ uid: String, _ pwd: String) {
        self.uid = uid.lowercased()
        self.pwd = pwd
    }
    
    init(dict: [String: String]) {
        self.uid = (dict["uid"] ?? "").lowercased()
        self.pwd = dict["pwd"] ?? ""
    }
    
    func toDic() -> [String: String] {
        return ["uid": uid, "pwd": pwd]
    }
}
