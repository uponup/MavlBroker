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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func updateData(session: ChatSession) {
        ivSessionIcon.image = #imageLiteral(resourceName: "chatroom_default")
        labelName.text = session.gid
        labelDetail.text = "last msg"    // last msg, default is ""
    }
}
