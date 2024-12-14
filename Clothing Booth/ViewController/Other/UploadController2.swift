//
//  UploadController.swift
//  Outfitter
//
//  Created by David Riegel on 09.05.24.
//

import UIKit
import SkeletonView
import SDWebImage

class UploadController2: UIViewController {
    
    var activeTextField: UITextField?
    let clothingType: [String] = ["clothing type", "hat/cap", "top", "bottom", "shoes"]
    var fileExtension: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        //NotificationCenter.default.addObserver(self, selector: #selector(UploadController2.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(UploadController2.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        configureViewComponents()
    }
    
    // MARK: --
    
    lazy var uploadImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isSkeletonable = true
        iv.skeletonCornerRadius = 12
        iv.image = UIImage(named: "upload_placeholder")
        iv.isUserInteractionEnabled = true
        iv.heightAnchor.constraint(equalToConstant: view.frame.width - (2 * (view.frame.width / 6))).isActive = true
        return iv
    }()
    
    lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        return picker
    }()
    
    // MARK: --
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "name"
        return label
    }()
    
    lazy var nameCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.text = "0/50"
        return label
    }()
    
    lazy var nameBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 16.88).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 16.88) / 4.16
        return view
    }()
    
    lazy var nameTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        tf.placeholder = "super cool name for your piece"
        tf.textColor = .label
        tf.textAlignment = .left
        tf.heightAnchor.constraint(equalToConstant: self.view.frame.height / 16.88).isActive = true
        tf.font = .systemFont(ofSize: 13, weight: .heavy)
        tf.returnKeyType = .done
        return tf
    }()
    
    // MARK: --
    
    lazy var brandLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "brand"
        return label
    }()
    
    lazy var brandBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 16.88).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 16.88) / 4.16
        return view
    }()
    
    lazy var brandTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        tf.placeholder = "the brand your piece is from"
        tf.textColor = .label
        tf.textAlignment = .left
        tf.heightAnchor.constraint(equalToConstant: self.view.frame.height / 16.88).isActive = true
        tf.font = .systemFont(ofSize: 13, weight: .heavy)
        tf.returnKeyType = .done
        return tf
    }()
    
    // MARK: --
    
    lazy var descLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "short description"
        return label
    }()
    
    lazy var descCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.text = "0/155"
        return label
    }()
    
    lazy var descBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 16.88).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 16.88) / 4.16
        return view
    }()
    
    lazy var descTextField: UITextField = {
        let tf = UITextField()
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        tf.placeholder = "optional short description of youre piece"
        tf.textColor = .label
        tf.textAlignment = .left
        tf.heightAnchor.constraint(equalToConstant: self.view.frame.height / 16.88).isActive = true
        tf.font = .systemFont(ofSize: 13, weight: .heavy)
        tf.returnKeyType = .done
        return tf
    }()
    
    // MARK: --
    
    lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = "type of clothing"
        return label
    }()
    
    lazy var typeBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.heightAnchor.constraint(equalToConstant: self.view.frame.height / 16.88).isActive = true
        view.layer.cornerRadius = (self.view.frame.height / 16.88) / 4.16
        return view
    }()
    
    lazy var typeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    lazy var typeIndidicatorImage: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .placeholderText))
        iv.contentMode = .scaleAspectFit
        iv.heightAnchor.constraint(equalToConstant: 3/6 * 50).isActive = true
        iv.widthAnchor.constraint(equalToConstant: 3/6 * 50).isActive = true
        return iv
    }()
    
    lazy var typeSelection: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textColor = .placeholderText
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 13, weight: .heavy)
        label.text = "clothing type"
        return label
    }()
    
    lazy var typePicker: UIPickerView = {
        let pv = UIPickerView()
        pv.isHidden = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.alpha = 0
        pv.backgroundColor = .secondarySystemBackground
        pv.autoresizingMask = .flexibleWidth
        pv.contentMode = .center
        return pv
    }()
    
    lazy var typePickerDone: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let title = NSAttributedString(string: "Done", attributes: [.font : UIFont.systemFont(ofSize: 18, weight: .bold)])
        button.isHidden = true
        button.alpha = 0
        button.setAttributedTitle(title, for: .normal)
        button.setTitleColor(.label, for: .normal)
        return button
    }()
    
    // MARK: --
    
    lazy var saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setAttributedTitle(NSAttributedString(string: "save piece", attributes: [.font : UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]), for: .normal)
        button.setTitleColor(.systemBackground, for: .normal)
        button.backgroundColor = .label
        button.heightAnchor.constraint(equalToConstant: 45).isActive = true
        button.widthAnchor.constraint(equalToConstant: self.view.frame.width / 2).isActive = true
        button.layer.cornerRadius = 45 / 5
        return button
    }()
    
    // MARK: -- objC functions
    
    @objc
    func cancelTapped() {
        tabBarController?.tabBar.isHidden = false
        navigationController?.popViewController(animated: true)
    }
    
    @objc
    func soon() {
        let infoAlert = UIAlertController(title: "🤫", message: "Pshhht! You've found a feature that is still work in progress...", preferredStyle: .alert)
        infoAlert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(infoAlert, animated: true)
    }

    @objc
    func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        guard activeTextField != nil else { return }
        
        let bottomOfTextField = activeTextField!.convert(activeTextField!.bounds, to: self.view).maxY
        let topOfKeyboard = self.view.frame.height - keyboardSize.height
        
        if bottomOfTextField > topOfKeyboard {
            self.view.frame.origin.y = keyboardSize.minY - bottomOfTextField - 25
        }
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
      self.view.frame.origin.y = 0
    }
    
    @objc
    func uploadImage() {
        let selectionAlert = UIAlertController(title: "Method", message: "Please select how you would prefer to upload your image.", preferredStyle: .alert)
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
        
        let bottomOfPickerButton = typeBackgroundView.convert(typeBackgroundView.bounds, to: view).maxY
        let topOfPicker = view.frame.height - typePicker.frame.height
        let heightDifferenceOfPickerButton = typeBackgroundView.convert(typeBackgroundView.bounds, to: typePicker).maxY
        
        typePicker.isHidden = false
        typePickerDone.isHidden = false
        
        UIView.animate(withDuration: 0.3) {
            if bottomOfPickerButton > topOfPicker {
                let topConstraint = self.uploadImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
                topConstraint!.constant = -heightDifferenceOfPickerButton
                self.uploadImageView.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
            self.typePicker.alpha = 1
            self.typePickerDone.alpha = 1
        }
    }
    
    @objc func hidePickerView() {
        UIView.animate(withDuration: 0.3) {
            let topConstraint = self.uploadImageView.constraintsAffectingLayout(for: .vertical).first { $0.firstAttribute == .top } // force unwrap needs to exist.
            topConstraint!.constant = 15
            self.uploadImageView.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.typePicker.alpha = 0
            self.typePickerDone.alpha = 0
        } completion: { _ in
            self.typePicker.isHidden = true
            self.typePickerDone.isHidden = true
        }
    }
    
    // MARK: -- View configuration
    
    func configureViewComponents() {
        view.backgroundColor = .systemBackground
        title = "Add piece to collection"
        
        tabBarController?.tabBar.isHidden = true
        
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.label, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "wand.and.stars", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))?.withTintColor(.label, renderingMode: .alwaysOriginal), style: .plain, target: self, action: #selector(soon))
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        view.addSubview(uploadImageView)
        uploadImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: view.frame.width / 6).isActive = true
        uploadImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15).isActive = true
        uploadImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -(view.frame.width / 6)).isActive = true
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(uploadImage))
        uploadImageView.addGestureRecognizer(imageTap)
        
        view.addSubview(nameLabel)
        nameLabel.topAnchor.constraint(equalTo: uploadImageView.bottomAnchor, constant: 15).isActive = true
        nameLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        
        view.addSubview(nameBackgroundView)
        nameBackgroundView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true
        nameBackgroundView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        nameBackgroundView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        
        nameBackgroundView.addSubview(nameCountLabel)
        nameCountLabel.bottomAnchor.constraint(equalTo: nameBackgroundView.bottomAnchor, constant: -5).isActive = true
        nameCountLabel.rightAnchor.constraint(equalTo: nameBackgroundView.rightAnchor, constant: -10).isActive = true
        
        nameBackgroundView.addSubview(nameTextField)
        nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5).isActive = true
        nameTextField.leftAnchor.constraint(equalTo: nameBackgroundView.leftAnchor, constant: 5).isActive = true
        nameTextField.rightAnchor.constraint(equalTo: nameBackgroundView.rightAnchor, constant: -5).isActive = true
        
        view.addSubview(brandLabel)
        brandLabel.topAnchor.constraint(equalTo: nameBackgroundView.bottomAnchor, constant: 15).isActive = true
        brandLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        brandLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        
        view.addSubview(brandBackgroundView)
        brandBackgroundView.topAnchor.constraint(equalTo: brandLabel.bottomAnchor, constant: 5).isActive = true
        brandBackgroundView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        brandBackgroundView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        
        brandBackgroundView.addSubview(brandTextField)
        brandTextField.topAnchor.constraint(equalTo: brandLabel.bottomAnchor, constant: 5).isActive = true
        brandTextField.leftAnchor.constraint(equalTo: brandBackgroundView.leftAnchor, constant: 5).isActive = true
        brandTextField.rightAnchor.constraint(equalTo: brandBackgroundView.rightAnchor, constant: -5).isActive = true
        
        view.addSubview(descLabel)
        descLabel.topAnchor.constraint(equalTo: brandBackgroundView.bottomAnchor, constant: 15).isActive = true
        descLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        descLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        
        view.addSubview(descBackgroundView)
        descBackgroundView.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 5).isActive = true
        descBackgroundView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        descBackgroundView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        
        descBackgroundView.addSubview(descCountLabel)
        descCountLabel.bottomAnchor.constraint(equalTo: descBackgroundView.bottomAnchor, constant: -5).isActive = true
        descCountLabel.rightAnchor.constraint(equalTo: descBackgroundView.rightAnchor, constant: -10).isActive = true
        
        descBackgroundView.addSubview(descTextField)
        descTextField.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 5).isActive = true
        descTextField.leftAnchor.constraint(equalTo: descBackgroundView.leftAnchor, constant: 5).isActive = true
        descTextField.rightAnchor.constraint(equalTo: descBackgroundView.rightAnchor, constant: -5).isActive = true
        
        view.addSubview(typeLabel)
        typeLabel.topAnchor.constraint(equalTo: descBackgroundView.bottomAnchor, constant: 15).isActive = true
        typeLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        typeLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        
        view.addSubview(typeBackgroundView)
        typeBackgroundView.topAnchor.constraint(equalTo: typeLabel.bottomAnchor, constant: 5).isActive = true
        typeBackgroundView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 25).isActive = true
        typeBackgroundView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -25).isActive = true
        
        typeBackgroundView.addSubview(typeIndidicatorImage)
        typeIndidicatorImage.rightAnchor.constraint(equalTo: typeBackgroundView.rightAnchor, constant: -15).isActive = true
        typeIndidicatorImage.centerYAnchor.constraint(equalTo: typeBackgroundView.centerYAnchor).isActive = true
        
        typeBackgroundView.addSubview(typeButton)
        typeButton.topAnchor.constraint(equalTo: typeBackgroundView.topAnchor).isActive = true
        typeButton.leftAnchor.constraint(equalTo: typeBackgroundView.leftAnchor).isActive = true
        typeButton.bottomAnchor.constraint(equalTo: typeBackgroundView.bottomAnchor).isActive = true
        typeButton.rightAnchor.constraint(equalTo: typeBackgroundView.rightAnchor).isActive = true
        typeButton.addTarget(self, action: #selector(showPickerView), for: .touchUpInside)
        
        typeBackgroundView.addSubview(typeSelection)
        typeSelection.leftAnchor.constraint(equalTo: typeBackgroundView.leftAnchor, constant: 5).isActive = true
        typeSelection.rightAnchor.constraint(equalTo: typeBackgroundView.rightAnchor, constant: -5).isActive = true
        typeSelection.centerYAnchor.constraint(equalTo: typeBackgroundView.centerYAnchor).isActive = true
        
        view.addSubview(typePicker)
        typePicker.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        typePicker.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
        typePicker.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        typePicker.delegate = self
        typePicker.dataSource = self
        typePicker.selectRow(0, inComponent: 0, animated: false)
        
        view.addSubview(typePickerDone)
        typePickerDone.topAnchor.constraint(equalTo: typePicker.topAnchor, constant: 10).isActive = true
        typePickerDone.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
        typePickerDone.addTarget(self, action: #selector(hidePickerView), for: .touchUpInside)
        
        view.addSubview(saveButton)
        saveButton.topAnchor.constraint(equalTo: typeBackgroundView.bottomAnchor, constant: 20).isActive = true
        saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
}

extension UploadController2: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        Task {
            dismiss(animated: true)
            
            guard let image = info[.editedImage] as? UIImage else { return }
            let assetPath = info[.imageURL] as! NSURL
            self.fileExtension = (assetPath.absoluteString ?? "").components(separatedBy: ".").last ?? ""
            
            guard ["png", "jpg", "jpeg"].contains(fileExtension) else {
                let alert = UIAlertController(title: "", message: "Unsupported file type for your profile picture. [\(fileExtension)]", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                    self.dismiss(animated: true)
                }))
                present(alert, animated: true)
                return
            }
            
            uploadImageView.showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: .skeletonColor), animation: GradientDirection.topLeftBottomRight.slidingAnimation(), transition: .crossDissolve(0.25))
            let clothingURL = try await APIHandler.shared.removeClothingBackground(from: image, self.fileExtension)
            uploadImageView.sd_setImage(with: clothingURL)
            uploadImageView.hideSkeleton()
        }
    }
}

extension UploadController2: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return clothingType.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return clothingType[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let newText = clothingType[row]
        typeSelection.text = newText
        
        guard row != 0 else { typeSelection.textColor = .placeholderText; return }
        typeSelection.textColor = .label
    }
}

extension UploadController2: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case nameTextField:
            if string == "" {
                nameCountLabel.text = "\((nameTextField.text?.count ?? 0) - 1)/50"
                return true
            }
            
            guard nameTextField.text?.count ?? 0 < 50 else { return false }
            
            nameCountLabel.text = "\((nameTextField.text?.count ?? 0) + 1)/50"
        case descTextField:
            if string == "" {
                descCountLabel.text = "\((descTextField.text?.count ?? 0) - 1)/155"
                return true
            }
            
            guard descTextField.text?.count ?? 0 < 155 else { return false }
            
            descCountLabel.text = "\((descTextField.text?.count ?? 0) + 1)/155"
        default:
            return true
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
      }
    
  func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
  }
}
