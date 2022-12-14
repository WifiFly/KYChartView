//
//  KYBarChartView.swift
//  KYChartView
//
//  Created by keyon on 2022/10/11.
//

import UIKit
import Combine

class KYBarChartView: KYChartBaseView {

    // MARK: public
    var chartData: KYBarChartDataSet? {
        didSet {
            calculateMinMaxX()
            calculateMinMaxY()
            setNeedsDisplay()
        }
    }

    private(set) var visibleRange: Range<Int> = .none {
        didSet {
            setNeedsDisplay()
        }
    }

    var renderer: KYBarChartRender?

    let config: KYBarChartConfig

    // MARK: private
    private(set) var contentOffset: CGPoint = .zero {
        didSet {
            calculateVisibleRange()
        }
    }

    private var highLights = [KYBarChartHighLight]() {
        didSet {
            setNeedsDisplay()
        }
    }

    private var lastContentOffset: CGPoint = .zero
    private var cancelAbles = Set<AnyCancellable>()
    private var _tapGestureRecognizer: UITapGestureRecognizer?
    private var _panGestureRecognizer: UIPanGestureRecognizer?
    private(set) var minX: Double = 0
    private(set) var maxX: Double = 0
    private(set) var minY: Double = 0
    private(set) var maxY: Double = 0

    init(config: KYBarChartConfig) {
        self.config = config
        super.init()
        renderer = KYBarChartRender(dataProvider: self)
        setup()
    }

    private func setup() {
        config.$spacing.combineLatest(config.$barWidth).sink { [weak self] _ in
            self?.setNeedsDisplay()
        }.store(in: &cancelAbles)
    }

    
    override func tapGestureRecognized(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            let point = recognizer.location(in: self)
            var highLights = [KYBarChartHighLight]()
            for i in visibleRange {
                let minX = config.thunkWidth * Double(i) - contentOffset.x
                let maxX = config.thunkWidth * Double(i) + config.barWidth - contentOffset.x
                if point.x >= minX && point.x <= maxX {
                    let highLight = KYBarChartHighLight(dataIndex: i)
                    highLights.append(highLight)
                }
            }
            self.highLights = highLights
        }
    }

    override func panGestureRecognized(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .changed {
            let originalTranslation = recognizer.translation(in: self)
            contentOffset.x = -originalTranslation.x + lastContentOffset.x
            if contentOffset.x <= minX {
                contentOffset.x = minX
            } else if contentOffset.x >= maxX {
                contentOffset.x = maxX
            }
        } else if recognizer.state == .ended {
            lastContentOffset = contentOffset
        }
    }

    override func longPressGestureRecognized(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .changed {
            let point = recognizer.location(in: self)
            var highLights = [KYBarChartHighLight]()
            for i in visibleRange {
                let minX = config.thunkWidth * Double(i) - contentOffset.x
                let maxX = config.thunkWidth * Double(i) + config.barWidth - contentOffset.x
                if point.x >= minX && point.x <= maxX {
                    let highLight = KYBarChartHighLight(dataIndex: i)
                    highLights.append(highLight)
                }
            }
            self.highLights = highLights
        }
    }

    override func notifyFrameChanged() {
        calculateMinMaxX()
        calculateVisibleRange()
    }

    private func notifyDataChanged() {
        setNeedsDisplay()
    }

    private func calculateVisibleRange() {
        guard let chartData = chartData else {
            visibleRange = .none
            return
        }
        let minX = contentOffset.x
        let maxX = minX + bounds.width
        let minIndex = min(chartData.data.count, max(0, Int(minX / config.thunkWidth)))
        let maxIndex = max(0, min(chartData.data.count, Int(maxX / config.thunkWidth) + 1))
        self.visibleRange = minIndex ..< maxIndex
    }

    private func calculateMinMaxX() {
        minX = 0
        // ??????????????????????????????,??????????????????
        maxX = config.thunkWidth * Double(chartData?.data.count ?? 0) - bounds.width - config.spacing
    }

    private func calculateMinMaxY() {
        let tmpMinY = ceil(chartData?.data.max(by: { $0.yVal > $1.yVal })?.yVal ?? 0)
        minY = tmpMinY < 0 ? tmpMinY : 0
        maxY = ceil(chartData?.data.max(by: { $0.yVal < $1.yVal })?.yVal ?? 0)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        guard let context = context else { return }

        context.setFillColor(UIColor.lightGray.cgColor)
        context.fill(rect)

        context.saveGState()
        renderer?.drawData(context: context)
        context.restoreGState()

        renderer?.drawHighlighted(context: context, indices: highLights)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
