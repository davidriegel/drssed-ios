//
//  WearEditorController.swift
//  Drssed
//
//  Created by David Riegel on 27.07.26.
//

import UIKit

protocol WearEditorDelegate: AnyObject {
    func wearEditor(_ controller: WearEditorController, didSave wear: OutfitWear)
    func wearEditor(_ controller: WearEditorController, didDelete wearID: String)
}

/// Sheet to log a new wear of an outfit or to edit an existing one.
final class WearEditorController: UIViewController {
    enum Mode {
        case create(outfitID: String)
        case edit(OutfitWear)
    }

    private let mode: Mode
    private let wearRepo: WearRepository = AppRepository.shared.wearRepository

    weak var delegate: WearEditorDelegate?

    // MARK: - Draft state -

    private var wornOn: Date {
        didSet { updateSaveButtonState() }
    }
    private var weather: WeatherCondition? {
        didSet { updateWeatherField(); updateSaveButtonState() }
    }
    private var occasion: WearOccasion? {
        didSet { updateOccasionField(); updateSaveButtonState() }
    }
    private var rating: Int? {
        didSet { updateRatingButtons(); updateSaveButtonState() }
    }

    private var originalWear: OutfitWear? {
        if case .edit(let wear) = mode { return wear }
        return nil
    }

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create:
            self.wornOn = Date()
        case .edit(let wear):
            self.wornOn = wear.wornOn
            self.weather = wear.weather
            self.occasion = wear.occasion
            self.rating = wear.rating
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()
        updateUIFromDraft()

