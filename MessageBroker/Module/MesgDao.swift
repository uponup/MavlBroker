//
//  MesgDao.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/27.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import Foundation

struct MesgDao {
    static func save(latestMesg mesg: Mesg) {
        guard let passport = MavlMessage.shared.passport else { return }
        let key = "\(passport.uid)_\(mesg.toUid)_latestMesg"
        UserDefaults.set(mesg.toDict(), forKey: key)
    }
    
    static func fetch(forTo toUid: String) -> Mesg? {
        guard let passport = MavlMessage.shared.passport else { return nil }
        
        let key = "\(passport.uid)_\(toUid)_latestMesg"
        guard let mesgDict = UserDefaults.object(forKey: key) as? [String: Any] else { return nil }
        
        return Mesg(dict: mesgDict)
    }
}
