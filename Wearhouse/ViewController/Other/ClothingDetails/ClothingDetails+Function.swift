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
        clothingNameField.fieldInput.isUserInteractionEnabled = isEditingClothing
        clothingTypeField.fieldInput.isUserInteractionEnabled = isEditingClothing
        clothingSeasonsField.fieldInput.isUserInteractionEnabled = isEditingClothing
        clothingColorButton.isUserInteractionEnabled = isEditingClothing
        clothingTagsField.fieldInput.isUserInteractionEnabled = isEditingClothing
    }
    
    func checkChangesMade() -> Bool {
        return !(clothingNameField.fieldInput.text == clothing.name && (updatedImageID == nil) && clothingTypeLabel.text == clothing.category.rawValue && selectedTagsArray == clothing.tags && selectedSeasonsArray == clothing.seasons && colorPickerView.selectedColor.hexStringFromColor(color: colorPickerView.selectedColor) == clothing.color)
    }
    
    func saveChanges() async throws {
        let newClothing = try await APIHandler.shared.clothingHandler.patchEditClothing(oldClothing: clothing, name: clothingNameField.fieldInput.text == clothing.name ? nil : clothingNameField.fieldInput.text, description: nil, category: clothingTypeLabel.text == clothing.category.rawValue ? nil : clothingTypeLabel.text, tags: selectedTagsArray == clothing.tags ? nil : selectedTagsArray, seasons: selectedSeasonsArray == clothing.seasons ? nil : selectedSeasonsArray, color: colorPickerView.selectedColor.hexStringFromColor(color: colorPickerView.selectedColor) == clothing.color ? nil : colorPickerView.selectedColor, image_id: updatedImageID)
        
        var clothesArray = try JSONDecoder().decode([ClothingAPI].self, from: UserDefaults.standard.data(forKey: "userClothes") ?? Data())
        
        guard let clothingIndex = clothesArray.firstIndex (where: { $0.clothing_id == clothing.clothing_id }) else {
            return assertionFailure("clothingIndex should not be nil")
        }
        
        clothesArray[clothingIndex] = newClothing
        
        let encoded = try JSONEncoder().encode(clothesArray)
        
        UserDefaults.standard.setValue(encoded, forKey: "userClothes")
    }
}