        if case .create = mode {
            Task { await prefillWeather() }
        }
    }

    // MARK: - UI Elements -

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: UIFont.systemFontSize, weight: .black)
        label.text = originalWear == nil
            ? String(localized: "wear.editor.title.new")
            : String(localized: "wear.editor.title.edit")
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.text = String(localized: "wear.editor.subtitle")
        return label
    }()

    private lazy var cancelButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle(String(localized: "common.cancel"), for: .normal)
        bt.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        bt.setTitleColor(.accent, for: .normal)
        return bt
    }()

    private lazy var saveButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }

            Task { await self.save() }
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle(String(localized: "common.save"), for: .normal)
        bt.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        bt.setTitleColor(.accent, for: .normal)
        bt.setTitleColor(.lightGray, for: .disabled)
        return bt
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.keyboardDismissMode = .interactive
        return sv
    }()

    private lazy var contentStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 15
        sv.alignment = .fill
        return sv
    }()

    // Worn on

    private lazy var wornOnTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = String(localized: "wear.field.date")
        return label
    }()

    private lazy var wornOnPicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.maximumDate = Date()
        picker.tintColor = .accent
        picker.addAction(UIAction { [weak self] _ in
            guard let self else { return }

            self.wornOn = self.wornOnPicker.date
        }, for: .valueChanged)
        return picker
    }()

    // Weather

    private lazy var weatherField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "wear.field.weather"))
        view.fieldInput.setTitleColor(.label, for: .normal)
        view.fieldInput.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        view.fieldInput.showsMenuAsPrimaryAction = true
        return view
    }()

    // Occasion

    private lazy var occasionField: CustomButtonInput = {
        let view = CustomButtonInput(fieldTitle: String(localized: "wear.field.occasion"))
        view.fieldInput.setTitleColor(.label, for: .normal)
        view.fieldInput.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        view.fieldInput.showsMenuAsPrimaryAction = true
        return view
    }()

    // Temperatures

    private lazy var temperatureField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(
            fieldTitle: String(localized: "wear.field.temperature"),
            placeholder: String(localized: "wear.placeholder.temperature"),
            text: Self.temperatureText(for: originalWear?.temperature)
        )
        view.fieldInput.keyboardType = .numbersAndPunctuation
        view.fieldInput.delegate = self
        view.fieldInput.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return view
    }()

    private lazy var feelsLikeField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(
            fieldTitle: String(localized: "wear.field.feelsLike"),
            placeholder: String(localized: "wear.placeholder.temperature"),
            text: Self.temperatureText(for: originalWear?.feelsLike)
        )
        view.fieldInput.keyboardType = .numbersAndPunctuation
        view.fieldInput.delegate = self
        view.fieldInput.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return view
    }()

    // Rating

    private lazy var ratingTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.font = .systemFont(ofSize: 12, weight: .black)
        label.text = String(localized: "wear.field.rating")
        return label
    }()

    private lazy var ratingButtons: [UIButton] = (1...5).map { value in
        let bt = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            guard let self else { return }

            // Tapping the active star again clears the rating.
            self.rating = (self.rating == value) ? nil : value
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.tintColor = .accent
        bt.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return bt
    }

    // Note

    private lazy var noteField: CustomTextFieldInput = {
        let view = CustomTextFieldInput(
            fieldTitle: String(localized: "wear.field.note"),
            placeholder: String(localized: "wear.placeholder.note"),
            text: originalWear?.note,
            charCounterWithCharacters: Self.maxNoteLength
        )
        view.fieldInput.delegate = self
        view.fieldInput.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return view
    }()

    // Weather source

    private lazy var weatherSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = .secondaryLabel
        return spinner
    }()

    /// Apple requires the trademark and a link to the legal page wherever WeatherKit data shows up.
    private lazy var weatherAttributionButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { _ in
            guard let url = URL(string: "https://weatherkit.apple.com/legal-attribution.html") else { return }
            UIApplication.shared.open(url)
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle("\u{F8FF} Weather", for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        bt.setTitleColor(.tertiaryLabel, for: .normal)
        bt.contentHorizontalAlignment = .leading
        return bt
    }()

    // Delete

    private lazy var deleteButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            self?.promptDelete()
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle(String(localized: "wear.action.remove"), for: .normal)
        bt.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        bt.setTitleColor(.systemRed, for: .normal)
        bt.isHidden = originalWear == nil
        return bt
    }()

    // MARK: - Constants -

    private static let maxNoteLength: Int = 255
    private static let minTemperature: Double = -100
    private static let maxTemperature: Double = 100

    // MARK: - Functions -

    private static func temperatureText(for value: Double?) -> String? {
        guard let value else { return nil }
        return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }

    /// Parsed temperature of a field: `.some(nil)` for an empty field, `nil` for invalid input.
    private func temperature(from field: CustomTextFieldInput) -> Double?? {
        let text = (field.fieldInput.text ?? "").trimmingCharacters(in: .whitespaces)

        guard !text.isEmpty else { return .some(nil) }

        guard let value = Double(text.replacingOccurrences(of: ",", with: ".")),
              Self.minTemperature...Self.maxTemperature ~= value else {
            return nil
        }

        return .some(value)
    }

    private var note: String? {
        let text = (noteField.fieldInput.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    @objc
    private func textFieldDidChange() {
        updateSaveButtonState()
    }

    /// Fills weather, temperature and feels-like from WeatherKit, but never overwrites
    /// anything the user has already picked or typed while it was loading.
    private func prefillWeather() async {
        weatherSpinner.startAnimating()

        let snapshot = await WeatherProvider.shared.currentWeather()

        weatherSpinner.stopAnimating()

        guard let snapshot else { return }

        if weather == nil {
            weather = snapshot.condition
        }

        if (temperatureField.fieldInput.text ?? "").isEmpty {
            temperatureField.fieldInput.text = Self.temperatureText(for: snapshot.temperature)
        }

        if (feelsLikeField.fieldInput.text ?? "").isEmpty {
            feelsLikeField.fieldInput.text = Self.temperatureText(for: snapshot.feelsLike)
        }

        updateSaveButtonState()
    }

    private func hasChanges() -> Bool {
        guard let original = originalWear else { return true }

        return original.wornOn != wornOn
            || original.weather != weather
            || original.occasion != occasion
            || original.rating != rating
            || original.note != note
            || original.temperature != (temperature(from: temperatureField) ?? original.temperature)
            || original.feelsLike != (temperature(from: feelsLikeField) ?? original.feelsLike)
    }

    private func updateSaveButtonState() {
        saveButton.isEnabled = hasChanges()
    }

    private func save() async {
        guard let parsedTemperature = temperature(from: temperatureField),
              let parsedFeelsLike = temperature(from: feelsLikeField) else {
            presentInvalidTemperature()
            return
        }

        let saved: OutfitWear?

        switch mode {
        case .create(let outfitID):
            saved = await wearRepo.logWear(
                outfitID: outfitID,
                wornOn: wornOn,
                feelsLike: parsedFeelsLike,
                temperature: parsedTemperature,
                weather: weather,
                occasion: occasion,
                rating: rating,
                note: note
            )
        case .edit(let original):
            var updated = original
            updated.wornOn = wornOn
            updated.feelsLike = parsedFeelsLike
            updated.temperature = parsedTemperature
            updated.weather = weather
            updated.occasion = occasion
            updated.rating = rating
            updated.note = note

            saved = await wearRepo.updateWear(from: original, to: updated)
        }

        guard let saved else { return }

        await MainActor.run {
            self.delegate?.wearEditor(self, didSave: saved)
            self.dismiss(animated: true)
        }
    }

    private func promptDelete() {
        guard let wear = originalWear else { return }

        let alert = UIAlertController(
            title: String(localized: "wear.remove.title"),
            message: String(localized: "wear.remove.question"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))

        alert.addAction(UIAlertAction(title: String(localized: "common.delete"), style: .destructive, handler: { _ in
            Task {
                guard await self.wearRepo.deleteWear(with: wear.id) else { return }

                await MainActor.run {
                    self.delegate?.wearEditor(self, didDelete: wear.id)
                    self.dismiss(animated: true)
                }
            }
        }))

        present(alert, animated: true)
    }

    private func presentInvalidTemperature() {
        let alert = UIAlertController(
            title: String(localized: "wear.temperature.invalid.title"),
            message: String(localized: "wear.temperature.invalid.message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: "common.ok"), style: .default))

        present(alert, animated: true)
    }

    // MARK: - UI updates -

    private func updateUIFromDraft() {
        wornOnPicker.date = wornOn
        updateWeatherField()
        updateOccasionField()
        updateRatingButtons()
        updateSaveButtonState()
    }

    private func updateWeatherField() {
        weatherField.fieldInput.setTitle(weather?.localizedName ?? String(localized: "common.none"), for: .normal)
        weatherField.fieldInput.menu = weatherMenu()
    }

    private func updateOccasionField() {
        occasionField.fieldInput.setTitle(occasion?.localizedName ?? String(localized: "common.none"), for: .normal)
        occasionField.fieldInput.menu = occasionMenu()
    }

    private func updateRatingButtons() {
        for (index, button) in ratingButtons.enumerated() {
            let isFilled = index < (rating ?? 0)
            button.setImage(
                UIImage(systemName: isFilled ? "star.fill" : "star", withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title3))),
                for: .normal
            )
        }
    }

    private func weatherMenu() -> UIMenu {
        var items: [UIAction] = [
            UIAction(title: String(localized: "common.none"), state: weather == nil ? .on : .off, handler: { [weak self] _ in
                guard let self else { return }

                self.weather = nil
            })
        ]

        items += WeatherCondition.allCases.map { condition in
            UIAction(
                title: condition.localizedName,
                image: UIImage(systemName: condition.symbolName),
                state: weather == condition ? .on : .off,
                handler: { [weak self] _ in self?.weather = condition }
            )
        }

        return UIMenu(title: String(localized: "wear.field.weather"), children: items)
    }

    private func occasionMenu() -> UIMenu {
        var items: [UIAction] = [
            UIAction(title: String(localized: "common.none"), state: occasion == nil ? .on : .off, handler: { [weak self] _ in
                guard let self else { return }

                self.occasion = nil
            })
        ]

        items += WearOccasion.allCases.map { wearOccasion in
            UIAction(
                title: wearOccasion.localizedName,
                image: UIImage(systemName: wearOccasion.symbolName),
                state: occasion == wearOccasion ? .on : .off,
                handler: { [weak self] _ in self?.occasion = wearOccasion }
            )
        }

        return UIMenu(title: String(localized: "wear.field.occasion"), children: items)
    }

    // MARK: - Layout -

    private func configureViewComponents() {
        view.backgroundColor = .background

        [titleLabel, subtitleLabel, cancelButton, saveButton, scrollView, weatherSpinner].forEach { view.addSubview($0) }
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            weatherSpinner.centerYAnchor.constraint(equalTo: subtitleLabel.centerYAnchor),
            weatherSpinner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            saveButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20)
        ])

        contentStack.addArrangedSubview(makeWornOnRow())

        let temperatureStack = UIStackView(arrangedSubviews: [temperatureField, feelsLikeField])
        temperatureStack.axis = .horizontal
        temperatureStack.distribution = .fillEqually
        temperatureStack.spacing = 10

        [weatherField, occasionField].forEach { field in
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 65).isActive = true
        }

        [temperatureField, feelsLikeField, noteField].forEach { field in
            field.heightAnchor.constraint(greaterThanOrEqualToConstant: 65).isActive = true
        }

        let pickerStack = UIStackView(arrangedSubviews: [weatherField, occasionField])
        pickerStack.axis = .horizontal
        pickerStack.distribution = .fillEqually
        pickerStack.spacing = 10

        contentStack.addArrangedSubview(pickerStack)
        contentStack.addArrangedSubview(temperatureStack)
        contentStack.addArrangedSubview(weatherAttributionButton)
        contentStack.addArrangedSubview(makeRatingRow())
        contentStack.addArrangedSubview(noteField)
        contentStack.addArrangedSubview(deleteButton)

        contentStack.setCustomSpacing(4, after: temperatureStack)
    }

    private func makeWornOnRow() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(wornOnTitleLabel)
        container.addSubview(wornOnPicker)

        NSLayoutConstraint.activate([
            wornOnTitleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            wornOnTitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            wornOnPicker.topAnchor.constraint(equalTo: wornOnTitleLabel.bottomAnchor, constant: 5),
            wornOnPicker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            wornOnPicker.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private func makeRatingRow() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(ratingTitleLabel)

        let starStack = UIStackView(arrangedSubviews: ratingButtons)
        starStack.translatesAutoresizingMaskIntoConstraints = false
        starStack.axis = .horizontal
        starStack.distribution = .fillEqually
        starStack.alignment = .center
        starStack.spacing = 5
        container.addSubview(starStack)

        NSLayoutConstraint.activate([
            ratingTitleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            ratingTitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            starStack.topAnchor.constraint(equalTo: ratingTitleLabel.bottomAnchor, constant: 5),
            starStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            starStack.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.6),
            starStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }
}

extension WearEditorController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == noteField.fieldInput else { return true }

        let current = textField.text ?? ""
        guard let stringRange = Range(range, in: current) else { return false }

        return current.replacingCharacters(in: stringRange, with: string).count <= Self.maxNoteLength
    }
}
