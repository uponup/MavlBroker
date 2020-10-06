//
//  ChatViewController.swift
//  Example
//
//  Created by CrazyWisdom on 15/12/24.
//  Copyright © 2015年 emqtt.io. All rights reserved.
//

import UIKit
import CocoaMQTT
import ESPullToRefresh

class ChatViewController: UIViewController {
    var session: ChatSession?
    var currentStatus: String?
    
    private var _messages: [ChatMessage]?
    var messages: [ChatMessage] {
        get {
            if _messages == nil {
                if let mesg = MesgDao.fetch(forTo: session?.gid ?? "") {
                    _messages = [ChatMessage(status: .sendSuccess, mesg: mesg)]
                }else {
                    _messages = []
                }
            }
            return _messages!
        }
        
        set {
            _messages = newValue
        
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
                self?.scrollToBottom()
            }
        }
    }
    
    private var slogan: String {
        guard let session = session else {
            return "Error: No Session To Match"
        }
        if session.isGroup {
            return "Gid: \(session.gid)";
        }else {
            return "\(session.sessionName)";
        }
    }
        
    private var status: String? {
        didSet {
            if status == "online" {
                statusView.backgroundColor = .green
                statusLabel.text = "online"
            }else {
                statusView.backgroundColor = .darkGray
                statusLabel.text = "offline"
            }
        }
    }
    
    private var latestMessagesId: String {
        guard let lastestMessage = messages.first else { return "" }
        
        return lastestMessage.uuid
    }
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextView: UITextView! {
        didSet {
            messageTextView.layer.cornerRadius = 5
        }
    }
    @IBOutlet weak var animalAvatarImageView: UIImageView!
    @IBOutlet weak var sloganLabel: UILabel!
    
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inputViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendMessageButton: UIButton! {
        didSet {
            sendMessageButton.isEnabled = false
        }
    }
    
    @IBAction func sendMessage() {
        guard let message = messageTextView.text else { return }
        
        guard let session = session else { return }
        if session.isGroup {
            MavlMessage.shared.sendToChatRoom(message: message, isToGroup: true, toId: session.gid)
        }else {
            MavlMessage.shared.sendToChatRoom(message: message, isToGroup: false, toId: session.gid)
        }
        messageTextView.text = ""
        sendMessageButton.isEnabled = false
        messageTextViewHeightConstraint.constant = messageTextView.contentSize.height
        messageTextView.layoutIfNeeded()
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageTextView.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.es.addPullToRefresh { [weak self] in
            
            guard let session = self?.session else {
                self?.tableView.es.stopPullToRefresh()
                return
            }
            let type: FetchMessagesType = session.isGroup ? .more : .one

            print("====>从\((self?.latestMessagesId).value)开始请求")

            MavlMessage.shared.fetchMessages(msgId: (self?.latestMessagesId).value, from: session.gid, type: type, offset: 10)
        }
        
        animalAvatarImageView.image = (session?.isGroup ?? false) ?  #imageLiteral(resourceName: "chatroom_default") : #imageLiteral(resourceName: "avatar_default")
        sloganLabel.text = slogan
        
        if let session = session, !session.isGroup {
            // TODO：订阅status通知
        }else {
            statusView.isHidden = true
            statusLabel.isHidden = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(receivedMessage(notification:)), name: .didReceiveMesg, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedStatusChanged(notification:)), name: .friendStatusDidUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receivedWillSendMessage(notification:)), name: .willSendMesg, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveDidSendMessageFailed(notification:)), name: .didSendMesgFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveDidSendMessage(notification:)), name: .didSendMesg, object: nil)
        
        guard let currentStatus = currentStatus, currentStatus.count > 0 else {
            status = "offline"
            return
        }
        status = currentStatus
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: Notification Action
    @objc func keyboardChanged(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let keyboardValue = userInfo["UIKeyboardFrameEndUserInfoKey"]
        let bottomDistance = UIScreen.main.bounds.size.height - keyboardValue!.cgRectValue.origin.y - UIScreen.bottomEdge
        
        if bottomDistance > 0 {
            inputViewBottomConstraint.constant = bottomDistance
        } else {
            inputViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }
    
    @objc func receivedStatusChanged(notification: NSNotification) {
        guard let session = session else { return }
        guard let obj = notification.object as? [String: String],
            let status = obj["status"],
            let uid = obj["uid"]
            else { return }
        
        if session.gid.lowercased() == uid {
            self.status = status
        }
    }
    
    @objc func receivedWillSendMessage(notification: NSNotification) {
        guard let object = notification.object as? [String: Mesg],
            let msg = object["msg"] else { return }
        
        let message = ChatMessage(status: .sending, mesg: msg)
        messages.append(message)
        tableView.reloadData()
        
        print("将要发送:\(msg.text)")
    }
    
    @objc func receiveDidSendMessage(notification: NSNotification) {
        guard let object = notification.object as? [String: Mesg],
            let msg = object["msg"] else { return }
        messages = messages.map {
            if $0.localId == msg.localId.value {
//                return ChatMessage(status: .send, mesg: msg)
                return $0
            }else {
                return $0
            }
        }
        
        tableView.reloadData()
        print("发送成功:\(msg.text)")
    }
    
    @objc func receiveDidSendMessageFailed(notification: NSNotification) {
        guard let object = notification.object as? [String: Any],
            let _ = object["err"] as? Error,
            let msg = object["msg"] as? Mesg else { return }
        
        messages = messages.map {
            if $0.localId == msg.localId.value {
                return ChatMessage(status: .sendfail, mesg: msg)
            }else {
                return $0
            }
        }
    }
    
    @objc func receivedMessage(notification: NSNotification) {
        
        let object = notification.object as! [String: Any]
        let receivedMsgs = object["msg"] as? [Mesg]
        let isLoadMore = object["isLoadMore"] as! Bool
        
        if isLoadMore {
            tableView.es.stopPullToRefresh()
        }
        
        guard let msgs = receivedMsgs else { return }
        let sortedMsgs = msgs.map{
            ChatMessage(status: .sendSuccess, mesg: $0)
        }.reversed()
        
        if isLoadMore {
            messages.insert(contentsOf: sortedMsgs, at: 0)
            scrollToTop()
        }else {
            messages.append(contentsOf: sortedMsgs)
            var dict: [String: ChatMessage] = [:]
            for message in messages {
                dict[message.localId] = message
            }
            messages = Array(dict.values).sorted(by: <)
        }
    }
    
    func scrollToBottom() {
        guard messages.count > 3 else { return }
        
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    func scrollToTop() {
        guard messages.count > 0 else { return }
        
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}


extension ChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.contentSize.height != textView.frame.size.height {
            let textViewHeight = textView.contentSize.height
            if textViewHeight < 100 {
                messageTextViewHeightConstraint.constant = textViewHeight
                textView.layoutIfNeeded()
            }
        }
        
        sendMessageButton.isEnabled = textView.text.count > 0
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        if message.sender.lowercased() == MavlMessage.shared.passport?.uid.lowercased() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "rightMessageCell", for: indexPath) as! ChatRightMessageCell
            cell.contentLabel.text = messages[indexPath.row].content
            cell.avatarImageView.image = #imageLiteral(resourceName: "iv_chat_local")
            if message.status == .sending {
                cell.labelStatus.text = "Sending..."
                cell.labelStatus.textColor = UIColor.gray
            }else if message.status == .sendfail {
                cell.labelStatus.text = "Send fail"
                cell.labelStatus.textColor = UIColor.red
            }else if message.status == .sendSuccess {
                cell.labelStatus.text = "Send success"
                cell.labelStatus.textColor = UIColor.blue
            }else if message.status == .send {
                cell.labelStatus.text = "Send"
                cell.labelStatus.textColor = UIColor.black
            }else {
                cell.labelStatus.isHidden = true
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "leftMessageCell", for: indexPath) as! ChatLeftMessageCell
            cell.contentLabel.text = messages[indexPath.row].content
            cell.avatarImageView.image = #imageLiteral(resourceName: "iv_chat_remote")
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
    }
}
