//
//  SubCategoryFilterCell.swift
//  Drssed
//
//  Created by David Riegel on 29.06.26.
//

import UIKit

final class SubCategoryFilterCell: UICollectionViewCell {
    static let identifier = "SubCategoryFilterCell"
    static let font: UIFont = .systemFont(ofSize: 13, weight: .semibold)
    static let horizontalPadding: CGFloat = 14
    static let height: CGFloat = 32

    private let label: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.font = SubCategoryFilterCell.font
        lb.textAlignment = .center
        return lb
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerCurve = .continuous
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.horizontalPadding),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.horizontalPadding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }

    func configure(title: String, isSelected: Bool) {
        label.text = title
        label.textColor = isSelected ? .label : .secondaryLabel
        contentView.backgroundColor = isSelected ? .accent : .secondarySystemBackground
    }

    static func width(for title: String) -> CGFloat {
        let size = (title as NSString).size(withAttributes: [.font: font])
        return ceil(size.width) + horizontalPadding * 2
    }
}
