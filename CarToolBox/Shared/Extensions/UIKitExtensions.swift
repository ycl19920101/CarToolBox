//
//  UIKitExtensions.swift
//  CarToolBox
//
//  Created by Chunlin Yao on 2026/3/6.
//

import UIKit
import SwiftUI

extension UINavigationController {
    func toHostingController<Content: View>(_ root: Content) -> UIViewController {
        let hostingController = UIHostingController(rootView: root)
        return hostingController
    }
}