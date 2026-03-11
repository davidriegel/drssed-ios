//
//  ClothingDetails+Delegates.swift
//  Clothing Booth
//
//  Created by David Riegel on 23.04.25.
//

import UIKit
import SkeletonView

protocol ClothingDetailsControllerDelegate: AnyObject {
    func didEditClothing(_ clothing: Clothing)
    func didDeleteClothing(_ clothing: Clothing)
}


extension ClothingDetailsController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        Task {
            dismiss(animated: true)
            
            guard let image = info[.editedImage] as? UIImage else { return }
            let assetPath = info[.imageURL] as! NSURL
            let fileExtension = (assetPath.absoluteString ?? "").components(separatedBy: ".").last ?? ""
            
            guard ["png", "jpg", "jpeg"].contains(fileExtension) else {
                let alert = UIAlertController(title: "", message: "Unsupported file type for your profile picture. [\(fileExtension)]", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.dismiss(animated: true)
                }))
                present(alert, animated: true)
                return
            }
            
            clothingImageView.image = nil
            clothingImageView.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            do {
                let (clothingURL, clothingColor, _) = try await APIClient.shared.clothingHandler.removeClothingBackground(from: image)
                
                updatedImageID = clothingURL.deletingPathExtension().lastPathComponent
                colorPickerView.selectedColor = clothingColor
                
//                if let index = clothingCategoriesDataSource.firstIndex(of: clothingCategory.localizedName) {
//                    itemCategoryPicker.selectRow(index, inComponent: 0, animated: false)
//                }
                
                clothingImageView.sd_setImage(with: clothingURL)
                clothingImageView.hideSkeleton()
            } catch APIError.payloadTooLarge {
                self.updatedImageID = nil
                self.clothingImageView.sd_setImage(with: URL(string: self.clothing.imageID, relativeTo: URL(string: "uploads/clothing_images/", relativeTo: APIClient.baseURL)))
                self.clothingImageView.hideSkeleton()
                
                picker.dismiss(animated: true) {
                    ErrorHandler.handle(APIError.payloadTooLargeWithMessage("The image background couldn't be removed.", suggestion: "Use a smaller image or a image with lower resolution."))                }
            } catch APIError.unprocessableContent {
                self.updatedImageID = nil
                self.clothingImageView.sd_setImage(with: URL(string: self.clothing.imageID, relativeTo: URL(string: "uploads/clothing_images/", relativeTo: APIClient.baseURL)))
                self.clothingImageView.hideSkeleton()
                
                picker.dismiss(animated: true) {
                    ErrorHandler.handle(APIError.unprocessableContentWithMessage("The image backround couldn't be removed.", suggestion: "Use a brighter enviroment and ensure a high contrast for the best results."))
                }
            } catch {
                self.updatedImageID = nil
                self.clothingImageView.sd_setImage(with: URL(string: self.clothing.imageID, relativeTo: URL(string: "uploads/clothing_images/", relativeTo: APIClient.baseURL)))
                self.clothingImageView.hideSkeleton()
                
                picker.dismiss(animated: true) {
                    ErrorHandler.handle(error)
                }
            }
        }
    }
}

extension ClothingDetailsController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return clothingTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        guard clothingTypes[row].contains("*") else {
            let label = UILabel()
            label.textAlignment = .center
            label.text = clothingTypes[row]
            label.font = UIFont.systemFont(ofSize: 22)

            return label
        }
        
        let splitter = UIView()
        splitter.backgroundColor = .lightGray
        splitter.frame = CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 2)
        return splitter
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var newText = clothingTypes[row]
        let previousIndex = clothingTypes.firstIndex(of: clothingTypeLabel.text ?? "") ?? 0
        
        if newText.contains("*") {
            pickerView.selectRow(row > previousIndex ? row - 1 : row + 1, inComponent: component, animated: true)
            newText = clothingTypes[row > previousIndex ? row - 1 : row + 1]
        }
        
        clothingTypeLabel.text = newText
        clothingTypeLabel.textColor = .label
    }
}

extension ClothingDetailsController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case clothingNameField.fieldInput:
            if string == "" { return true }
            
            guard clothingNameField.fieldInput.text?.count ?? 0 < 50 else { return false }
        default:
            return true
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

extension ClothingDetailsController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !isEditingClothing
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard checkChangesMade() else {
            dismiss(animated: true)
            return
        }
        
        let alert = UIAlertController(title: "Unsaved changes", message: "There are some unsaved changes", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Save and continue", style: .default, handler: { _ in
            self.finishEditing()
        }))
        
        alert.addAction(UIAlertAction(title: "Undo", style: .destructive, handler: { _ in
            self.clothingNameField.fieldInput.text = self.clothing.name
            self.clothingTypeLabel.text = self.clothing.category.localizedName
            self.selectedTagsArray = self.clothing.tags
            self.selectedSeasonsArray = self.clothing.seasons
            self.clothingColorButton.backgroundColor = self.clothing.color
            self.colorPickerView.selectedColor = self.clothing.color
            
            if self.updatedImageID != nil {
                self.updatedImageID = nil
                self.clothingImageView.sd_setImage(with: URL(string: self.clothing.imageID, relativeTo: APIClient.clothingImagesURL))
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Abort", style: .cancel, handler: { _ in
            return
        }))
        
        present(alert, animated: true)
    }
}

extension ClothingDetailsController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        clothingColorButton.backgroundColor = color
    }
}
