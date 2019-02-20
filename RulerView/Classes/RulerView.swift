//
//  RulerView.swift
//  RulerView
//
//  Created by qjshuai on 2017/5/31.
//  Copyright © 2017年 qjshuai. All rights reserved.
//

import UIKit

/// 绘制模式
///
/// - visiable: 实际宽度超过当前显示宽度时, 只绘制正在显示的部分, 每次滑动进行重绘
/// - whole: 无论实际宽度多长, 一次性绘制全部
enum RulerRenderMode: Int {
    case visiable
    case whole
}

enum RulerDirection: Int {
    case horizontal
    case vertical
}

enum RulerOrientation: Int {
    case `default` //→ ↑
    case reverse  // ← ↓
}

public typealias RulerSelectedAction = (_ value: CGFloat) -> Void

public class RulerView: UIView {

    public func setValue(_ value: CGFloat, animated: Bool) {
        var value = value
        if value < min {
            value = min
        }
        if value > max {
            value = max
        }
        let target = CGPoint(x: value / unit * CGFloat(unitWidth), y: 0)
        scrollView.setContentOffset(adjustedPoint(with: target), animated: animated)
    }

    public lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        return scrollView
    }()

    public let rulerContainerView = UIView()

    public let lineLayer = CAShapeLayer()

    public let pointer: UIImageView = {
        let imageView = UIImageView()
        imageView.image = imageWithName("pointer")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    public let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    public var rulerSelectedAction: RulerSelectedAction?

    ///默认不需要设置该值  如果需要自定义该值  则数量需要 == (max - min)/unit
    public var scaleIntervalTexts: [String] = []

    //指针偏移 默认zero
    public var pointerOffSet: CGPoint = .zero {
        didSet {
            //            pointerImageView.frame.origin =
        }
    }

    /// 指针尺寸 默认 30 10
    public var pointerSize: CGSize = .zero
    //    {
    //        didSet {
    //            pointer.frame.size = pointerSize
    //        }
    //    }

    /// 最小刻度值
    public var min: CGFloat = 0

    /// 最大刻度值 默认100
    public var max: CGFloat = 100

    /// 每个最小单元格的单位值 默认1
    public var unit: CGFloat = 0.1

    /// 可滚动的最小间距 默认1
    public var scrollableUnitCount: NSInteger = 5

    /// 每个单元格的宽度, 默认5 最小1
    public var unitWidth: Int = 10

    /// 是否显示刻度值 默认 true
    public var isShowScaleIntervalText: Bool = true

    /// 刻度值字体
    public var scaleIntervalFont: UIFont = .systemFont(ofSize: 12)

    /// 高亮显示字体的比例
    public var highlightedScale: CGFloat = 1.2

    /// 短刻度值线宽
    public var shortLineWidth: CGFloat = 0.5
    public var longLineWidth: CGFloat = 1.0
    public var mediumLineWidth: CGFloat = 1.0
    public var horizontalLineWidth: CGFloat = 1.0

    /// 长刻度值 长度占总体的比例
    public var longLineHeightScale: CGFloat = 0.5
    /// 中刻度值 长度占总体的比例
    public var mediumLineHeightScale: CGFloat = 0.375
    /// 短刻度值 长度占总体的比例
    public var shortLineHeightScale: CGFloat = 0.25

    /// 文字的颜色
    public var textColor: UIColor = .black

    /// 线的颜色
    public var lineColor: UIColor = .black {
        didSet {
            lineLayer.fillColor = lineColor.cgColor
        }
    }

    ///保留几位小数
    public var decimalPlace: Int = 0

    /// 绘制模式  暂未使用
    //    var renderMode: RulerRenderMode = .visiable

    //path 缓存计算  根据 间隔距离 高度  等等 判断是否相类似的view 暂未使用
    //    static var cache: [Any] = [] //根据id以及offset 缓存path

    private var textLayers: [CATextLayer] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    private func setup() {
        scrollView.decelerationRate = 0.5

        pointerSize = CGSize(width: 5, height: 15)
        addSubview(scrollView)
        addSubview(pointer)
        scrollView.addSubview(rulerContainerView)
        rulerContainerView.layer.addSublayer(lineLayer)

        do {
            pointer.translatesAutoresizingMaskIntoConstraints = false
            let centerX = NSLayoutConstraint(item: pointer, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: pointerOffSet.x)
            let bottom = NSLayoutConstraint(item: pointer, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: pointerOffSet.y)

            let width = NSLayoutConstraint(item: pointer, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: pointerSize.width)

            let height = NSLayoutConstraint(item: pointer, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: pointerSize.height)

            addConstraints([centerX, bottom, width, height])
        }

        do {
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            let top = NSLayoutConstraint(item: scrollView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
            let left = NSLayoutConstraint(item: scrollView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
            let bottom = NSLayoutConstraint(item: scrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: scrollView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)

            addConstraints([top, left, bottom, right])
        }
        redrawPath()
    }

    private var lineLayerHeight: CGFloat {
        return frame.height * 0.625
    }

    private var minValue: Int {
        return Int(min / unit)
    }

    private var maxValue: Int {
        return Int(max / unit)
    }

    private var unitCount: Int {
        return maxValue - minValue
    }

    public override func layoutSubviews() {
        super.layoutSubviews()


        let height = bounds.height
        let containerFrame = rulerContainerView.frame

        if containerFrame.height != height {
            let width = bounds.width
            let containerWidth = CGFloat(unitWidth * unitCount)

            scrollView.contentSize = CGSize(width: containerWidth + width, height: 0)
            rulerContainerView.frame = CGRect(x: width / 2, y: 0, width: containerWidth, height: height)
            lineLayer.frame = CGRect(x: 0, y: height - lineLayerHeight, width:  containerWidth, height: lineLayerHeight)
            redrawPath()
        }
    }

    //    var paths: [Any] = []//TODO  缓存路径 无需再次计算

    private func redrawPath() {

        let lineLayerHeight = self.lineLayerHeight
        let height = rulerContainerView.frame.height
        let width = rulerContainerView.frame.width

        if lineLayerHeight == 0 || width == 0 || height == 0{
            lineLayer.path = nil
            return
        }

        //绘制横线
        let horizontalFrame = CGRect(x: 0, y: lineLayerHeight - horizontalLineWidth, width: width, height: horizontalLineWidth)
        let path = UIBezierPath(rect: horizontalFrame)

        for i in 0...unitCount {

            let lineHeight: CGFloat
            let lineWidth: CGFloat
            if i % 10 == 0 {
                lineHeight = longLineHeightScale * height
                lineWidth = longLineWidth
            } else if i % 5 == 0 {
                lineHeight = mediumLineHeightScale * height
                lineWidth = mediumLineWidth
            } else {
                lineHeight = shortLineHeightScale * height
                lineWidth = shortLineWidth
            }
            let y = lineLayerHeight - lineHeight - horizontalLineWidth

            let x = CGFloat(i * unitWidth) - lineWidth / 2
            let rect = CGRect(x: x, y: y, width: lineWidth, height: lineHeight)
            let verticalLine = UIBezierPath(rect: rect)
            path.append(verticalLine)
        }

        lineLayer.path = path.cgPath

        redrawTexts()
    }

    private func redrawTexts() {
        guard isShowScaleIntervalText else {
            return
        }

        let longScaleCount = unitCount / 10 + 1 //需要显示文字的个数
        //自定义的text  如果没有  使用系统默认的
        if scaleIntervalTexts.count != 0 && scaleIntervalTexts.count < longScaleCount {
            assertionFailure("如果使用了自定义的刻度值文字, 传入的文字个数不能小于长刻度值的个数")
        }

        var texts = self.scaleIntervalTexts
        if texts.isEmpty {
            texts = (minValue...maxValue).filter{ $0 % 10 == 0}.map{ String(format: "%.\(decimalPlace)f", CGFloat($0) * unit) }
        }

        //绘制刻度值
        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: textColor,
                                                        .font: scaleIntervalFont]

        while textLayers.count > texts.count {
            let last = textLayers.removeLast()
            last.removeFromSuperlayer()
        }

        while textLayers.count < texts.count {
            let textLayer = CATextLayer()
            textLayer.alignmentMode = kCAAlignmentCenter
            rulerContainerView.layer.addSublayer(textLayer)
            textLayers.append(textLayer)
        }

        let width = rulerContainerView.frame.width / CGFloat(unitCount / 10) //等于一个单元格的宽度
        let height = rulerContainerView.frame.height * 0.4
        for (index, textLayer) in textLayers.enumerated() {
            textLayer.string = NSAttributedString(string: texts[index], attributes: attributes)
            textLayer.frame = CGRect(x: width * CGFloat(index) - width / 2, y: 0, width: width, height: height)
        }
    }

    //指针对应标尺中的位置
    private var poineterOriginInRuler: CGPoint {
        return convert(pointer.center, to: rulerContainerView)
    }

    //纠正偏移量后的点
    private func adjustedPoint(with point: CGPoint) -> CGPoint {
        let x = round(point.x)
        let scrollableWidth = unitWidth * scrollableUnitCount

        var deviation = CGFloat(Int(x) % (scrollableWidth))

        if deviation < CGFloat(scrollableWidth) / 2 {
            deviation = -deviation
        } else {
            deviation = CGFloat(scrollableWidth) - deviation
        }
        return CGPoint(x: x + deviation, y: point.y)
    }

    var selectedValue: CGFloat {
        return adjustedPoint(with: poineterOriginInRuler).x / CGFloat(unitWidth) * unit
    }

    private var lastValue: CGFloat?
}

extension RulerView: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if lastValue == selectedValue {
            return
        }
        lastValue = selectedValue
        rulerSelectedAction?(lastValue!)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetContentOffset.pointee = adjustedPoint(with: targetContentOffset.pointee)
    }
}

internal let bundle = Bundle(for: RulerView.self)

internal func imageWithName(_ name: String) -> UIImage {
    let image = UIImage(contentsOfFile: bundle.path(forResource: "RulerView.bundle/\(name)", ofType: "png")!)
    return image!
}

