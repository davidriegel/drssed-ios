//
//  Extensions.swift
//  Clothing Booth
//
//  Created by David Riegel on 10.08.24.
//

import Foundation
import CoreData
import UIKit

extension UIColor {
    static let skeletonColor = UIColor(named: "skeletonColor")!
    
    var hexString: String {
        let components = self.cgColor.components
        
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
        overlay.alpha = 0
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
        
        UIView.animate(withDuration: 0.3) {
            overlay.alpha = 1.0
        }
    }

    func hideInteractionBlocker() {
        for subview in view.subviews {
            if subview.tag == 2000 {
                UIView.animate(withDuration: 0.3) {
                    subview.alpha = 0.0
                    subview.removeFromSuperview()
                }
            }
        }
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        guard let windowScene = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootViewController = windowScene.windows
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        return topViewController(from: rootViewController)
    }
    
    private func topViewController(from viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return topViewController(from: presented)
        }
        
        if let navigationController = viewController as? UINavigationController,
           let visible = navigationController.visibleViewController {
            return topViewController(from: visible)
        }
        
        if let tabBarController = viewController as? UITabBarController,
           let selected = tabBarController.selectedViewController {
            return topViewController(from: selected)
        }
        
        return viewController
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

extension UIView {
    func renderAsTransparentImage() -> UIImage? {
        // Sicherstellen, dass Canvas Hintergrund transparent ist
        let originalBackground = backgroundColor
        backgroundColor = .clear
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false // 🔑 Transparent möglich

        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        let image = renderer.image { ctx in
            layer.render(in: ctx.cgContext)
        }
        
        // Hintergrund zurücksetzen
        backgroundColor = originalBackground
        return image
    }
}

extension NSManagedObjectContext {
    func saveIfNeeded() throws { if hasChanges { try save() } }
}
