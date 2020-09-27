//
//  ChatSessionCell.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class ChatSessionCell: UITableViewCell {

    @IBOutlet weak var ivSessionIcon: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelDetail: UILabel!
    @IBOutlet weak var labelDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func updateData(session: ChatSession) {
        ivSessionIcon.image = session.isGroup ? #imageLiteral(resourceName: "chatroom_default") : #imageLiteral(resourceName: "avatar_default")
        labelName.text = session.gid
        
        guard let mesg = MesgDao.fetch(forTo: session.gid) else {
            labelDate.isHidden = true
            labelDetail.isHidden = true
            return
        }
        labelDate.isHidden = false
        labelDetail.isHidden = false
        labelDetail.text = (session.isGroup && UserCenter.isMe(uid: mesg.fromUid)) ?  "\(mesg.text)" : "\(mesg.fromUid.capitalized): \(mesg.text)"
        labelDate.text = Date(timeIntervalSince1970: mesg.timestamp).toString(with: .MMddHHmm)
    }
}

public enum DateFormat: String {
    case MMddHHmm = "MM-dd HH:mm"
    case yyyyMMddHHmm = "yyyy MM-dd HH:mm"
    case yyyyMMddHHmmss = "yyyy MM-dd HH:mm:ss"
}

extension Date {
    public func toString(with format: DateFormat) -> String {
        return toString(withFormatString: format.rawValue)
    }
    
    public func toString(withFormatString string: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = string
        formatter.timeZone = TimeZone.current
        return formatter.string(from: self)
    }
}
