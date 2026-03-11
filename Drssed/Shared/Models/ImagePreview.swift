//
//  ImagePreview.swift
//  Drssed
//
//  Created by David Riegel on 12.08.25.
//


public struct ImagePreview: Codable {
    let image_url: String
    let image_id: String
    let image_color: String
    let image_category: ClothingCategories
}
