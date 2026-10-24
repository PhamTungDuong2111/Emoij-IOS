import UIKit
import SwiftUI

public class EmojiMaskUIView: UIView {
    public var maskType: EmojiMaskType = .grinning {
        didSet { setNeedsDisplay() }
    }
    public var isCutoutMode: Bool = true {
        didSet { setNeedsDisplay() }
    }
    public var faceStates: [FaceExpressionState] = [] {
        didSet { setNeedsDisplay() }
    }
    public var imageWidth: Int = 1080
    public var imageHeight: Int = 1920
    public var isFrontCamera: Bool = true

    private var displayLink: CADisplayLink?
    private var animationStartTime: CFTimeInterval = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw

        displayLink = CADisplayLink(target: self, selector: #selector(onDisplayFrame))
        displayLink?.add(to: .main, forMode: .common)
        animationStartTime = CACurrentMediaTime()
    }

    @objc private func onDisplayFrame() {
        setNeedsDisplay()
    }

    deinit {
        displayLink?.invalidate()
    }

    public func update(
        states: [FaceExpressionState],
        imgW: Int,
        imgH: Int,
        isFront: Bool
    ) {
        self.faceStates = states
        self.imageWidth = imgW
        self.imageHeight = imgH
        self.isFrontCamera = isFront
        setNeedsDisplay()
    }

    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)

        let elapsed = CGFloat(CACurrentMediaTime() - animationStartTime)
        let phase = (elapsed.truncatingRemainder(dividingBy: 1.2)) / 1.2

        let viewW = bounds.width
        let viewH = bounds.height
        if viewW <= 0 || viewH <= 0 { return }

        let scale = max(viewW / CGFloat(imageWidth), viewH / CGFloat(imageHeight))
        let offsetX = (viewW - CGFloat(imageWidth) * scale) / 2.0
        let offsetY = (viewH - CGFloat(imageHeight) * scale) / 2.0

        for state in faceStates {
            guard state.isFaceDetected else { continue }

            let mappedCenterX: CGFloat = isFrontCamera
                ? (viewW - (state.centerX * scale + offsetX))
                : (state.centerX * scale + offsetX)
            let mappedCenterY: CGFloat = state.centerY * scale + offsetY

            let faceDim = max(state.faceWidth, state.faceHeight)
            let radius = max(viewW * 0.18, (faceDim * scale) * 0.72)

            EmojiMaskRenderer.drawEmojiMask(
                in: context,
                cx: mappedCenterX,
                cy: mappedCenterY,
                radius: radius,
                state: state,
                maskType: maskType,
                isFrontCam: isFrontCamera,
                phase: phase,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                viewW: viewW,
                isCutoutMode: isCutoutMode
            )
        }
    }
}

// SwiftUI Representable
public struct EmojiMaskOverlayView: UIViewRepresentable {
    public let maskType: EmojiMaskType
    public let isCutoutMode: Bool
    public let faceStates: [FaceExpressionState]
    public let imageWidth: Int
    public let imageHeight: Int
    public let isFrontCamera: Bool

    public init(
        maskType: EmojiMaskType,
        isCutoutMode: Bool,
        faceStates: [FaceExpressionState],
        imageWidth: Int,
        imageHeight: Int,
        isFrontCamera: Bool
    ) {
        self.maskType = maskType
        self.isCutoutMode = isCutoutMode
        self.faceStates = faceStates
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.isFrontCamera = isFrontCamera
    }

    public func makeUIView(context: Context) -> EmojiMaskUIView {
        let view = EmojiMaskUIView()
        view.maskType = maskType
        view.isCutoutMode = isCutoutMode
        view.update(states: faceStates, imgW: imageWidth, imgH: imageHeight, isFront: isFrontCamera)
        return view
    }

    public func updateUIView(_ uiView: EmojiMaskUIView, context: Context) {
        uiView.maskType = maskType
        uiView.isCutoutMode = isCutoutMode
        uiView.update(states: faceStates, imgW: imageWidth, imgH: imageHeight, isFront: isFrontCamera)
    }
}
