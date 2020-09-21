//
//  ViewController.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var tfUserName: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    
    var mavlMsgClient: MavlMessage?
    
    private var isLogin: Bool = false {
        didSet {
            if isLogin {
                title = "Online"
                loginView.isHidden = true
                itemAdd.isEnabled = true
            }else {
                title = "Offline"
                tfUserName.text = ""
                tfPassword.text = "xxxxxx"
                loginView.isHidden = false
                itemAdd.isEnabled = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isLogin = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectedContacts(noti:)), name: .selectedContacts, object: nil)
    }
    
    @objc func didSelectedContacts(noti: Notification) {
        guard let object = noti.object else { return }
        
        print("选中的联系人是: \(object)")
    }

    @IBAction func loginAction(_ sender: Any) {
        guard let username = tfUserName.text,
            let password = tfPassword.text else { return }
        
        let config = MavlMessageConfiguration(appid: GlobalConfig.xnAppId, appkey: GlobalConfig.xnAppKey, uuid: username, token: password)
        mavlMsgClient = MavlMessage(config: config)
        mavlMsgClient?.delegate = self
        mavlMsgClient?.login()
    }
    
    @IBAction func addChatSession(_ sender: Any) {
        let alert = UIAlertController(title: "What do you want to do?", message: nil, preferredStyle: .actionSheet)
        let actionAddFriend = UIAlertAction(title: "Add a friend", style: .default) { _  in
            
        }
        alert.addAction(actionAddFriend)
        let actionCreateGroup = UIAlertAction(title: "Create a group chat", style: .default) { _ in
            guard let friendListVc = self.storyboard?.instantiateViewController(identifier: "FriendListController") as? FriendListController else { return }
            
            self.present(friendListVc, animated: true, completion: nil)
        }
        alert.addAction(actionCreateGroup)
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actionCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: MavlMessageDelegate {
    func beginLogin() {
        TRACE("start login...")
    }
    
    func loginSuccess() {
        TRACE("login success")
        isLogin = true
    }
    
    func joinedChatRoom(groupId gid: String) {
        
    }
    
    func sendMessageSuccess() {
        
    }
    
    func mavlDidReceived(message msg: String?, topic t: String) {
        
    }
    
    func logoutSuccess() {
        isLogin = false
    }
}

extension ViewController {
    public func TRACE(_ msg: String) {
        print(">>>: \(msg)")
    }
}
