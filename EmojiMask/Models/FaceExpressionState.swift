import Foundation
import CoreGraphics

public struct FaceExpressionState: Equatable {
    public var isFaceDetected: Bool
    public var trackingId: Int
    public var centerX: CGFloat
    public var centerY: CGFloat
    public var faceWidth: CGFloat
    public var faceHeight: CGFloat
    
    // 3D Head Orientation (Euler Angles in degrees)
    public var pitch: CGFloat
    public var yaw: CGFloat
    public var roll: CGFloat
    
    // Expression Ratios (0.0 to 1.0)
    public var smileRatio: CGFloat
    public var leftEyeOpenRatio: CGFloat
    public var rightEyeOpenRatio: CGFloat
    public var mouthOpenRatio: CGFloat
    public var mouthPuckerRatio: CGFloat
    public var browFurrowRatio: CGFloat
    public var eyebrowsRaisedRatio: CGFloat
    public var mouthFrownRatio: CGFloat
    
    // 2D Contour Landmarks (Coordinates in Image Space)
    public var faceContour: [CGPoint]
    public var leftEyeContour: [CGPoint]
    public var rightEyeContour: [CGPoint]
    public var upperLipTop: [CGPoint]
    public var upperLipBottom: [CGPoint]
    public var lowerLipTop: [CGPoint]
    public var lowerLipBottom: [CGPoint]
    public var noseBridge: [CGPoint]
    public var noseBottom: [CGPoint]

    public init(
        isFaceDetected: Bool = false,
        trackingId: Int = 0,
        centerX: CGFloat = 0,
        centerY: CGFloat = 0,
        faceWidth: CGFloat = 0,
        faceHeight: CGFloat = 0,
        pitch: CGFloat = 0,
        yaw: CGFloat = 0,
        roll: CGFloat = 0,
        smileRatio: CGFloat = 0,
        leftEyeOpenRatio: CGFloat = 1,
        rightEyeOpenRatio: CGFloat = 1,
        mouthOpenRatio: CGFloat = 0,
        mouthPuckerRatio: CGFloat = 0,
        browFurrowRatio: CGFloat = 0,
        eyebrowsRaisedRatio: CGFloat = 0,
        mouthFrownRatio: CGFloat = 0,
        faceContour: [CGPoint] = [],
        leftEyeContour: [CGPoint] = [],
        rightEyeContour: [CGPoint] = [],
        upperLipTop: [CGPoint] = [],
        upperLipBottom: [CGPoint] = [],
        lowerLipTop: [CGPoint] = [],
        lowerLipBottom: [CGPoint] = [],
        noseBridge: [CGPoint] = [],
        noseBottom: [CGPoint] = []
    ) {
        self.isFaceDetected = isFaceDetected
        self.trackingId = trackingId
        self.centerX = centerX
        self.centerY = centerY
        self.faceWidth = faceWidth
        self.faceHeight = faceHeight
        self.pitch = pitch
        self.yaw = yaw
        self.roll = roll
        self.smileRatio = smileRatio
        self.leftEyeOpenRatio = leftEyeOpenRatio
        self.rightEyeOpenRatio = rightEyeOpenRatio
        self.mouthOpenRatio = mouthOpenRatio
        self.mouthPuckerRatio = mouthPuckerRatio
        self.browFurrowRatio = browFurrowRatio
        self.eyebrowsRaisedRatio = eyebrowsRaisedRatio
        self.mouthFrownRatio = mouthFrownRatio
        self.faceContour = faceContour
        self.leftEyeContour = leftEyeContour
        self.rightEyeContour = rightEyeContour
        self.upperLipTop = upperLipTop
        self.upperLipBottom = upperLipBottom
        self.lowerLipTop = lowerLipTop
        self.lowerLipBottom = lowerLipBottom
        self.noseBridge = noseBridge
        self.noseBottom = noseBottom
    }

    public func getDetectedEmotionKey() -> String {
        if smileRatio > 0.65 {
            return "expr_laughing"
        } else if smileRatio > 0.35 {
            return "expr_smiling"
        } else if mouthPuckerRatio > 0.40 {
            return "expr_kissing"
        } else if mouthOpenRatio > 0.45 {
            return "expr_mouth_open"
        } else if browFurrowRatio > 0.40 || mouthFrownRatio > 0.35 {
            return "expr_frowning"
        } else if eyebrowsRaisedRatio > 0.45 {
            return "expr_surprised"
        } else if leftEyeOpenRatio < 0.30 && rightEyeOpenRatio > 0.60 {
            return "expr_winking_left"
        } else if rightEyeOpenRatio < 0.30 && leftEyeOpenRatio > 0.60 {
            return "expr_winking_right"
        } else if leftEyeOpenRatio < 0.30 && rightEyeOpenRatio < 0.30 {
            return "expr_eyes_closed"
        } else {
            return "expr_neutral"
        }
    }
}
