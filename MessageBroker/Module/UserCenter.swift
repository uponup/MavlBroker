//
//  UserCenter.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/23.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

struct Passport {
    var uid: String
    var pwd: String
    
    init(_ uid: String, _ pwd: String) {
        self.uid = uid
        self.pwd = pwd
    }
    
    init(dict: [String: String]) {
        self.uid = dict["uid"] ?? ""
        self.pwd = dict["pwd"] ?? ""
    }
    
    func toDic() -> [String: String] {
        return ["uid": uid, "pwd": pwd]
    }
}

class UserCenter {
    static let center = UserCenter()
    
    private let key = "com.tm.messagebroker.passport"
    private var _passport: Passport? {
        didSet {
            storePassport()
        }
    }
    
    var passport: Passport? {
        return _passport
    }
    
    func login(passport: Passport) {
        _passport = passport
    }
    
    func logout() {
        // todo清除用户数据?
    }
    
    func save(sessionList list:[[String: Any]]) {
        guard let passport = passport else { return }
        let sessionKey = "\(passport.uid)_sessionList"
        UserDefaults.set(list, forKey: sessionKey)
    }
    
    func fetchSessionList() -> Any? {
        guard let passport = passport else { return nil }
        let sessionKey = "\(passport.uid)_sessionList"
        return UserDefaults.object(forKey: sessionKey)
    }
    
    
    func save(contactsList contacts: [String]) {
        guard let passport = passport else { return }
        let contactsKey = "\(passport.uid)_contactsList"
        UserDefaults.set(contacts, forKey: contactsKey)
    }
    
    func fetchContactsList() -> [String] {
        let defaultContacts = ["Sheep", "Pig", "Horse"]
        
        guard let passport = passport else { return defaultContacts}
        let contactsKey = "\(passport.uid)_contactsList"
        
        guard let contacts =  UserDefaults.object(forKey: contactsKey) as? [String] else { return defaultContacts }
        return contacts
    }
    
    func save(groupList gourps: [String]) {
        guard let passport = passport else { return }
        let groupsKey = "\(passport.uid)_groupsList"
        UserDefaults.set(gourps, forKey: groupsKey)
    }
    
    func fetchGroupsList() -> [String] {
        guard let passport = passport else { return [] }
        let groupsKey = "\(passport.uid)_groupsList"
        return UserDefaults.object(forKey: groupsKey) as? [String] ?? [] 
    }
    
    private func storePassport() {
        if let passport = _passport {
            UserDefaults.standard.set(passport.toDic(), forKey: key)
        }
    }
}


extension UserDefaults {
    public class func set(_ value: Any?, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    public class func object(forKey key: String) -> Any? {
        return UserDefaults.standard.object(forKey: key)
    }
    
    public class func removeObject(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
}
