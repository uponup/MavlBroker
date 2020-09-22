//
//  ChatViewController.swift
//  Example
//
//  Created by CrazyWisdom on 15/12/24.
//  Copyright © 2015年 emqtt.io. All rights reserved.
//

import UIKit
import CocoaMQTT


class ChatViewController: UIViewController {
    var username: String?
    var msgClient: MavlMessage?
    var groupId: String?
    var isGroup: Bool = true
    
    var messages: [ChatMessage] = [] {
        didSet {
            tableView.reloadData()
            scrollToBottom()
        }
    }
    
    private var slogan: String {
        if isGroup {
            return "Gid: \(self.groupId.value)";
        }else {
            return "\(self.groupId.value)";
        }
    }
    
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
        guard let client = msgClient, let message = messageTextView.text else { return }
        
        if isGroup {
            client.sendToChatRoom(message: message, isToGroup: true, toId: groupId.value)
        }else {
            client.sendToChatRoom(message: message, isToGroup: false, toId: "56_\(groupId.value.lowercased())")
        }
        messageTextView.text = ""
        sendMessageButton.isEnabled = false
        messageTextViewHeightConstraint.constant = messageTextView.contentSize.height
        messageTextView.layoutIfNeeded()
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        messageTextView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.receivedMessage(notification:)), name: .didReceiveMesg, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardChanged(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        animalAvatarImageView.image = #imageLiteral(resourceName: "chatroom_default")
        sloganLabel.text = slogan
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    
    @objc func keyboardChanged(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let keyboardValue = userInfo["UIKeyboardFrameEndUserInfoKey"]
        let bottomDistance = UIScreen.main.bounds.size.height - (navigationController?.navigationBar.frame.height)! - keyboardValue!.cgRectValue.origin.y
        
        if bottomDistance > 0 {
            inputViewBottomConstraint.constant = bottomDistance
        } else {
            inputViewBottomConstraint.constant = 0
        }
        view.layoutIfNeeded()
    }
    
    @objc func receivedMessage(notification: NSNotification) {
        let object = notification.object as! [String: String]
        let content = object["message"].value
        let topic = object["topic"].value
        
        let sender = topic.components(separatedBy: "/56_")[1]
        let chatMessage = ChatMessage(sender: sender.capitalized, content: content)
        messages.append(chatMessage)
        
        scrollToBottom()
    }
    
    func scrollToBottom() {
        let count = messages.count
        if count > 3 {
            let indexPath = IndexPath(row: count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
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
        if message.sender.lowercased() == username.value.lowercased() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "rightMessageCell", for: indexPath) as! ChatRightMessageCell
            cell.contentLabel.text = messages[indexPath.row].content
            cell.avatarImageView.image = #imageLiteral(resourceName: "iv_chat_local")
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
