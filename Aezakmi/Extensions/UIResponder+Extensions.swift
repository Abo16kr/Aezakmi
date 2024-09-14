//
//  UIResponder+Extensions.swift
//  PhotoEditor
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import UIKit

extension UIResponder {
    /// Access parent controller
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
