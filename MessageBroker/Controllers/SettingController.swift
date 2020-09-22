//
//  SettingController.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/21.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

class SettingController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let nav = tabBarController?.viewControllers?.first as? UINavigationController,
            let home = nav.viewControllers.first as? ViewController else { return }
        self.navigationItem.title = home.mavlMsgClient?.currentUserName
    }
}
