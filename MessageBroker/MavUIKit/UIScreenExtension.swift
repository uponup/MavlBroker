//
//  UIScreenExtension.swift
//  MessageBroker
//
//  Created by 龙格 on 2020/9/23.
//  Copyright © 2020 Paul Gao. All rights reserved.
//

import UIKit

extension UIScreen {
    @objc public static var bottomEdge: CGFloat {
        guard let window = UIApplication.shared.windows.first else { return 0}
        if #available(iOS 11.0, *) {
            let bottom = window.safeAreaInsets.bottom
            return bottom == 0 ? 0 : bottom
        } else {
            return 0
        }
    }
}
