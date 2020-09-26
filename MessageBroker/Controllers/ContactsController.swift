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
    
    private lazy var groups: [ContactModel] = {
        UserCenter.center.fetchGroupsList().map{ ContactModel(uid: $0, isGroup: true)}
    }()
    private lazy var contacts: [ContactModel] = {
        UserCenter.center.fetchContactsList().map{ ContactModel(uid: $0) }
    }()
    
    
    private var addGid: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkStatus()
        itemAdd.isEnabled = MavlMessage.shared.isLogin
        MavlMessage.shared.delegateGroup = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFriendStatusUpdate(noti:)), name: .friendStatusDidUpdated, object: nil)
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
            self.showTextFieldAlert(type: false)
        }
        alert.addAction(actionJoinGroup)
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actionCancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showTextFieldAlert(type isAddFriend: Bool = true) {
        let title = isAddFriend ? "Join a group" : "Friend someone"
    
        let alert = UIAlertController(title: title, message: "Please input \(isAddFriend ? " UserID" : "GroupID") you want", preferredStyle: .alert)
        alert.addTextField { [unowned self] tf in
            NotificationCenter.default.addObserver(self, selector: #selector(self.alertTextFieldDidChanged(noti:)), name: UITextField.textDidChangeNotification, object: nil)
        };
        
        let ok = UIAlertAction(title: "OK", style: .cancel) { [unowned self] _ in
            guard self.addGid.count > 0 else { return }
            if isAddFriend {
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
        itemAdd.isEnabled = true
    }
    
    @objc func didLogoutSuccess() {
        itemAdd.isEnabled = false
    }
    
    @objc func didReceiveLoginSuccess(noti: Notification) {
        checkStatus()
    }
    
    @objc func didReceiveFriendStatusUpdate(noti: Notification) {
        guard let obj = noti.object as? [String: String],
            let uid = obj.keys.first,
            let status = obj.values.first else { return }
        
        var s = [ContactModel]()
        for var model in contacts {
            if model.uid.lowercased() == uid {
                model.status = status
            }
            s.append(model)
        }
        contacts.removeAll()
        contacts.append(contentsOf: s)
        tableView.reloadData()
    }
    
    // MARK: Private Method
    private func checkStatus() {
        for contact in contacts {
            MavlMessage.shared.checkStatus(withUserName: contact.uid.lowercased())
        }
    }
}

extension ContactsController: MavlMessageGroupDelegate {
    
    func createGroupSuccess(groupId gid: String) {
        _addGroup(gid)
    }
    
    func joinedGroup(groupId gid: String, isLauncher: Bool) {
        _addGroup(gid)
        if isLauncher {
            print("您已经加入群聊")
        }else {
            print("您被拉进群聊")
            
        }
    }
    
    func quitGroup(gid: String, error: Error?) {
        
    }
    
    func addFriendSuccess(friendName name: String) {
        
    }
    
    func friendStatus(_ status: String?, friendId: String) {
        
    }
    
    
    private func _addGroup(_ gid: String) {
        let model = ContactModel(uid: gid)
        groups.append(model)
        tableView.reloadData()
    }
}


extension ContactsController {
    // MARK: - Table view data source

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
}
