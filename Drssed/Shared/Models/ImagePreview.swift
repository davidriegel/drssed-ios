//
//  ImagePreview.swift
//  Drssed
//
//  Created by David Riegel on 12.08.25.
//


public struct ImagePreviewJob: Codable {
    let job_id: String
}

public struct ImagePreviewStatus: Codable {
    let status: String   // "processing" | "ready" | "failed" | "not_found"
    let image_url: String?
    let image_id: String?
    let image_color: String?
    let image_category: ClothingCategories?
    let image_sub_category: ClothingSubCategories?
}
