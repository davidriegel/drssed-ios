//
//  ItemWrapper.swift
//  Drssed
//
//  Created by David Riegel on 01.04.26.
//

import Foundation

struct ItemWrapper<T: Decodable>: Decodable {
    let item: T
}
