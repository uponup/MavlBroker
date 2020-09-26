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
    
    lazy var sessions: [ChatSession] = {
        []
    }()
    
    private var isLogin: Bool = false {
        didSet {
            if isLogin {
                title = "Online"
                loginView.isHidden = true
                itemClose.isEnabled = true
                
                let passport = Passport(tfUserName.text.value, tfPassword.text.value)
                UserCenter.center.login(passport: passport)
                
                loadData()
            }else {
                title = "Offline"
                tfUserName.text = ""
                tfPassword.text = "xxxxxx"
                loginView.isHidden = false
                itemClose.isEnabled = false
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
        
        tableView.reloadData()
    }
    
    @objc func didSelectedContacts(noti: Notification) {
        guard let object = noti.object as? [String: Any], let contacts = object["contacts"] as? [String], let isChat1V1 = object["1v1"] as? Bool else { return }
        
        if isChat1V1 {
            guard let friend = contacts.first else { return }
            MavlMessage.shared.addFriend(withUserName: friend)
        }else {
            MavlMessage.shared.createAGroup(withUsers: contacts)
        }
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
        
        guard let err = withError else { return }
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
        chatVc.session = sessionModel
        navigationController?.pushViewController(chatVc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = sessions[indexPath.row]
        
        guard session.isGroup  else { return UISwipeActionsConfiguration(actions: []) }
        
        let actionDelete = UIContextualAction(style: .destructive, title: "Quit") { (action, view, block) in
            MavlMessage.shared.quitGroup(withGroupId: session.gid)
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
        
        UIView.animate(withDuration: 1.5, animations: {
            label.transform = CGAffineTransform(rotationAngle: .pi)
            label.transform = .identity
            launchVc.view.alpha = 0
        }) { finished  in
            launchVc.view.removeFromSuperview()
        }
    }
}
