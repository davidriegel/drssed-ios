//
//  Extensions.swift
//  Clothing Booth
//
//  Created by David Riegel on 10.08.24.
//

import Foundation
import UIKit

extension UIColor {
    static let skeletonColor = UIColor(named: "skeletonColor")!
    
    func hexStringFromColor(color: UIColor) -> String {
        let components = color.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
     }
}
