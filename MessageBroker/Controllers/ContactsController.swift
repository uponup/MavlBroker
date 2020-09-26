//
//  ContactsController.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/26.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class ContactsController: UITableViewController {

    lazy var contacts: [[ContactModel]] = {
        [UserCenter.center.fetchGroupsList().map{ ContactModel(uid: $0, isGroup: true) },
         UserCenter.center.fetchContactsList().map{ ContactModel(uid: $0) }].map{
            $0.count == 0 ? nil : $0
        }.compactMap{ $0 }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Contacts"
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFriendStatusUpdate(noti:)), name: .friendStatusDidUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveLoginSuccess), name: .loginSuccess, object: nil)
        checkStatus()
    }
    
    // MARK: Notification Action
    @objc func didReceiveLoginSuccess(noti: Notification) {
        checkStatus()
    }
    
    @objc func didReceiveFriendStatusUpdate(noti: Notification) {
        guard let obj = noti.object as? [String: String],
            let uid = obj.keys.first,
            let status = obj.values.first else { return }
        
        var s = [[ContactModel]]()
        
        for arr in contacts {
            var tempArr = [ContactModel]()
            for var model in arr {
                if model.uid.lowercased() == uid {
                    model.status = status
                }
                tempArr.append(model)
            }
            s.append(tempArr)
        }
        contacts.removeAll()
        contacts.append(contentsOf: s)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return contacts.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts[section].count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionView = UIView()
        sectionView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        let label = UILabel(frame: CGRect(x: 12, y: 0, width: 200, height: 32))
        label.text = contacts[section].first!.isGroup ? "Groups" : "Friends"
        sectionView.addSubview(label)
        return sectionView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell", for: indexPath) as! ContactCell
        let contact = contacts[indexPath.section][indexPath.row]
        cell.updateData(contact)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    // MARK: Private Method
    private func checkStatus() {
        guard let friends = contacts.last else { return }
        for contact in friends {
            MavlMessage.shared.checkStatus(withUserName: contact.uid.lowercased())
        }
    }
}
