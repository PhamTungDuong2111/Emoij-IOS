import Foundation
import CoreGraphics

/// Double exponential smoothing filter for face motion and facial expressions,
/// eliminating high frequency frame jitter while maintaining low latency responsiveness.
public class FaceSmoother {
    private var smoothedValues: [CGFloat]?
    private var trendValues: [CGFloat]?
    private var lastFrameNum: Int = 0

    // Alpha: smoothing factor (higher = more responsive, lower = smoother)
    // Beta: trend factor for velocity estimation
    private let alphaPos: CGFloat = 0.65
    private let betaPos: CGFloat = 0.25

    private let alphaAngle: CGFloat = 0.60
    private let betaAngle: CGFloat = 0.20

    private let alphaExpr: CGFloat = 0.70
    private let betaExpr: CGFloat = 0.20

    public init() {}

    public func smooth(
        cx: CGFloat, cy: CGFloat, w: CGFloat, h: CGFloat,
        pitch: CGFloat, yaw: CGFloat, roll: CGFloat,
        smile: CGFloat, leftEye: CGFloat, rightEye: CGFloat,
        mouthOpen: CGFloat, pucker: CGFloat,
        browFurrow: CGFloat, browRaise: CGFloat, mouthFrown: CGFloat,
        frameNum: Int
    ) -> [CGFloat] {
        let raw: [CGFloat] = [
            cx, cy, w, h,
            pitch, yaw, roll,
            smile, leftEye, rightEye,
            mouthOpen, pucker,
            browFurrow, browRaise, mouthFrown
        ]

        if smoothedValues == nil || frameNum - lastFrameNum > 15 {
            smoothedValues = raw
            trendValues = Array(repeating: 0, count: raw.count)
            lastFrameNum = frameNum
            return raw
        }

        var prevSmooth = smoothedValues!
        var prevTrend = trendValues!
        var nextSmooth = [CGFloat](repeating: 0, count: raw.count)
        var nextTrend = [CGFloat](repeating: 0, count: raw.count)

        for i in 0..<raw.count {
            let (alpha, beta): (CGFloat, CGFloat) = {
                if i < 4 {
                    return (alphaPos, betaPos)
                } else if i < 7 {
                    return (alphaAngle, betaAngle)
                } else {
                    return (alphaExpr, betaExpr)
                }
            }()

            let s = alpha * raw[i] + (1.0 - alpha) * (prevSmooth[i] + prevTrend[i])
            let b = beta * (s - prevSmooth[i]) + (1.0 - beta) * prevTrend[i]

            nextSmooth[i] = s
            nextTrend[i] = b
        }

        smoothedValues = nextSmooth
        trendValues = nextTrend
        lastFrameNum = frameNum

        return nextSmooth
    }

    public func reset() {
        smoothedValues = nil
        trendValues = nil
        lastFrameNum = 0
    }
}
