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
    @IBOutlet weak var itemClose: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var mavlMsgClient: MavlMessage?
    lazy var sessions: [ChatSession] = {
        []
    }()
    var addGid: String = ""
    
    private var isLogin: Bool = false {
        didSet {
            if isLogin {
                title = "Online"
                loginView.isHidden = true
                itemAdd.isEnabled = true
                itemClose.isEnabled = true
                username = tfUserName.text.value
                
                let passport = Passport(tfUserName.text.value, tfPassword.text.value)
                UserCenter.center.login(passport: passport)
                
                loadData()
            }else {
                title = "Offline"
                tfUserName.text = ""
                tfPassword.text = "xxxxxx"
                loginView.isHidden = false
                itemAdd.isEnabled = false
                itemClose.isEnabled = false
                username = ""
            }
        }
    }
    
    private var username: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isLogin = false
        tableView.tableFooterView = UIView()
        view.bringSubviewToFront(loginView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectedContacts(noti:)), name: .selectedContacts, object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    
    // 刷新数据
    func loadData() {
        guard let sessionList = UserCenter.center.fetchSessionList() as? [[String: Any]] else {
            TRACE("获取缓存信息失败")
            return
        }
        sessions.removeAll()
        let history = sessionList.map{ ChatSession(dict: $0) }
        sessions.append(contentsOf: history)
        
        print(sessions)
        tableView.reloadData()
    }
    
    @objc func didSelectedContacts(noti: Notification) {
        guard let object = noti.object as? [String: Any], let contacts = object["contacts"] as? [String], let isChat1V1 = object["1v1"] as? Bool else { return }
        
        if isChat1V1 {
            guard let friend = contacts.first else { return }
            mavlMsgClient?.addFriend(withUserName: friend)
        }else {
            mavlMsgClient?.createAGroup(withUsers: contacts)
        }
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
            guard let friendListVc = self.storyboard?.instantiateViewController(identifier: "FriendListController") as? FriendListController else { return }
            friendListVc.isChat1V1 = true
            self.present(friendListVc, animated: true, completion: nil)
        }
        alert.addAction(actionAddFriend)
        let actionCreateGroup = UIAlertAction(title: "Create a group chat", style: .default) { _ in
            guard let friendListVc = self.storyboard?.instantiateViewController(identifier: "FriendListController") as? FriendListController else { return }
            
            self.present(friendListVc, animated: true, completion: nil)
        }
        alert.addAction(actionCreateGroup)
        let actionJoinGroup = UIAlertAction(title: "Join a group chat", style: .default) { [unowned self] _ in
            self.joinGroupAction()
        }
        alert.addAction(actionJoinGroup)
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actionCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logout(_ sender: Any) {
        mavlMsgClient?.logout()
    }
    
    @objc func alertTextFieldDidChanged(noti: Notification) {
        guard let alert = self.presentedViewController as? UIAlertController,
        let textfield = alert.textFields?.first,
        let text = textfield.text else { return }
        
         self.addGid = text
    }
    
    private func joinGroupAction() {
        let alert = UIAlertController(title: "Join In", message: "Please input group id you want to join", preferredStyle: .alert)
        alert.addTextField { [unowned self] tf in
            NotificationCenter.default.addObserver(self, selector: #selector(self.alertTextFieldDidChanged(noti:)), name: UITextField.textDidChangeNotification, object: nil)
        };
        
        let ok = UIAlertAction(title: "OK", style: .default) { [unowned self] _ in
            self.mavlMsgClient?.joinGroup(withGroupId: self.addGid)
//            self.mavlMsgClient?.quitGroup(withGroupId: self.addGid)
        }
        alert.addAction(ok)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
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
        TRACE("新加入的是:\(gid)")
        let session = ChatSession(gid: gid)
        sessions.insert(session, at: 0)
        tableView.reloadData()
        
        UserCenter.center.save(sessionList: sessions.map{$0.toDic()})
    }
    
    func addFriendSuccess(friendName name: String) {
        let session = ChatSession(gid: name, sessionName: name, isGroup: false)
        sessions.append(session)
        tableView.reloadData()
        
        UserCenter.center.save(sessionList: sessions.map{$0.toDic()})
    }
    
    func sendMessageSuccess() {
        
    }
    
    func mavlDidReceived(message msg: String?, topic t: String) {
        TRACE("收到信息msg：\(msg.value), topic: \(t)")
        NotificationCenter.default.post(name: .didReceiveMesg, object: ["message": msg ?? "", "topic": t])
    }
    
    func logout(withError: Error?) {
        isLogin = false
        
        guard let err = withError else { return }
        // 如果有err，说明是异常断开连接
        let alert = UIAlertController(title: "Warning", message: err.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func friendStatus(_ status: String?, friendId: String) {
        guard let status = status else {  return }
        NotificationCenter.default.post(name: .friendStatusDidUpdated, object: [friendId: status])
    }
    
    func quitGroup(gid: String, error: Error? = nil) {
        if let err = error {
            TRACE("退出圈子失败: \(err.localizedDescription)")
            return
        }
        
        sessions = sessions.filter{ $0.gid != gid }
        tableView.reloadData()
        
        UserCenter.center.save(sessionList: sessions.map{ $0.toDic() })
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatSessionCell", for: indexPath) as! ChatSessionCell
        let sessionModel = sessions[indexPath.row]
        cell.updateData(session: sessionModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sessionModel = sessions[indexPath.row]
        
        guard let chatVc = storyboard?.instantiateViewController(identifier: "ChatViewController") as? ChatViewController else { return }
        chatVc.hidesBottomBarWhenPushed = true
        chatVc.msgClient = mavlMsgClient
        chatVc.session = sessionModel
        navigationController?.pushViewController(chatVc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = sessions[indexPath.row]
        
        guard session.isGroup  else { return UISwipeActionsConfiguration(actions: []) }
        
        let actionDelete = UIContextualAction(style: .destructive, title: "Quit") { [unowned self] (action, view, block) in
            self.mavlMsgClient?.quitGroup(withGroupId: session.gid)
        }
        
        return UISwipeActionsConfiguration(actions: [actionDelete])
    }
}

extension ViewController {
    public func TRACE(_ msg: String) {
        print(">>>: \(msg)")
    }
}
