//
//  ContactsController.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/26.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class ContactsController: UITableViewController {

    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    var dataArr: [[ContactModel]] {
        [groups, contacts].filter{ $0.count > 0 }
    }
    
    private var _groups: [ContactModel]?
    private var groups: [ContactModel] {
        get {
            if _groups == nil {
                _groups =  UserCenter.center.fetchGroupsList().map{ ContactModel(uid: $0, isGroup: true)}
            }
            return _groups!
        }
        set {
            _groups = newValue
        }
    }
    
    private var _contacts: [ContactModel]?
    private var contacts: [ContactModel] {
        get {
            if _contacts == nil {
                _contacts = UserCenter.center.fetchContactsList().map{ ContactModel(uid: $0) }
            }
            return _contacts!
        }
        set {
            _contacts = newValue
        }
    }
    
    
    private var addGid: String = ""
    private var isLogin: Bool? {
        didSet {
            itemAdd.isEnabled = isLogin ?? false
            _contacts = nil
            _groups = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkStatus()
        itemAdd.isEnabled = MavlMessage.shared.isLogin
        MavlMessage.shared.delegateGroup = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveLoginSuccess), name: .loginSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLoginSuccess), name: .loginSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didLogoutSuccess), name: .logoutSuccess, object: nil)
    }
    
    // MARK: BarItem Action
    
    @IBAction func addAction(_ sender: Any) {
        let alert = UIAlertController(title: "What do you want to do?", message: nil, preferredStyle: .actionSheet)
        let actionAddFriend = UIAlertAction(title: "Add a friend", style: .default) { [unowned self] _  in
            self.showTextFieldAlert()
        }
        alert.addAction(actionAddFriend)
        let actionCreateGroup = UIAlertAction(title: "Create a group chat", style: .default) { _ in
            guard let friendListVc = self.storyboard?.instantiateViewController(identifier: "FriendListController") as? FriendListController else { return }
            
            self.present(friendListVc, animated: true, completion: nil)
        }
        alert.addAction(actionCreateGroup)
        let actionJoinGroup = UIAlertAction(title: "Join a group chat", style: .default) { [unowned self] _ in
            self.showTextFieldAlert(isAddFriend: false)
        }
        alert.addAction(actionJoinGroup)
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actionCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showTextFieldAlert(isAddFriend type: Bool = true) {
        let title = type ? "Join a group" : "Friend someone"
    
        let alert = UIAlertController(title: title, message: "Please input \(type ? " UserID" : "GroupID") you want", preferredStyle: .alert)
        alert.addTextField { [unowned self] tf in
            NotificationCenter.default.addObserver(self, selector: #selector(self.alertTextFieldDidChanged(noti:)), name: UITextField.textDidChangeNotification, object: nil)
        };
        
        let ok = UIAlertAction(title: "OK", style: .cancel) { [unowned self] _ in
            guard self.addGid.count > 0 else { return }
            if type {
                MavlMessage.shared.addFriend(withUserName: self.addGid)
            }else {
                MavlMessage.shared.joinGroup(withGroupId: self.addGid)
            }
        }
        alert.addAction(ok)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: Notification Action
    @objc func alertTextFieldDidChanged(noti: Notification) {
        guard let alert = self.presentedViewController as? UIAlertController,
        let textfield = alert.textFields?.first,
        let text = textfield.text else { return }
       
        self.addGid = text
    }
       
    @objc func didLoginSuccess() {
        isLogin = true
    }
    
    @objc func didLogoutSuccess() {
        isLogin = false
    }
    
    @objc func didReceiveLoginSuccess(noti: Notification) {
        checkStatus()
    }
    
    // MARK: Private Method
    private func checkStatus() {
        for contact in contacts {
            MavlMessage.shared.checkStatus(withUserName: contact.uid.lowercased())
        }
    }
}

// MARK: - MavlMessageGroupDelegate
extension ContactsController: MavlMessageGroupDelegate {
    
    func createGroupSuccess(groupId gid: String) {
        _addGroup(gid)
    }
    
    func joinedGroup(groupId gid: String, isLauncher: Bool) {
        _addGroup(gid)
        if isLauncher {
            showHud("您已经加入群聊")
        }else {
            showHud("您被邀请进群聊")
        }
    }
    
    func quitGroup(gid: String, error: Error?) {
        groups = groups.filter{ $0.uid != gid }
        tableView.reloadData()
        
        UserCenter.center.save(groupList: groups.map{ $0.uid })
        showHud("已退出群：\(gid)")
    }
    
    func addFriendSuccess(friendName name: String) {
        let model = ContactModel(uid: name)
        contacts.append(model)
        tableView.reloadData()
        
        // 添加成功后，需要监听好友状态
        MavlMessage.shared.checkStatus(withUserName: name.lowercased())
        UserCenter.center.save(contactsList: contacts.map{ $0.uid })
    }
    
    func friendStatus(_ status: String, friendId: String) {
        contacts = contacts.map { m in
            var model = m
            if model.uid.lowercased() == friendId {
                model.status = status
            }
            return model
        }
        tableView.reloadData()
        
        NotificationCenter.default.post(name: .friendStatusDidUpdated, object: ["status": status, "uid": friendId])
    }
    
    
    private func _addGroup(_ gid: String) {
        let model = ContactModel(uid: gid, isGroup: true)
        groups.append(model)
        tableView.reloadData()
        
        UserCenter.center.save(groupList: groups.map{ $0.uid })
    }
}

// MARK: - Table view data source
extension ContactsController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataArr.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArr[section].count
    }
    
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionView = UIView()
        sectionView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        let label = UILabel(frame: CGRect(x: 12, y: 0, width: 200, height: 32))
        label.text = dataArr[section].first!.isGroup ? "Groups" : "Friends"
        sectionView.addSubview(label)
        return sectionView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactCell
        let contact = dataArr[indexPath.section][indexPath.row]
        cell.updateData(contact)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let contactModel = self.dataArr[indexPath.section][indexPath.row]
        
        guard contactModel.isGroup  else { return UISwipeActionsConfiguration(actions: []) }
        
        let actionDelete = UIContextualAction(style: .destructive, title: "Quit") { (action, view, block) in
            MavlMessage.shared.quitGroup(withGroupId: contactModel.uid)
        }
        
        let actionChat = UIContextualAction(style: .normal, title: "Chat") { [unowned self] (action, view, block) in
            guard let chatVc = self.storyboard?.instantiateViewController(identifier: "ChatViewController") as? ChatViewController else { return }
            chatVc.hidesBottomBarWhenPushed = true
            chatVc.session = ChatSession(gid: contactModel.uid)
            self.navigationController?.pushViewController(chatVc, animated: true)
        }
        
        return UISwipeActionsConfiguration(actions: [actionDelete, actionChat])
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
