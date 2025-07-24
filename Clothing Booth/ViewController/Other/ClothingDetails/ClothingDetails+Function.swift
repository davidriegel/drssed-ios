//
//  hekll.swift
//  Clothing Booth
//
//  Created by David Riegel on 23.04.25.
//

import UIKit

extension ClothingDetailsController {
    func showSeasonPicker(completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Pick a Season", message: nil, preferredStyle: .actionSheet)
        
        let tags = ["🌱 Spring", "☀️ Summer", "🍂 Autumn", "❄️ Winter"]
        
        for tag in tags {
            alert.addAction(UIAlertAction(title: tag, style: .default, handler: { _ in
                completion(tag)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func showTagPicker(completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Pick a Tag", message: nil, preferredStyle: .actionSheet)
        
        let tags = ["🧍🏻 Casual", "🕴🏻 Formal", "⛹🏻 Sports", "🧳 Vintage"]
        
        for tag in tags {
            alert.addAction(UIAlertAction(title: tag, style: .default, handler: { _ in
                completion(tag)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    func setEditingMode() {
        clothingImageView.isUserInteractionEnabled = isEditingClothing
        clothingNameTextField.isUserInteractionEnabled = isEditingClothing
        typeButton.isUserInteractionEnabled = isEditingClothing
        clothingSeasonsLabel.isUserInteractionEnabled = isEditingClothing
        clothingColorButton.isUserInteractionEnabled = isEditingClothing
        clothingTagsLabel.isUserInteractionEnabled = isEditingClothing
    }
    
    func checkChangesMade() -> Bool {
        return !(clothingNameTextField.text == clothing.name && (updatedImageID == nil) && clothingTypeLabel.text == clothing.category && selectedTagsArray == clothing.tags && selectedSeasonsArray == clothing.seasons && colorPickerView.selectedColor.hexStringFromColor(color: colorPickerView.selectedColor) == clothing.color)
    }
    
    func saveChangesToDatabase(_ item: Clothing) async throws {
        try await APIHandler.shared.clothingHandler.patchEditClothing(clothing: item)
    }
    
    func saveChangesToUserDefaults(_ item: Clothing) throws {
        var clothesArray = try JSONDecoder().decode([Clothing].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data())
        
        guard let clothingIndex = clothesArray.firstIndex (where: { $0.clothing_id == clothing.clothing_id }) else {
            return assertionFailure("clothingIndex should not be nil")
        }
        
        clothesArray[clothingIndex] = item
        
        let encoded = try JSONEncoder().encode(clothesArray)
        
        UserDefaults.standard.setValue(encoded, forKey: "userClothes")
    }
}
