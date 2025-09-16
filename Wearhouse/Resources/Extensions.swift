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
        
        guard components?.count != nil && components!.count >= 3 else {
            guard UITraitCollection.current.userInterfaceStyle != .dark else {
                return "#FFFFFF"
            }
            
            return "#000000"
        }
        
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
     }
    
    public convenience init?(hex: String) {
        let r, g, b: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: 1.0)
                    return
                }
            }
        }
        
        return nil
    }
}

extension UIViewController {
    func showInteractionBlocker() {
        let overlay = UIView(frame: view.bounds)
        overlay.tag = 2000
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isUserInteractionEnabled = true // blockiert alles darunter
        
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func hideInteractionBlocker() {
        for subview in view.subviews {
            if subview.tag == 2000 {
                subview.removeFromSuperview()
            }
        }
    }
}

extension UIApplication {
    func topMostViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .filter { $0.activationState == .foregroundActive }
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topMostViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController,
           let selected = tab.selectedViewController {
            return topMostViewController(base: selected)
        }
        
        if let presented = base?.presentedViewController {
            return topMostViewController(base: presented)
        }
        
        return base
    }
}


extension UIImage {
    func compressedData(maxSizeMB: Double) -> Data? {
        let maxBytes = Int(maxSizeMB * 1024 * 1024)
        
        var compression: CGFloat = 0.9
        let minCompression: CGFloat = 0.1
        guard var imageData = self.jpegData(compressionQuality: compression) else {
            return nil
        }
        
        if imageData.count > maxBytes {
            var resizedImage = self
            while imageData.count > maxBytes && resizedImage.size.width > 200 {
                let newSize = CGSize(width: resizedImage.size.width * 0.8,
                                     height: resizedImage.size.height * 0.8)
                UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
                resizedImage.draw(in: CGRect(origin: .zero, size: newSize))
                resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? resizedImage
                UIGraphicsEndImageContext()
                
                if let newData = resizedImage.jpegData(compressionQuality: compression) {
                    imageData = newData
                }
            }
        }
        
        while imageData.count > maxBytes && compression > minCompression {
            compression -= 0.1
            if let newData = self.jpegData(compressionQuality: compression) {
                imageData = newData
            }
        }
        
        return imageData.count <= maxBytes ? imageData : nil
    }
}

public enum CornerStyle {
    case small, medium, large, pill, circle
    
    func radius(for view: UIView) -> CGFloat {
        let minSide = min(view.bounds.width, view.bounds.height)
        view.layer.cornerCurve = .continuous
        switch self {
        case .small:  return minSide * 0.08
        case .medium: return minSide * 0.12
        case .large:  return minSide * 0.18
        case .pill:   return view.bounds.height / 2
        case .circle: return minSide / 2
        }
    }
}
