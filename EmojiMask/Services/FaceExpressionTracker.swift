import Foundation
import CoreGraphics
import Vision
import AVFoundation

public class FaceExpressionTracker {
    public var isFrontCamera: Bool = true
    private var frameNum: Int = 0
    private var sequenceHandler = VNSequenceRequestHandler()
    private var smoothers: [Int: FaceSmoother] = [:]

    public init() {}

    public func processPixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation,
        completion: @escaping ([FaceExpressionState], Int, Int, Bool) -> Void
    ) {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        let request = VNDetectFaceLandmarksRequest { [weak self] req, error in
            guard let self = self, error == nil,
                  let observations = req.results as? [VNFaceObservation] else {
                completion([], width, height, self?.isFrontCamera ?? true)
                return
            }

            self.frameNum += 1
            var states: [FaceExpressionState] = []

            for (index, face) in observations.enumerated() {
                let state = self.extractFaceState(
                    face: face,
                    imageWidth: CGFloat(width),
                    imageHeight: CGFloat(height),
                    trackingId: index + 1
                )
                states.append(state)
            }

            completion(states, width, height, self.isFrontCamera)
        }

        do {
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: orientation)
        } catch {
            completion([], width, height, isFrontCamera)
        }
    }

    private func extractFaceState(
        face: VNFaceObservation,
        imageWidth: CGFloat,
        imageHeight: CGFloat,
        trackingId: Int
    ) -> FaceExpressionState {
        // Vision coordinates: (0,0) is bottom-left, normalized 0..1
        let bb = face.boundingBox
        let rawCenterX = (bb.origin.x + bb.size.width / 2.0) * imageWidth
        // Invert Y so (0,0) is top-left
        let rawCenterY = (1.0 - (bb.origin.y + bb.size.height / 2.0)) * imageHeight
        let rawWidth = bb.size.width * imageWidth
        let rawHeight = bb.size.height * imageHeight

        // Head Angles
        let rawRoll = CGFloat(face.roll?.doubleValue ?? 0.0) * (180.0 / .pi)
        let rawYaw = CGFloat(face.yaw?.doubleValue ?? 0.0) * (180.0 / .pi)
        let rawPitch = CGFloat(face.pitch?.doubleValue ?? 0.0) * (180.0 / .pi)

        // Helper to convert normalized Vision landmark points to image pixel space (top-left origin)
        func convertPoints(_ points: [CGPoint]?) -> [CGPoint] {
            guard let pts = points, !pts.isEmpty else { return [] }
            return pts.map { p in
                let absX = (bb.origin.x + p.x * bb.size.width) * imageWidth
                let absY = (1.0 - (bb.origin.y + p.y * bb.size.height)) * imageHeight
                return CGPoint(x: absX, y: absY)
            }
        }

        let faceContour = convertPoints(face.landmarks?.faceContour?.normalizedPoints)
        let leftEyeContour = convertPoints(face.landmarks?.leftEye?.normalizedPoints)
        let rightEyeContour = convertPoints(face.landmarks?.rightEye?.normalizedPoints)
        let outerLips = convertPoints(face.landmarks?.outerLips?.normalizedPoints)
        let innerLips = convertPoints(face.landmarks?.innerLips?.normalizedPoints)
        let leftEyebrow = convertPoints(face.landmarks?.leftEyebrow?.normalizedPoints)
        let rightEyebrow = convertPoints(face.landmarks?.rightEyebrow?.normalizedPoints)
        let noseBridge = convertPoints(face.landmarks?.noseCrest?.normalizedPoints)
        let noseBottom = convertPoints(face.landmarks?.nose?.normalizedPoints)

        // 1. EYE OPENING PROBABILITY (EAR: Eye Aspect Ratio)
        func calculateEAR(_ pts: [CGPoint]) -> CGFloat {
            guard pts.count >= 6 else { return 1.0 }
            let minX = pts.map { $0.x }.min() ?? 0
            let maxX = pts.map { $0.x }.max() ?? 1
            let minY = pts.map { $0.y }.min() ?? 0
            let maxY = pts.map { $0.y }.max() ?? 1
            let w = max(1.0, maxX - minX)
            let h = max(0.0, maxY - minY)
            let ear = h / w
            return max(0.0, min(1.0, (ear - 0.14) / 0.15))
        }

        let rawLeftEye = calculateEAR(leftEyeContour)
        let rawRightEye = calculateEAR(rightEyeContour)

        // 2. MOUTH OPENING RATIO (Vertical separation of inner lips)
        var rawMouthOpen: CGFloat = 0.0
        if innerLips.count >= 6 {
            let minY = innerLips.map { $0.y }.min() ?? 0
            let maxY = innerLips.map { $0.y }.max() ?? 0
            let verticalGap = max(0.0, maxY - minY)
            let normGap = verticalGap / max(1.0, rawHeight * 0.14)
            rawMouthOpen = max(0.0, min(1.0, normGap))
        }

        // 3. SMILE RATIO
        var rawSmile: CGFloat = 0.0
        if outerLips.count >= 8 {
            let sortedX = outerLips.sorted { $0.x < $1.x }
            let leftCorner = sortedX.first!
            let rightCorner = sortedX.last!
            let mouthWidth = max(1.0, rightCorner.x - leftCorner.x)
            let cornerAvgY = (leftCorner.y + rightCorner.y) / 2.0

            let midLipsY = outerLips.map { $0.y }.reduce(0, +) / CGFloat(outerLips.count)
            // When smiling, corners go UP (so cornerAvgY < midLipsY in top-down coordinates)
            let lift = (midLipsY - cornerAvgY) / max(1.0, rawHeight * 0.06)
            let widthRatio = (mouthWidth / max(1.0, rawWidth) - 0.38) / 0.15
            rawSmile = max(0.0, min(1.0, (lift * 0.65 + widthRatio * 0.35)))
        }

        // 4. MOUTH PUCKER (Kissing - 😘)
        var rawPucker: CGFloat = 0.0
        if outerLips.count >= 6 {
            let minX = outerLips.map { $0.x }.min() ?? 0
            let maxX = outerLips.map { $0.x }.max() ?? 1
            let minY = outerLips.map { $0.y }.min() ?? 0
            let maxY = outerLips.map { $0.y }.max() ?? 1
            let mw = max(1.0, maxX - minX)
            let mh = max(1.0, maxY - minY)
            let widthRatio = mw / max(1.0, rawWidth)
            let aspect = mw / mh

            let puckerFromWidth = max(0.0, min(1.0, (0.36 - widthRatio) / 0.12))
            let puckerFromAspect = max(0.0, min(1.0, (2.6 - aspect) / 1.2))

            if rawSmile < 0.35 && rawMouthOpen < 0.35 {
                rawPucker = max(puckerFromWidth, (puckerFromWidth * 0.5 + puckerFromAspect * 0.5))
            }
        }

        // 5. BROW FURROW (Angry - 😡) & BROW RAISE (Surprised - 😲)
        var rawBrowFurrow: CGFloat = 0.0
        var rawBrowRaise: CGFloat = 0.0
        if !leftEyebrow.isEmpty && !rightEyebrow.isEmpty {
            let leftInner = leftEyebrow.min(by: { abs($0.x - rawCenterX) < abs($1.x - rawCenterX) }) ?? leftEyebrow.last!
            let rightInner = rightEyebrow.min(by: { abs($0.x - rawCenterX) < abs($1.x - rawCenterX) }) ?? rightEyebrow.first!

            let innerDist = hypot(rightInner.x - leftInner.x, rightInner.y - leftInner.y)
            let normDist = innerDist / max(1.0, rawWidth)

            if normDist < 0.19 {
                rawBrowFurrow = max(0.0, min(1.0, (0.19 - normDist) / 0.08))
            }

            if !leftEyeContour.isEmpty && !rightEyeContour.isEmpty {
                let leftEyeY = leftEyeContour.map { $0.y }.reduce(0, +) / CGFloat(leftEyeContour.count)
                let rightEyeY = rightEyeContour.map { $0.y }.reduce(0, +) / CGFloat(rightEyeContour.count)
                let leftBrowY = leftEyebrow.map { $0.y }.reduce(0, +) / CGFloat(leftEyebrow.count)
                let rightBrowY = rightEyebrow.map { $0.y }.reduce(0, +) / CGFloat(rightEyebrow.count)

                let browEyeDist = ((leftEyeY - leftBrowY) + (rightEyeY - rightBrowY)) / 2.0
                let normBrowHeight = browEyeDist / max(1.0, rawHeight)

                if normBrowHeight > 0.16 && rawBrowFurrow < 0.20 {
                    rawBrowRaise = max(0.0, min(1.0, (normBrowHeight - 0.16) / 0.06))
                }
            }
        }

        // 6. MOUTH FROWN (Mép miệng cụp xuống - ☹️)
        var rawMouthFrown: CGFloat = 0.0
        if outerLips.count >= 8 && rawSmile < 0.25 {
            let sortedX = outerLips.sorted { $0.x < $1.x }
            let leftCorner = sortedX.first!
            let rightCorner = sortedX.last!
            let minY = outerLips.map { $0.y }.min() ?? 0
            let cornerAvgY = (leftCorner.y + rightCorner.y) / 2.0

            let cornerDrop = (cornerAvgY - minY) / max(1.0, rawHeight)
            if cornerDrop > 0.025 {
                rawMouthFrown = max(0.0, min(1.0, (cornerDrop - 0.025) / 0.035))
            }
        }

        // Split lips into upper and lower contours
        var upperLipTop = outerLips
        var upperLipBottom = innerLips
        var lowerLipTop = innerLips
        var lowerLipBottom = outerLips

        if outerLips.count >= 6 {
            let midIndex = outerLips.count / 2
            upperLipTop = Array(outerLips.prefix(midIndex))
            lowerLipBottom = Array(outerLips.suffix(outerLips.count - midIndex))
        }

        // Temporal Smoothing
        let smoother = smoothers[trackingId] ?? {
            let s = FaceSmoother()
            smoothers[trackingId] = s
            return s
        }()

        let smoothed = smoother.smooth(
            cx: rawCenterX, cy: rawCenterY, w: rawWidth, h: rawHeight,
            pitch: rawPitch, yaw: rawYaw, roll: rawRoll,
            smile: rawSmile, leftEye: rawLeftEye, rightEye: rawRightEye,
            mouthOpen: rawMouthOpen, pucker: rawPucker,
            browFurrow: rawBrowFurrow, browRaise: rawBrowRaise, mouthFrown: rawMouthFrown,
            frameNum: frameNum
        )

        return FaceExpressionState(
            isFaceDetected: true,
            trackingId: trackingId,
            centerX: smoothed[0],
            centerY: smoothed[1],
            faceWidth: smoothed[2],
            faceHeight: smoothed[3],
            pitch: smoothed[4],
            yaw: smoothed[5],
            roll: smoothed[6],
            smileRatio: smoothed[7],
            leftEyeOpenRatio: smoothed[8],
            rightEyeOpenRatio: smoothed[9],
            mouthOpenRatio: smoothed[10],
            mouthPuckerRatio: smoothed[11],
            browFurrowRatio: smoothed[12],
            eyebrowsRaisedRatio: smoothed[13],
            mouthFrownRatio: smoothed[14],
            faceContour: faceContour,
            leftEyeContour: leftEyeContour,
            rightEyeContour: rightEyeContour,
            upperLipTop: upperLipTop,
            upperLipBottom: upperLipBottom,
            lowerLipTop: lowerLipTop,
            lowerLipBottom: lowerLipBottom,
            noseBridge: noseBridge,
            noseBottom: noseBottom
        )
    }

    public func stop() {
        smoothers.removeAll()
    }
}
