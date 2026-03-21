//
//  ModalPresentationDelegate.swift
//  Drssed
//
//  Created by David Riegel on 21.03.26.
//


protocol ModalPresentationDelegate: AnyObject {
    func modalWillDismiss()
}

extension ModalPresentationDelegate {
    func modalWillDismiss() {}
}
