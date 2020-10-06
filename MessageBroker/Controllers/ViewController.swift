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
    @IBOutlet weak var itemClose: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    private var _sessions: [ChatSession]?
    var sessions: [ChatSession] {
        get {
            if _sessions == nil {
                guard let sessionList = UserCenter.center.fetchSessionList() else {
                    TRACE("获取缓存信息失败")
                    _sessions = nil
                    return []
                }
                _sessions = sessionList
            }
            return _sessions!
        }
        set {
            _sessions = newValue
        }
    }
    
    private var isLogin: Bool = false {
        didSet {
            view.endEditing(true)
            if isLogin {
                navigationItem.title = "Online"
                loginView.isHidden = true
                itemClose.isEnabled = true
                _sessions = nil
                
                let passport = Passport(tfUserName.text.value, tfPassword.text.value)
                UserCenter.center.login(passport: passport)
                
                refreshData()
            }else {
                navigationItem.title = "Offline"
                tfUserName.text = ""
                tfPassword.text = "xxxxxx"
                loginView.isHidden = false
                itemClose.isEnabled = false
                
                UserCenter.center.logout()
            }
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        isLogin = false
        tableView.tableFooterView = UIView()
        view.bringSubviewToFront(loginView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didSelectedContacts(noti:)), name: .selectedContacts, object: nil)
        
        launchAnimation()
    }
    
    func refreshData() {
        let sortedSessions = sessions.sorted(by: >)
        sessions = sortedSessions
        
        tableView.reloadData()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @objc func didSelectedContacts(noti: Notification) {
        guard let object = noti.object as? [String: [String]], let contacts = object["contacts"] else { return }
        MavlMessage.shared.createAGroup(withUsers: contacts)
    }

    @IBAction func loginAction(_ sender: Any) {
        guard let username = tfUserName.text,
            let password = tfPassword.text else { return }
        MavlMessage.shared.delegateMsg = self
        MavlMessage.shared.delegateLogin = self
        MavlMessage.shared.login(userName: username, password: password)
    }
    
    @IBAction func logout(_ sender: Any) {
        MavlMessage.shared.logout()
    }
}

extension ViewController: MavlMessageDelegate {
    func beginLogin() {
        TRACE("start login...")
    }
    
    func loginSuccess() {
        TRACE("login success")
        isLogin = true
        
        NotificationCenter.default.post(name: .loginSuccess, object: nil)
    }
    
    func logout(withError: Error?) {
        isLogin = false
        
        guard let err = withError else {
            NotificationCenter.default.post(name: .logoutSuccess, object: nil)
            return
        }
        // 如果有err，说明是异常断开连接
        let alert = UIAlertController(title: "Warning", message: err.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: MavlMessageStatusDelegate {
    func mavl(willSend: Mesg) {
        NotificationCenter.default.post(name: .willSendMesg, object: ["msg": willSend])
    }
    
    func mavl(didSend: Mesg, error: Error?) {
        if let err = error {
            NotificationCenter.default.post(name: .didSendMesgFailed, object: ["msg": didSend, "err": err])
        }else {
            NotificationCenter.default.post(name: .didSendMesg, object: ["msg": didSend])
        }
    }
    
    func mavl(didRevceived messages: [Mesg], isLoadMore: Bool) {
        NotificationCenter.default.post(name: .didReceiveMesg, object: ["msg": messages, "isLoadMore": isLoadMore])

        guard let msg = messages.last else { return }
        // 保存最后一条收到的信息
        if isLoadMore == false {
            var item: ChatSession
            if msg.isGroup {
                item = ChatSession(gid: msg.groupId)
            }else {
                item = ChatSession(gid: msg.fromUid, sessionName: msg.fromUid, isGroup: false)
            }
            
            if !(sessions.map{ $0.gid }.contains(item.gid)) {
                sessions.append(item)
            }
            UserCenter.center.save(sessionList: sessions)
            
            MesgDao.save(latestMesg: msg)
        }
        
        refreshData()
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
        tableView.deselectRow(at: indexPath, animated: false)
        
        let sessionModel = sessions[indexPath.row]
        
        guard let chatVc = storyboard?.instantiateViewController(identifier: "ChatViewController") as? ChatViewController else { return }
        chatVc.hidesBottomBarWhenPushed = true
        chatVc.session = sessionModel
        navigationController?.pushViewController(chatVc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = sessions[indexPath.row]
        
        guard session.isGroup  else { return UISwipeActionsConfiguration(actions: []) }
        
        let actionDelete = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] (action, view, block) in
            self.sessions.remove(at: indexPath.row)
            self.refreshData()
            
            UserCenter.center.save(sessionList: self.sessions)
        }
        
        return UISwipeActionsConfiguration(actions: [actionDelete])
    }
}

extension ViewController {
    public func TRACE(_ msg: String) {
        print(">>>: \(msg)")
    }
}

extension ViewController {
    private func launchAnimation() {
        let launchVc = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateViewController(withIdentifier: "launch")
        
        guard let keyWindow = UIApplication.shared.windows.last else {
            TRACE("没有视图")
            return
        }
        keyWindow.addSubview(launchVc.view)
        
        guard let label = launchVc.view.viewWithTag(101),
           let _ = launchVc.view.viewWithTag(100) else { return }
        
        UIView.animate(withDuration: 0.8, animations: {
            label.transform = CGAffineTransform(scaleX: 1.2,y: 1.2)
            launchVc.view.alpha = 0.3
        }) { finished  in
            launchVc.view.removeFromSuperview()
        }
    }
}
