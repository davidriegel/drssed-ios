//
//  GridView.swift
//  Drssed
//
//  Created by David Riegel on 05.04.26.
//

import UIKit

class GridView: UIView {

    var numberOfColumns: Int = 10 {
        didSet { setNeedsLayout() }
    }

    var lineColor: UIColor = .darkGray {
        didSet { gridLayer.strokeColor = lineColor.cgColor }
    }

    var lineWidth: CGFloat = 0.5 {
        didSet { gridLayer.lineWidth = lineWidth }
    }

    private let gridLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        gridLayer.strokeColor = lineColor.cgColor
        gridLayer.lineWidth = lineWidth
        gridLayer.fillColor = nil
        layer.addSublayer(gridLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawGrid()
    }

    private func drawGrid() {
        guard numberOfColumns > 0 else { return }

        let path = UIBezierPath()

        let width = bounds.width
        let height = bounds.height

        let spacing = width / CGFloat(numberOfColumns)

        for i in 0...numberOfColumns {
            let x = CGFloat(i) * spacing
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
        }

        let numberOfRows = Int(floor(height / spacing))

        for i in 0...numberOfRows {
            let y = CGFloat(i) * spacing
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }

        if CGFloat(numberOfRows) * spacing < height {
            path.move(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: width, y: height))
        }

        gridLayer.path = path.cgPath
    }
}
