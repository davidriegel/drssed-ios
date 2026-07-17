//
//  ToastPresenter.swift
//  Drssed
//
//  Created by David Riegel on 10.05.26.
//

import UIKit
import Toast

enum ToastPresenter {
    
    private static var defaultConfig: ToastConfiguration {
        ToastConfiguration(allowToastOverlap: false)
    }
    
    static func success(_ message: String) {
        Toast.default(
            image: UIImage(systemName: "checkmark.circle.fill")!,
            imageTint: .accent,
            title: message,
            config: defaultConfig
        ).show(haptic: .success)
    }
    
    static func error(_ message: String) {
        Toast.default(
            image: UIImage(systemName: "x.circle.fill")!,
            imageTint: .systemRed,
            title: message,
            config: defaultConfig
        ).show(haptic: .error)
    }
    
    static func info(_ message: String) {
        Toast.default(
            image: UIImage(systemName: "info.circle.fill")!,
            imageTint: .systemBlue,
            title: message,
            config: defaultConfig
        ).show(haptic: .warning)
    }
}
