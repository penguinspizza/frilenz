//
//  NotScreenshot.swift
//  Fri+Lenz
//
//  Created by 後藤翔哉 on 2023/08/19.
//

import Foundation
import UIKit

extension UIView {
    
    // こちらの回答が元ネタです
    // https://stackoverflow.com/a/67054892
    func makeSecure() {
        DispatchQueue.main.async {
            let field = UITextField()
            field.isSecureTextEntry = true
            self.addSubview(field)
            field.translatesAutoresizingMaskIntoConstraints = false
            field.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
            field.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            self.layer.superlayer?.addSublayer(field.layer)
            field.layer.sublayers?.first?.addSublayer(self.layer)
        }
    }
    
}
