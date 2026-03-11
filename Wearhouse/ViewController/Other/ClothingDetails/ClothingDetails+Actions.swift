//
//  ClothingDetails+Actions.swift
//  Clothing Booth
//
//  Created by David Riegel on 23.04.25.
//

import UIKit

extension ClothingDetailsController {
    
    @objc
    func uploadImage() {
        let selectionAlert = UIAlertController(title: "👕", message: "Please ensure a high contrast between the clothing piece and the background also try to use a bright environment for better results.", preferredStyle: .alert)
        selectionAlert.addAction(UIAlertAction(title: "Upload Image", style: .default, handler: { _ in
            self.present(self.imagePickerController, animated: true)
        }))
        selectionAlert.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { _ in
            let infoAlert = UIAlertController(title: "Soon", message: "This is currently not possible but very soon will be.", preferredStyle: .alert)
            infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
            self.present(infoAlert, animated: true)
        }))
        selectionAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(selectionAlert, animated: true)
    }
    
    @objc
    func showPickerView(_ sender: UIButton) {
        guard typePicker.isHidden == true else {
            return
        }
        
        let bottomOfPickerButton = clothingTypeField.convert(clothingTypeField.bounds, to: view).maxY
        let topOfPicker = view.frame.height - typePicker.frame.height
        let heightDifferenceOfPickerButton = clothingTypeField.convert(clothingTypeField.bounds, to: typePicker).maxY
        
        typePicker.isHidden = false
        typePickerDone.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            if bottomOfPickerButton > topOfPicker {
                let topConstraint = self.clothingImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
                topConstraint!.constant = -heightDifferenceOfPickerButton
                self.clothingImageView.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
            self.typePicker.alpha = 1
            self.typePickerDone.alpha = 1
        }
    }
    
    @objc func hidePickerView() {
        UIView.animate(withDuration: 0.3) {
            let topConstraint = self.clothingImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
            topConstraint!.constant = 15
            self.clothingImageView.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.typePicker.alpha = 0
            self.typePickerDone.alpha = 0
        } completion: { _ in
            self.typePicker.isHidden = true
            self.typePickerDone.isHidden = true
        }
    }
    
    @objc
    func showColorPicker() {
        present(colorPickerView, animated: true)
    }
    
    @objc func seasonButtonTapped() {
        showSeasonPicker { selectedSeason in
            let seasonName = String(selectedSeason.dropFirst(2))
            #warning("This needs to replaced with real picker")
            /*if self.selectedSeasonsArray.contains(seasonName) {
                self.selectedSeasonsArray.remove(at: self.selectedSeasonsArray.firstIndex(of: seasonName)!)
            } else {
                self.selectedSeasonsArray.append(seasonName)
            }*/
        }
    }
    
    @objc func tagButtonTapped() {
        showTagPicker { selectedTag in
            let tagName = String(selectedTag.dropFirst(2))
            #warning("This needs to replaced with real picker")
            /*if self.selectedTagsArray.contains(tagName) {
                self.selectedTagsArray.remove(at: self.selectedTagsArray.firstIndex(of: tagName)!)
            } else {
                self.selectedTagsArray.append(tagName)
            }*/
        }
    }
    
    @objc
    func startEditing() {
        isEditingClothing = true
    }
    
    @objc
    func finishEditing() {
        isEditingClothing = false
        guard checkChangesMade() else { return }
        
        clothing.name = clothingNameField.fieldInput.text ?? clothing.name
        clothing.category = ClothingCategories(rawValue: clothingTypeLabel.text?.uppercased() ?? clothing.category.rawValue) ?? clothing.category
        clothing.tags = selectedTagsArray
        clothing.seasons = selectedSeasonsArray
        clothing.color = colorPickerView.selectedColor
        clothing.imageID = updatedImageID ?? clothing.imageID
        
        Task {
            do {
                try await saveChanges()
                
                delegate?.didEditClothing(clothing)
            } catch let e {
                ErrorHandler.handle(e)
            }
        }
    }
    
    @objc
    func confirmDeleteClothing() {
        let confirmationAlert = UIAlertController(title: "Are you sure you want to delete \"\(clothingNameField.fieldInput.text ?? clothing.name)\"", message: "", preferredStyle: .alert)
        
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmationAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            Task {
                do {
                    await AppRepository.shared.clothingRepository.deleteClothing(with: self.clothing.id)
                    self.delegate?.didDeleteClothing(self.clothing)
                    self.dismiss(animated: true)
                }
            }
        }))
        
        present(confirmationAlert, animated: true)
    }
}
