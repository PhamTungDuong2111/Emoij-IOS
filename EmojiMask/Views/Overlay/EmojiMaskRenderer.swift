import UIKit
import CoreGraphics

public class EmojiMaskRenderer {

    public static func drawEmojiMask(
        in context: CGContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        state: FaceExpressionState,
        maskType: EmojiMaskType,
        isFrontCam: Bool,
        phase: CGFloat,
        scale: CGFloat = 1.0,
        offsetX: CGFloat = 0.0,
        offsetY: CGFloat = 0.0,
        viewW: CGFloat = 0.0,
        isCutoutMode: Bool = true
    ) {
        context.saveGState()

        // 3D Tilt (Roll)
        let rollAngle = isFrontCam ? state.roll : -state.roll
        context.translateBy(x: cx, y: cy)
        context.rotate(by: rollAngle * .pi / 180.0)
        context.translateBy(x: -cx, y: -cy)

        // Perspective shift based on Yaw and Pitch
        let yawRatio = max(-1.0, min(1.0, state.yaw / 45.0))
        let pitchRatio = max(-1.0, min(1.0, state.pitch / 30.0))

        let featureShiftX = (isFrontCam ? -yawRatio : yawRatio) * (radius * 0.20)
        let featureShiftY = -pitchRatio * (radius * 0.16)

        if isCutoutMode {
            drawArCutoutMask(
                in: context,
                cx: cx,
                cy: cy,
                radius: radius,
                state: state,
                maskType: maskType,
                isFrontCam: isFrontCam,
                yawRatio: yawRatio,
                pitchRatio: pitchRatio,
                featureShiftX: featureShiftX,
                featureShiftY: featureShiftY,
                phase: phase,
                scale: scale,
                offsetX: offsetX,
                offsetY: offsetY,
                viewW: viewW,
                rollAngle: rollAngle
            )
        } else {
            // 2D Cartoon Mode
            drawBaseHead(in: context, cx: cx, cy: cy, radius: radius, maskType: maskType, yawRatio: yawRatio, pitchRatio: pitchRatio, state: state)
            drawEyes(in: context, cx: cx + featureShiftX, cy: cy + featureShiftY, radius: radius, state: state, maskType: maskType, isFrontCam: isFrontCam, phase: phase)
            drawEyebrows(in: context, cx: cx + featureShiftX, cy: cy + featureShiftY, radius: radius, state: state, maskType: maskType)
            drawMouth(in: context, cx: cx + featureShiftX, cy: cy + featureShiftY, radius: radius, state: state, maskType: maskType, phase: phase)
            drawSpecialDecorations(in: context, cx: cx, cy: cy, shiftX: featureShiftX, shiftY: featureShiftY, radius: radius, state: state, maskType: maskType, phase: phase)
        }

        context.restoreGState()
    }

    // MARK: - AR Cutout Mask Implementation
    private static func drawArCutoutMask(
        in context: CGContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        state: FaceExpressionState,
        maskType: EmojiMaskType,
        isFrontCam: Bool,
        yawRatio: CGFloat,
        pitchRatio: CGFloat,
        featureShiftX: CGFloat,
        featureShiftY: CGFloat,
        phase: CGFloat,
        scale: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        viewW: CGFloat,
        rollAngle: CGFloat
    ) {
        let actualFaceW = state.faceWidth > 10 ? state.faceWidth * scale : radius * 1.5
        let actualFaceH = state.faceHeight > 10 ? state.faceHeight * scale : radius * 1.8

        let halfW = actualFaceW * 0.52
        let halfH = actualFaceH * 0.58

        let layerMargin = max(halfW, halfH) * 1.5
        let layerRect = CGRect(x: cx - layerMargin, y: cy - layerMargin, width: layerMargin * 2, height: layerMargin * 2)

        context.saveGState()
        context.clip(to: layerRect)
        context.beginTransparencyLayer(auxiliaryInfo: nil)

        // 1. Base Anatomical Face Path (snug on chin and temples)
        let topY = cy - halfH * 0.95
        let botY = cy + halfH * 1.02
        let chinW = halfW * 0.66
        let cheekY = cy + halfH * 0.10

        let facePath = UIBezierPath()
        facePath.move(to: CGPoint(x: cx, y: topY))
        facePath.addCurve(to: CGPoint(x: cx + halfW, y: cy - halfH * 0.15),
                          controlPoint1: CGPoint(x: cx + halfW * 0.65, y: topY),
                          controlPoint2: CGPoint(x: cx + halfW, y: cy - halfH * 0.50))
        facePath.addCurve(to: CGPoint(x: cx + chinW, y: cy + halfH * 0.88),
                          controlPoint1: CGPoint(x: cx + halfW, y: cheekY),
                          controlPoint2: CGPoint(x: cx + halfW * 0.90, y: cy + halfH * 0.48))
        facePath.addCurve(to: CGPoint(x: cx - chinW, y: cy + halfH * 0.88),
                          controlPoint1: CGPoint(x: cx + chinW * 0.55, y: botY),
                          controlPoint2: CGPoint(x: cx - chinW * 0.55, y: botY))
        facePath.addCurve(to: CGPoint(x: cx - halfW, y: cy - halfH * 0.15),
                          controlPoint1: CGPoint(x: cx - halfW * 0.90, y: cy + halfH * 0.48),
                          controlPoint2: CGPoint(x: cx - halfW, y: cheekY))
        facePath.addCurve(to: CGPoint(x: cx, y: topY),
                          controlPoint1: CGPoint(x: cx - halfW, y: cy - halfH * 0.50),
                          controlPoint2: CGPoint(x: cx - halfW * 0.65, y: topY))
        facePath.close()

        // Mask Shading Gradient
        let lightX = cx - halfW * 0.25 - (yawRatio * halfW * 0.2)
        let lightY = cy - halfH * 0.35 + (pitchRatio * halfH * 0.15)

        context.saveGState()
        facePath.addClip()
        drawMaskGradient(in: context, maskType: maskType, cx: cx, cy: cy, lightX: lightX, lightY: lightY, halfW: halfW, halfH: halfH)
        context.restoreGState()

        // Outer ambient shadow stroke
        context.saveGState()
        context.setLineWidth(max(halfW * 0.04, 3.5))
        context.setStrokeColor(UIColor(white: 0, alpha: 0.22).cgColor)
        context.addPath(facePath.cgPath)
        context.strokePath()
        context.restoreGState()

        // Specular highlight on forehead
        context.saveGState()
        let glossW = halfW * 0.32
        let glossH = halfH * 0.14
        let glossRect = CGRect(x: cx - halfW * 0.38 - glossW / 2, y: cy - halfH * 0.52 - glossH / 2, width: glossW, height: glossH)
        context.setFillColor(UIColor(white: 1.0, alpha: 0.25).cgColor)
        context.fillEllipse(in: glossRect)
        context.restoreGState()

        // 3D Nose Bridge Shading
        draw3DNoseBridge(in: context, cx: cx + featureShiftX, cy: cy + featureShiftY, halfW: halfW, halfH: halfH)

        // 2. CUT OUT EYES (Clear blend mode revealing real eyes)
        let eyeSpacing = halfW * 0.38
        let eyeY = cy + featureShiftY - halfH * 0.18
        let eyeLeftX = cx + featureShiftX - eyeSpacing
        let eyeRightX = cx + featureShiftX + eyeSpacing

        let screenLeftOpen = isFrontCam ? state.leftEyeOpenRatio : state.rightEyeOpenRatio
        let screenRightOpen = isFrontCam ? state.rightEyeOpenRatio : state.leftEyeOpenRatio

        let eyeCutoutW = halfW * 0.20
        let eyeCutoutH = halfH * 0.15

        // Left Eye Cutout
        if maskType == .laughing || (screenLeftOpen < 0.42 && maskType != .sunglasses) {
            drawWinkArc(in: context, x: eyeLeftX, y: eyeY, width: eyeCutoutW)
        } else if maskType == .heartEyes {
            let hp = createHeartPath(x: eyeLeftX, y: eyeY, size: eyeCutoutW * 1.4)
            context.saveGState()
            context.setBlendMode(.clear)
            context.addPath(hp.cgPath)
            context.fillPath()
            context.restoreGState()

            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor)
            context.setLineWidth(halfW * 0.05)
            context.addPath(hp.cgPath)
            context.strokePath()
            context.restoreGState()
        } else if maskType != .sunglasses {
            let leftRect = CGRect(x: eyeLeftX - eyeCutoutW, y: eyeY - eyeCutoutH, width: eyeCutoutW * 2, height: eyeCutoutH * 2)
            context.saveGState()
            context.setBlendMode(.clear)
            context.fillEllipse(in: leftRect)
            context.restoreGState()

            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.27, green: 0.14, blue: 0.04, alpha: 0.85).cgColor)
            context.setLineWidth(max(halfW * 0.035, 3.0))
            context.strokeEllipse(in: leftRect)
            context.restoreGState()
        }

        // Right Eye Cutout
        if maskType == .laughing || (screenRightOpen < 0.42 && maskType != .sunglasses) {
            drawWinkArc(in: context, x: eyeRightX, y: eyeY, width: eyeCutoutW)
        } else if maskType == .heartEyes {
            let hp = createHeartPath(x: eyeRightX, y: eyeY, size: eyeCutoutW * 1.4)
            context.saveGState()
            context.setBlendMode(.clear)
            context.addPath(hp.cgPath)
            context.fillPath()
            context.restoreGState()

            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor)
            context.setLineWidth(halfW * 0.05)
            context.addPath(hp.cgPath)
            context.strokePath()
            context.restoreGState()
        } else if maskType != .sunglasses {
            let rightRect = CGRect(x: eyeRightX - eyeCutoutW, y: eyeY - eyeCutoutH, width: eyeCutoutW * 2, height: eyeCutoutH * 2)
            context.saveGState()
            context.setBlendMode(.clear)
            context.fillEllipse(in: rightRect)
            context.restoreGState()

            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.27, green: 0.14, blue: 0.04, alpha: 0.85).cgColor)
            context.setLineWidth(max(halfW * 0.035, 3.0))
            context.strokeEllipse(in: rightRect)
            context.restoreGState()
        }

        // 3. DYNAMIC MOUTH CUTOUT (reveals real mouth & tongue!)
        let smile = state.smileRatio
        let openRatio = state.mouthOpenRatio
        let pucker = state.mouthPuckerRatio
        let frown = max(state.mouthFrownRatio, state.browFurrowRatio * 0.5)

        var mX = cx + featureShiftX
        var localMouthTopY = cy + featureShiftY + halfH * 0.22

        if !state.upperLipTop.isEmpty && viewW > 0 {
            let rawLipX = state.upperLipTop.map { $0.x }.reduce(0, +) / CGFloat(state.upperLipTop.count)
            let rawLipY = state.upperLipTop.map { $0.y }.reduce(0, +) / CGFloat(state.upperLipTop.count)
            let sx = isFrontCam ? viewW - (rawLipX * scale + offsetX) : rawLipX * scale + offsetX
            let sy = rawLipY * scale + offsetY

            if abs(rollAngle) > 0.1 {
                let rad = -rollAngle * .pi / 180.0
                let cosA = cos(rad)
                let sinA = sin(rad)
                let dx = sx - cx
                let dy = sy - cy
                mX = cx + dx * cosA - dy * sinA
                localMouthTopY = cy + dx * sinA + dy * cosA
            } else {
                mX = sx
                localMouthTopY = sy
            }
        }

        if (pucker > 0.32 && smile < 0.35) || maskType == .kissing {
            let kissY = localMouthTopY + halfH * 0.12
            drawKissingLips(in: context, cx: mX, mouthY: kissY, radius: halfW, phase: phase)
        } else if maskType == .mask {
            let medY = localMouthTopY + halfH * 0.12
            drawMedicalMask(in: context, cx: mX, mouthY: medY, radius: halfW)
        } else {
            let mw = halfW * (0.38 + smile * 0.16 + openRatio * 0.10)
            let mh = halfH * (0.10 + openRatio * 0.50)
            let mouthCenterY = localMouthTopY + mh * (0.32 + openRatio * 0.15)

            let cornerY = mouthCenterY - mh * 0.15 + (frown * mh * 0.30) - (smile * mh * 0.22)
            let leftCornerX = mX - mw
            let rightCornerX = mX + mw

            let mouthPath = UIBezierPath()
            if openRatio > 0.12 {
                mouthPath.move(to: CGPoint(x: leftCornerX, y: cornerY))
                mouthPath.addQuadCurve(to: CGPoint(x: rightCornerX, y: cornerY), controlPoint: CGPoint(x: mX, y: mouthCenterY - mh * 0.32))
                let bottomY = mouthCenterY + mh * 0.88
                mouthPath.addCurve(to: CGPoint(x: leftCornerX, y: cornerY),
                                   controlPoint1: CGPoint(x: rightCornerX + mw * 0.05, y: bottomY),
                                   controlPoint2: CGPoint(x: leftCornerX - mw * 0.05, y: bottomY))
                mouthPath.close()
            } else if smile > 0.18 {
                let smileDepth = mh * (0.50 + smile * 0.45)
                mouthPath.move(to: CGPoint(x: leftCornerX, y: cornerY))
                mouthPath.addQuadCurve(to: CGPoint(x: rightCornerX, y: cornerY), controlPoint: CGPoint(x: mX, y: cornerY + smileDepth * 0.25))
                mouthPath.addQuadCurve(to: CGPoint(x: leftCornerX, y: cornerY), controlPoint: CGPoint(x: mX, y: cornerY + smileDepth))
                mouthPath.close()
            } else if frown > 0.30 {
                let frownArch = mh * 0.50
                mouthPath.move(to: CGPoint(x: leftCornerX, y: cornerY + frownArch))
                mouthPath.addQuadCurve(to: CGPoint(x: rightCornerX, y: cornerY + frownArch), controlPoint: CGPoint(x: mX, y: cornerY))
                mouthPath.addQuadCurve(to: CGPoint(x: leftCornerX, y: cornerY + frownArch), controlPoint: CGPoint(x: mX, y: cornerY + frownArch * 0.6))
                mouthPath.close()
            } else {
                let slitH = mh * 0.36
                let neutRect = CGRect(x: leftCornerX, y: mouthCenterY - slitH, width: mw * 2, height: slitH * 2)
                mouthPath.append(UIBezierPath(roundedRect: neutRect, cornerRadius: slitH))
            }

            // Cavity background
            if openRatio > 0.18 {
                context.saveGState()
                context.setFillColor(UIColor(red: 0.16, green: 0.06, blue: 0.02, alpha: 1.0).cgColor)
                context.addPath(mouthPath.cgPath)
                context.fillPath()
                context.restoreGState()
            }

            // Clear cutout
            context.saveGState()
            context.setBlendMode(.clear)
            context.addPath(mouthPath.cgPath)
            context.fillPath()
            context.restoreGState()

            // Mouth outline
            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.13, green: 0.04, blue: 0.01, alpha: 1.0).cgColor)
            context.setLineWidth(max(halfW * 0.045, 4.0))
            context.setLineCap(.round)
            context.setLineJoin(.round)
            context.addPath(mouthPath.cgPath)
            context.strokePath()
            context.restoreGState()
        }

        context.endTransparencyLayer()
        context.restoreGState()

        // 4. Overlays & Eyebrows
        drawSpecialDecorations(in: context, cx: cx, cy: cy, shiftX: featureShiftX, shiftY: featureShiftY, radius: halfW, state: state, maskType: maskType, phase: phase)
        drawEyebrows(in: context, cx: cx + featureShiftX, cy: cy + featureShiftY, radius: halfW, state: state, maskType: maskType)
    }

    private static func drawMaskGradient(
        in context: CGContext,
        maskType: EmojiMaskType,
        cx: CGFloat, cy: CGFloat,
        lightX: CGFloat, lightY: CGFloat,
        halfW: CGFloat, halfH: CGFloat
    ) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        switch maskType {
        case .angry:
            let colors = [
                UIColor(red: 1.0, green: 0.44, blue: 0.26, alpha: 1.0).cgColor,
                UIColor(red: 0.90, green: 0.22, blue: 0.21, alpha: 1.0).cgColor,
                UIColor(red: 0.72, green: 0.11, blue: 0.11, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.65, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawRadialGradient(gradient, startCenter: CGPoint(x: lightX, y: lightY), startRadius: 0,
                                           endCenter: CGPoint(x: lightX, y: lightY), endRadius: max(halfW, halfH) * 1.35,
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
        case .scream:
            let colors = [
                UIColor(red: 0.36, green: 0.58, blue: 0.77, alpha: 1.0).cgColor,
                UIColor(red: 0.63, green: 0.77, blue: 0.89, alpha: 1.0).cgColor,
                UIColor(red: 1.0, green: 0.89, blue: 0.48, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.45, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawLinearGradient(gradient, start: CGPoint(x: cx, y: cy - halfH), end: CGPoint(x: cx, y: cy + halfH), options: [])
            }
        case .devil:
            let colors = [
                UIColor(red: 0.73, green: 0.41, blue: 0.78, alpha: 1.0).cgColor,
                UIColor(red: 0.56, green: 0.14, blue: 0.67, alpha: 1.0).cgColor,
                UIColor(red: 0.29, green: 0.08, blue: 0.55, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.65, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawRadialGradient(gradient, startCenter: CGPoint(x: lightX, y: lightY), startRadius: 0,
                                           endCenter: CGPoint(x: lightX, y: lightY), endRadius: max(halfW, halfH) * 1.35,
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
        case .alien:
            let colors = [
                UIColor(red: 0.65, green: 0.84, blue: 0.65, alpha: 1.0).cgColor,
                UIColor(red: 0.51, green: 0.78, blue: 0.52, alpha: 1.0).cgColor,
                UIColor(red: 0.18, green: 0.49, blue: 0.20, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.65, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawRadialGradient(gradient, startCenter: CGPoint(x: lightX, y: lightY), startRadius: 0,
                                           endCenter: CGPoint(x: lightX, y: lightY), endRadius: max(halfW, halfH) * 1.35,
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
        case .robot:
            let colors = [
                UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1.0).cgColor,
                UIColor(red: 0.69, green: 0.75, blue: 0.77, alpha: 1.0).cgColor,
                UIColor(red: 0.38, green: 0.49, blue: 0.55, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.55, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawLinearGradient(gradient, start: CGPoint(x: cx - halfW, y: cy - halfH), end: CGPoint(x: cx + halfW, y: cy + halfH), options: [])
            }
        case .clown:
            let colors = [
                UIColor(white: 1.0, alpha: 1.0).cgColor,
                UIColor(white: 0.96, alpha: 1.0).cgColor,
                UIColor(white: 0.84, alpha: 1.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.70, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawRadialGradient(gradient, startCenter: CGPoint(x: lightX, y: lightY), startRadius: 0,
                                           endCenter: CGPoint(x: lightX, y: lightY), endRadius: max(halfW, halfH) * 1.3,
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
        default:
            // Classic Apple Golden-Yellow Emoji Gradient
            let colors = [
                UIColor(red: 1.00, green: 0.98, blue: 0.77, alpha: 1.0).cgColor, // soft highlight
                UIColor(red: 1.00, green: 0.84, blue: 0.31, alpha: 1.0).cgColor, // core yellow
                UIColor(red: 1.00, green: 0.63, blue: 0.00, alpha: 1.0).cgColor, // body amber
                UIColor(red: 0.90, green: 0.32, blue: 0.00, alpha: 1.0).cgColor, // rich shadow rim
                UIColor(red: 0.55, green: 0.15, blue: 0.00, alpha: 1.0).cgColor  // ambient rim
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.40, 0.72, 0.92, 1.0]
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                context.drawRadialGradient(gradient, startCenter: CGPoint(x: lightX, y: lightY), startRadius: 0,
                                           endCenter: CGPoint(x: lightX, y: lightY), endRadius: max(halfW, halfH) * 1.35,
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
        }
    }

    private static func draw3DNoseBridge(in context: CGContext, cx: CGFloat, cy: CGFloat, halfW: CGFloat, halfH: CGFloat) {
        let noseY = cy + halfH * 0.05
        let noseW = halfW * 0.13
        let noseH = halfH * 0.12

        // Soft white nose bridge highlight
        context.saveGState()
        context.setStrokeColor(UIColor(white: 1.0, alpha: 0.22).cgColor)
        context.setLineWidth(max(halfW * 0.04, 3.0))
        context.setLineCap(.round)
        context.move(to: CGPoint(x: cx - noseW * 0.15, y: noseY - noseH * 0.6))
        context.addLine(to: CGPoint(x: cx - noseW * 0.15, y: noseY + noseH * 0.1))
        context.strokePath()
        context.restoreGState()

        // Soft warm shadow under nose tip
        context.saveGState()
        context.setStrokeColor(UIColor(white: 0, alpha: 0.18).cgColor)
        context.setLineWidth(max(halfW * 0.04, 3.5))
        context.setLineCap(.round)
        let sp = UIBezierPath()
        sp.move(to: CGPoint(x: cx - noseW, y: noseY + noseH * 0.25))
        sp.addQuadCurve(to: CGPoint(x: cx + noseW, y: noseY + noseH * 0.25), controlPoint: CGPoint(x: cx, y: noseY + noseH * 0.55))
        context.addPath(sp.cgPath)
        context.strokePath()
        context.restoreGState()
    }

    private static func createHeartPath(x: CGFloat, y: CGFloat, size: CGFloat) -> UIBezierPath {
        let p = UIBezierPath()
        p.move(to: CGPoint(x: x, y: y + size * 0.55))
        p.addCurve(to: CGPoint(x: x, y: y - size * 0.35),
                   controlPoint1: CGPoint(x: x - size * 0.85, y: y - size * 0.1),
                   controlPoint2: CGPoint(x: x - size * 0.85, y: y - size * 0.75))
        p.addCurve(to: CGPoint(x: x, y: y + size * 0.55),
                   controlPoint1: CGPoint(x: x + size * 0.85, y: y - size * 0.75),
                   controlPoint2: CGPoint(x: x + size * 0.85, y: y - size * 0.1))
        p.close()
        return p
    }

    private static func drawKissingLips(in context: CGContext, cx: CGFloat, mouthY: CGFloat, radius: CGFloat, phase: CGFloat) {
        let puckerX = cx - radius * 0.04
        let puckerSize = radius * 0.14

        let kissPath = UIBezierPath()
        kissPath.move(to: CGPoint(x: puckerX - puckerSize, y: mouthY))
        kissPath.addCurve(to: CGPoint(x: puckerX + puckerSize, y: mouthY),
                          controlPoint1: CGPoint(x: puckerX - puckerSize * 0.5, y: mouthY - puckerSize * 0.8),
                          controlPoint2: CGPoint(x: puckerX + puckerSize * 0.5, y: mouthY - puckerSize * 0.8))
        kissPath.addCurve(to: CGPoint(x: puckerX - puckerSize, y: mouthY),
                          controlPoint1: CGPoint(x: puckerX + puckerSize * 0.5, y: mouthY + puckerSize * 0.8),
                          controlPoint2: CGPoint(x: puckerX - puckerSize * 0.5, y: mouthY + puckerSize * 0.8))
        kissPath.close()

        context.saveGState()
        context.setFillColor(UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0).cgColor)
        context.addPath(kissPath.cgPath)
        context.fillPath()

        context.setStrokeColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
        context.setLineWidth(radius * 0.075)
        context.setLineCap(.round)
        context.addPath(kissPath.cgPath)
        context.strokePath()

        context.move(to: CGPoint(x: puckerX - puckerSize * 0.4, y: mouthY))
        context.addLine(to: CGPoint(x: puckerX + puckerSize * 0.4, y: mouthY))
        context.strokePath()
        context.restoreGState()

        // Drifting animated heart
        let heartDrift = phase * radius * 0.45
        let heartX = cx + radius * 0.35 + heartDrift * 0.45
        let heartY = mouthY - radius * 0.12 - heartDrift
        let heartScale = 1.0 - phase * 0.3
        drawHeart(in: context, x: heartX, y: heartY, size: radius * 0.20 * heartScale, color: UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0))
    }

    // MARK: - 2D Cartoon Base Head
    private static func drawBaseHead(
        in context: CGContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        maskType: EmojiMaskType,
        yawRatio: CGFloat,
        pitchRatio: CGFloat,
        state: FaceExpressionState
    ) {
        let lightX = cx - radius * 0.25 - (yawRatio * radius * 0.15)
        let lightY = cy - radius * 0.32 + (pitchRatio * radius * 0.1)

        context.saveGState()

        switch maskType {
        case .scream:
            let ovalRect = CGRect(x: cx - radius * 0.88, y: cy - radius * 1.08, width: radius * 1.76, height: radius * 2.16)
            let path = UIBezierPath(ovalIn: ovalRect)
            path.addClip()
            drawMaskGradient(in: context, maskType: maskType, cx: cx, cy: cy, lightX: lightX, lightY: lightY, halfW: radius * 0.88, halfH: radius * 1.08)
        case .robot:
            let rect = CGRect(x: cx - radius * 0.95, y: cy - radius * 0.95, width: radius * 1.9, height: radius * 1.9)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius * 0.35)
            path.addClip()
            drawMaskGradient(in: context, maskType: maskType, cx: cx, cy: cy, lightX: lightX, lightY: lightY, halfW: radius, halfH: radius)
            // Robot ears
            context.restoreGState()
            context.saveGState()
            context.setFillColor(UIColor(red: 0.47, green: 0.56, blue: 0.61, alpha: 1.0).cgColor)
            context.fillEllipse(in: CGRect(x: cx - radius * 1.16, y: cy - radius * 0.14, width: radius * 0.28, height: radius * 0.28))
            context.fillEllipse(in: CGRect(x: cx + radius * 0.88, y: cy - radius * 0.14, width: radius * 0.28, height: radius * 0.28))
        case .alien:
            let path = UIBezierPath()
            path.addArc(withCenter: CGPoint(x: cx, y: cy - radius * 0.5), radius: radius * 1.0, startAngle: .pi, endAngle: 0, clockwise: true)
            path.addCurve(to: CGPoint(x: cx, y: cy + radius * 1.12),
                          controlPoint1: CGPoint(x: cx + radius * 0.95, y: cy + radius * 0.4),
                          controlPoint2: CGPoint(x: cx + radius * 0.45, y: cy + radius * 1.05))
            path.addCurve(to: CGPoint(x: cx - radius * 1.0, y: cy - radius * 0.5),
                          controlPoint1: CGPoint(x: cx - radius * 0.45, y: cy + radius * 1.05),
                          controlPoint2: CGPoint(x: cx - radius * 0.95, y: cy + radius * 0.4))
            path.close()
            path.addClip()
            drawMaskGradient(in: context, maskType: maskType, cx: cx, cy: cy, lightX: lightX, lightY: lightY, halfW: radius, halfH: radius)
        default:
            let path = UIBezierPath(ovalIn: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
            path.addClip()
            drawMaskGradient(in: context, maskType: maskType, cx: cx, cy: cy, lightX: lightX, lightY: lightY, halfW: radius, halfH: radius)

            // Glossy arc
            context.restoreGState()
            context.saveGState()
            context.setStrokeColor(UIColor(white: 1.0, alpha: 0.35).cgColor)
            context.setLineWidth(radius * 0.08)
            context.setLineCap(.round)
            let glossArc = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: radius * 0.82, startAngle: 210 * .pi / 180, endAngle: 270 * .pi / 180, clockwise: true)
            context.addPath(glossArc.cgPath)
            context.strokePath()

            // Brow furrow redness flush
            if state.browFurrowRatio > 0.50 {
                let flushAlpha = min(0.5, (state.browFurrowRatio - 0.50) * 2.0 * 0.5)
                context.setFillColor(UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: flushAlpha).cgColor)
                context.fillEllipse(in: CGRect(x: cx - radius * 0.75, y: cy - radius * 1.0, width: radius * 1.5, height: radius * 1.5))
            }
        }

        context.restoreGState()

        // Subtle dark border
        context.saveGState()
        context.setStrokeColor(UIColor(white: 0, alpha: 0.15).cgColor)
        context.setLineWidth(radius * 0.025)
        context.strokeEllipse(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
        context.restoreGState()
    }

    // MARK: - 2D Eyes
    private static func drawEyes(
        in context: CGContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        state: FaceExpressionState,
        maskType: EmojiMaskType,
        isFrontCam: Bool,
        phase: CGFloat
    ) {
        let eyeSpacing = radius * 0.38
        let eyeY = cy - radius * 0.16
        let eyeLeftX = cx - eyeSpacing
        let eyeRightX = cx + eyeSpacing

        let screenLeftOpen = isFrontCam ? state.leftEyeOpenRatio : state.rightEyeOpenRatio
        let screenRightOpen = isFrontCam ? state.rightEyeOpenRatio : state.leftEyeOpenRatio

        switch maskType {
        case .heartEyes:
            let pulse = 1.0 + state.smileRatio * 0.25 + sin(phase * .pi * 2.0) * 0.08
            let baseSize = radius * 0.26 * pulse
            drawExpressiveHeartEye(in: context, x: eyeLeftX, y: eyeY, size: baseSize, openRatio: screenLeftOpen)
            drawExpressiveHeartEye(in: context, x: eyeRightX, y: eyeY, size: baseSize, openRatio: screenRightOpen)
        case .starStruck:
            let starSize = radius * 0.28
            let starAngle = (phase * 360.0).truncatingRemainder(dividingBy: 360.0)
            drawExpressiveStarEye(in: context, x: eyeLeftX, y: eyeY, size: starSize, rotation: starAngle, openRatio: screenLeftOpen)
            drawExpressiveStarEye(in: context, x: eyeRightX, y: eyeY, size: starSize, rotation: -starAngle, openRatio: screenRightOpen)
        case .sunglasses:
            break
        case .laughing:
            drawWinkArc(in: context, x: eyeLeftX, y: eyeY, width: radius * 0.24)
            drawWinkArc(in: context, x: eyeRightX, y: eyeY, width: radius * 0.24)
        case .crying:
            let weepArc = UIBezierPath(arcCenter: CGPoint(x: eyeLeftX, y: eyeY), radius: radius * 0.15, startAngle: 200 * .pi / 180, endAngle: 340 * .pi / 180, clockwise: false)
            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
            context.setLineWidth(radius * 0.07)
            context.setLineCap(.round)
            context.addPath(weepArc.cgPath)
            context.strokePath()

            let weepArcR = UIBezierPath(arcCenter: CGPoint(x: eyeRightX, y: eyeY), radius: radius * 0.15, startAngle: 200 * .pi / 180, endAngle: 340 * .pi / 180, clockwise: false)
            context.addPath(weepArcR.cgPath)
            context.strokePath()
            context.restoreGState()
        case .alien:
            drawAlienEye(in: context, x: eyeLeftX, y: eyeY, radius: radius, angle: -22.0, openRatio: screenLeftOpen)
            drawAlienEye(in: context, x: eyeRightX, y: eyeY, radius: radius, angle: 22.0, openRatio: screenRightOpen)
        case .robot:
            drawRobotEye(in: context, x: eyeLeftX, y: eyeY, radius: radius, openRatio: screenLeftOpen)
            drawRobotEye(in: context, x: eyeRightX, y: eyeY, radius: radius, openRatio: screenRightOpen)
        case .zany:
            if screenLeftOpen < 0.42 {
                drawWinkArc(in: context, x: eyeLeftX, y: eyeY, width: radius * 0.24)
            } else {
                drawStandardEye(in: context, x: eyeLeftX, y: eyeY, width: radius * 0.24, maxH: radius * 0.28, openRatio: screenLeftOpen)
            }
            if screenRightOpen < 0.42 {
                drawWinkArc(in: context, x: eyeRightX, y: eyeY, width: radius * 0.14)
            } else {
                drawStandardEye(in: context, x: eyeRightX, y: eyeY, width: radius * 0.12, maxH: radius * 0.14, openRatio: screenRightOpen)
            }
        default:
            let eyeW = radius * 0.15
            let eyeMaxH = radius * 0.20
            drawStandardEye(in: context, x: eyeLeftX, y: eyeY, width: eyeW, maxH: eyeMaxH, openRatio: screenLeftOpen)
            drawStandardEye(in: context, x: eyeRightX, y: eyeY, width: eyeW, maxH: eyeMaxH, openRatio: screenRightOpen)
        }
    }

    private static func drawStandardEye(in context: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, maxH: CGFloat, openRatio: CGFloat) {
        if openRatio < 0.42 {
            drawWinkArc(in: context, x: x, y: y, width: width)
        } else {
            let curH = max(maxH * 0.25, maxH * openRatio)
            let eyeRect = CGRect(x: x - width, y: y - curH, width: width * 2, height: curH * 2)

            context.saveGState()
            context.setFillColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
            context.fillEllipse(in: eyeRect)

            if openRatio > 0.45 {
                let sparkleSize = min(width, curH) * 0.35
                context.setFillColor(UIColor.white.cgColor)
                context.fillEllipse(in: CGRect(x: x - width * 0.30 - sparkleSize / 2, y: y - curH * 0.30 - sparkleSize / 2, width: sparkleSize, height: sparkleSize))
            }
            context.restoreGState()
        }
    }

    private static func drawWinkArc(in context: CGContext, x: CGFloat, y: CGFloat, width: CGFloat) {
        let arc = UIBezierPath(arcCenter: CGPoint(x: x, y: y), radius: width * 0.8, startAngle: 200 * .pi / 180, endAngle: 340 * .pi / 180, clockwise: false)
        context.saveGState()
        context.setStrokeColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
        context.setLineWidth(max(width * 0.38, 6.0))
        context.setLineCap(.round)
        context.addPath(arc.cgPath)
        context.strokePath()
        context.restoreGState()
    }

    private static func drawExpressiveHeartEye(in context: CGContext, x: CGFloat, y: CGFloat, size: CGFloat, openRatio: CGFloat) {
        if openRatio < 0.42 {
            drawWinkArc(in: context, x: x, y: y, width: size * 0.7)
        } else {
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.scaleBy(x: 1.0, y: max(0.2, openRatio))
            context.translateBy(x: -x, y: -y)
            drawHeart(in: context, x: x, y: y, size: size, color: UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0))
            context.restoreGState()
        }
    }

    private static func drawExpressiveStarEye(in context: CGContext, x: CGFloat, y: CGFloat, size: CGFloat, rotation: CGFloat, openRatio: CGFloat) {
        if openRatio < 0.42 {
            drawWinkArc(in: context, x: x, y: y, width: size * 0.7)
        } else {
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.scaleBy(x: 1.0, y: max(0.2, openRatio))
            context.rotate(by: rotation * .pi / 180.0)
            context.translateBy(x: -x, y: -y)
            drawStar(in: context, x: x, y: y, size: size)
            context.restoreGState()
        }
    }

    private static func drawAlienEye(in context: CGContext, x: CGFloat, y: CGFloat, radius: CGFloat, angle: CGFloat, openRatio: CGFloat) {
        if openRatio < 0.35 {
            drawWinkArc(in: context, x: x, y: y, width: radius * 0.16)
        } else {
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: angle * .pi / 180.0)
            context.scaleBy(x: 1.0, y: max(0.15, openRatio))
            context.translateBy(x: -x, y: -y)

            let oval = CGRect(x: x - radius * 0.22, y: y - radius * 0.35, width: radius * 0.44, height: radius * 0.70)
            context.setFillColor(UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1.0).cgColor)
            context.fillEllipse(in: oval)

            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: CGRect(x: x - radius * 0.06 - radius * 0.06, y: y - radius * 0.12 - radius * 0.06, width: radius * 0.12, height: radius * 0.12))
            context.restoreGState()
        }
    }

    private static func drawRobotEye(in context: CGContext, x: CGFloat, y: CGFloat, radius: CGFloat, openRatio: CGFloat) {
        let eyeSize = radius * 0.22
        let h = max(4.0, eyeSize * openRatio)
        let rect = CGRect(x: x - eyeSize / 2, y: y - h / 2, width: eyeSize, height: h)

        context.saveGState()
        context.setFillColor(UIColor(red: 0.15, green: 0.20, blue: 0.22, alpha: 1.0).cgColor)
        context.fill(rect)

        if openRatio > 0.35 {
            let ph = max(2.0, eyeSize * 0.3 * openRatio)
            context.setFillColor(UIColor(red: 0.0, green: 0.90, blue: 1.0, alpha: 1.0).cgColor)
            context.fill(CGRect(x: x - eyeSize * 0.3, y: y - ph, width: eyeSize * 0.6, height: ph * 2))
        }
        context.restoreGState()
    }

    // MARK: - Eyebrows
    private static func drawEyebrows(
        in context: CGContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        state: FaceExpressionState,
        maskType: EmojiMaskType
    ) {
        let browY = cy - radius * 0.38
        let browSpacing = radius * 0.38

        let furrow = state.browFurrowRatio
        let raise = state.eyebrowsRaisedRatio

        context.saveGState()
        context.setStrokeColor(UIColor(red: 0.31, green: 0.20, blue: 0.18, alpha: 1.0).cgColor)
        context.setLineWidth(radius * 0.07)
        context.setLineCap(.round)

        if maskType == .scream {
            let screamRaise = radius * 0.12
            let leftArc = UIBezierPath(arcCenter: CGPoint(x: cx - browSpacing, y: browY - screamRaise), radius: radius * 0.15, startAngle: 200 * .pi / 180, endAngle: 340 * .pi / 180, clockwise: false)
            let rightArc = UIBezierPath(arcCenter: CGPoint(x: cx + browSpacing, y: browY - screamRaise), radius: radius * 0.15, startAngle: 200 * .pi / 180, endAngle: 340 * .pi / 180, clockwise: false)
            context.addPath(leftArc.cgPath)
            context.addPath(rightArc.cgPath)
            context.strokePath()
        } else if furrow > 0.45 || maskType == .angry || maskType == .devil {
            let furrowStrength = max(furrow, (maskType == .angry || maskType == .devil) ? 0.5 : 0.0)
            context.setLineWidth(radius * (0.045 + furrowStrength * 0.012))
            context.setStrokeColor(UIColor(red: 0.18, green: 0.11, blue: 0.08, alpha: 1.0).cgColor)

            let innerDrop = radius * (0.04 + furrowStrength * 0.08)
            let outerY = browY - radius * 0.03
            let innerY = browY + innerDrop

            let leftOuterX = cx - browSpacing - radius * 0.15
            let leftInnerX = cx - radius * 0.08
            let lp = UIBezierPath()
            lp.move(to: CGPoint(x: leftOuterX, y: outerY))
            lp.addQuadCurve(to: CGPoint(x: leftInnerX, y: innerY), controlPoint: CGPoint(x: (leftOuterX + leftInnerX) / 2.0, y: outerY - radius * 0.02))
            context.addPath(lp.cgPath)

            let rightInnerX = cx + radius * 0.08
            let rightOuterX = cx + browSpacing + radius * 0.15
            let rp = UIBezierPath()
            rp.move(to: CGPoint(x: rightInnerX, y: innerY))
            rp.addQuadCurve(to: CGPoint(x: rightOuterX, y: outerY), controlPoint: CGPoint(x: (rightInnerX + rightOuterX) / 2.0, y: outerY - radius * 0.02))
            context.addPath(rp.cgPath)
            context.strokePath()
        } else {
            let browRaiseY = raise * radius * 0.10
            let leftY = browY - browRaiseY
            let rightY = browY - browRaiseY
            let leftArc = UIBezierPath(arcCenter: CGPoint(x: cx - browSpacing, y: leftY), radius: radius * 0.15, startAngle: 200 * .pi / 180, endAngle: 340 * .pi / 180, clockwise: false)
            let rightArc = UIBezierPath(arcCenter: CGPoint(x: cx + browSpacing, y: rightY), radius: radius * 0.15, startAngle: 200 * .pi / 180, endAngle: 340 * .pi / 180, clockwise: false)
            context.addPath(leftArc.cgPath)
            context.addPath(rightArc.cgPath)
            context.strokePath()
        }
        context.restoreGState()
    }

    // MARK: - 2D Mouth
    private static func drawMouth(
        in context: CGContext,
        cx: CGFloat,
        cy: CGFloat,
        radius: CGFloat,
        state: FaceExpressionState,
        maskType: EmojiMaskType,
        phase: CGFloat
    ) {
        let mouthY = cy + radius * 0.28
        let smile = state.smileRatio
        let openRatio = state.mouthOpenRatio
        let pucker = state.mouthPuckerRatio
        let frown = max(state.mouthFrownRatio, state.browFurrowRatio * 0.5)

        if maskType == .robot {
            drawRobotMouth(in: context, cx: cx, mouthY: mouthY, radius: radius)
            return
        }
        if maskType == .mask {
            drawMedicalMask(in: context, cx: cx, mouthY: mouthY, radius: radius)
            return
        }
        if maskType == .scream && openRatio < 0.2 {
            drawScreamMouth(in: context, cx: cx, mouthY: mouthY, radius: radius, openRatio: openRatio)
            return
        }

        if (pucker > 0.28 && smile < 0.35 && openRatio < 0.28) ||
           (maskType == .kissing && smile < 0.35 && openRatio < 0.28 && frown < 0.28) {
            drawKissingLips(in: context, cx: cx, mouthY: mouthY, radius: radius, phase: phase)
        } else if openRatio > 0.22 || (maskType == .scream && smile < 0.25) {
            if maskType == .scream {
                drawScreamMouth(in: context, cx: cx, mouthY: mouthY, radius: radius, openRatio: openRatio)
            } else {
                let mw = radius * (0.35 + smile * 0.18)
                let mh = radius * (0.28 + openRatio * 0.40)

                let mouthPath = UIBezierPath()
                mouthPath.move(to: CGPoint(x: cx - mw, y: mouthY))
                mouthPath.addQuadCurve(to: CGPoint(x: cx + mw, y: mouthY), controlPoint: CGPoint(x: cx, y: mouthY - radius * 0.06))
                mouthPath.addCurve(to: CGPoint(x: cx - mw, y: mouthY),
                                   controlPoint1: CGPoint(x: cx + mw * 0.9, y: mouthY + mh),
                                   controlPoint2: CGPoint(x: cx - mw * 0.9, y: mouthY + mh))
                mouthPath.close()

                context.saveGState()
                context.setFillColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
                context.addPath(mouthPath.cgPath)
                context.fillPath()

                context.clip(to: mouthPath.bounds)
                mouthPath.addClip()

                // Teeth
                context.setFillColor(UIColor.white.cgColor)
                let teethRect = CGRect(x: cx - mw * 0.85, y: mouthY - radius * 0.08, width: mw * 1.7, height: radius * 0.22)
                context.fill(UIBezierPath(roundedRect: teethRect, cornerRadius: 8.0).cgPath)

                // Tongue
                context.setFillColor(UIColor(red: 1.0, green: 0.18, blue: 0.33, alpha: 1.0).cgColor)
                context.fillEllipse(in: CGRect(x: cx - mw * 0.55, y: mouthY + mh * 0.85 - mw * 0.55, width: mw * 1.1, height: mw * 1.1))
                context.restoreGState()
            }
        } else if (frown > 0.40 && smile < 0.25) || (maskType == .angry && smile < 0.25 && openRatio < 0.22) {
            let frownStrength = max(frown, maskType == .angry ? 0.7 : 0.0)
            let mw = radius * 0.36
            let frownDepth = radius * (0.08 + frownStrength * 0.16)

            let p = UIBezierPath()
            p.move(to: CGPoint(x: cx - mw, y: mouthY + frownDepth * 0.6))
            p.addQuadCurve(to: CGPoint(x: cx + mw, y: mouthY + frownDepth * 0.6), controlPoint: CGPoint(x: cx, y: mouthY - frownDepth * 0.6))

            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
            context.setLineWidth(radius * 0.08)
            context.setLineCap(.round)
            context.addPath(p.cgPath)
            context.strokePath()
            context.restoreGState()
        } else if smile > 0.20 {
            let mw = radius * (0.35 + smile * 0.18)
            let smileDepth = radius * (0.12 + smile * 0.20)

            let p = UIBezierPath()
            p.move(to: CGPoint(x: cx - mw, y: mouthY))
            p.addQuadCurve(to: CGPoint(x: cx + mw, y: mouthY), controlPoint: CGPoint(x: cx, y: mouthY + smileDepth))

            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
            context.setLineWidth(radius * 0.08)
            context.setLineCap(.round)
            context.addPath(p.cgPath)
            context.strokePath()

            // Cheerful blush
            if smile > 0.35 {
                let blushAlpha = min(0.45, smile * 0.45)
                context.setFillColor(UIColor(red: 1.0, green: 0.32, blue: 0.32, alpha: blushAlpha).cgColor)
                context.fillEllipse(in: CGRect(x: cx - radius * 0.55 - radius * 0.16, y: mouthY - radius * 0.08 - radius * 0.16, width: radius * 0.32, height: radius * 0.32))
                context.fillEllipse(in: CGRect(x: cx + radius * 0.55 - radius * 0.16, y: mouthY - radius * 0.08 - radius * 0.16, width: radius * 0.32, height: radius * 0.32))
            }
            context.restoreGState()
        } else {
            let mw = radius * 0.32
            let p = UIBezierPath()
            p.move(to: CGPoint(x: cx - mw, y: mouthY))
            p.addQuadCurve(to: CGPoint(x: cx + mw, y: mouthY), controlPoint: CGPoint(x: cx, y: mouthY + radius * 0.03))

            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
            context.setLineWidth(radius * 0.075)
            context.setLineCap(.round)
            context.addPath(p.cgPath)
            context.strokePath()
            context.restoreGState()
        }
    }

    private static func drawRobotMouth(in context: CGContext, cx: CGFloat, mouthY: CGFloat, radius: CGFloat) {
        let mw = radius * 0.42
        let mh = radius * 0.18
        let rect = CGRect(x: cx - mw, y: mouthY - mh / 2, width: mw * 2, height: mh)

        context.saveGState()
        context.setFillColor(UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1.0).cgColor)
        context.fill(rect)

        context.setStrokeColor(UIColor(red: 0.15, green: 0.20, blue: 0.22, alpha: 1.0).cgColor)
        context.setLineWidth(radius * 0.045)
        for i in -3...3 {
            let bx = cx + CGFloat(i) * (radius * 0.11)
            context.move(to: CGPoint(x: bx, y: mouthY - mh / 2))
            context.addLine(to: CGPoint(x: bx, y: mouthY + mh / 2))
        }
        context.strokePath()
        context.restoreGState()
    }

    private static func drawMedicalMask(in context: CGContext, cx: CGFloat, mouthY: CGFloat, radius: CGFloat) {
        let mw = radius * 0.72
        let mh = radius * 0.52
        let maskRect = CGRect(x: cx - mw, y: mouthY - mh * 0.4, width: mw * 2, height: mh * 1.2)

        context.saveGState()
        context.setFillColor(UIColor(red: 0.50, green: 0.87, blue: 0.92, alpha: 1.0).cgColor)
        context.fill(UIBezierPath(roundedRect: maskRect, cornerRadius: 22.0).cgPath)

        context.setStrokeColor(UIColor(red: 0.30, green: 0.82, blue: 0.88, alpha: 1.0).cgColor)
        context.setLineWidth(radius * 0.03)
        context.move(to: CGPoint(x: cx - mw * 0.85, y: mouthY))
        context.addLine(to: CGPoint(x: cx + mw * 0.85, y: mouthY))
        context.move(to: CGPoint(x: cx - mw * 0.85, y: mouthY + mh * 0.35))
        context.addLine(to: CGPoint(x: cx + mw * 0.85, y: mouthY + mh * 0.35))
        context.strokePath()
        context.restoreGState()
    }

    private static func drawScreamMouth(in context: CGContext, cx: CGFloat, mouthY: CGFloat, radius: CGFloat, openRatio: CGFloat) {
        let ovalW = radius * 0.28
        let ovalH = radius * (0.42 + openRatio * 0.25)
        let rect = CGRect(x: cx - ovalW, y: mouthY - ovalH * 0.2, width: ovalW * 2, height: ovalH * 1.3)

        context.saveGState()
        context.setFillColor(UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0).cgColor)
        context.fillEllipse(in: rect)
        context.restoreGState()
    }

    // MARK: - Special Decorations
    private static func drawSpecialDecorations(
        in context: CGContext,
        cx: CGFloat,
        cy: CGFloat,
        shiftX: CGFloat,
        shiftY: CGFloat,
        radius: CGFloat,
        state: FaceExpressionState,
        maskType: EmojiMaskType,
        phase: CGFloat
    ) {
        switch maskType {
        case .cat:
            drawCatFeatures(in: context, cx: cx, cy: cy, shiftX: shiftX, shiftY: shiftY, radius: radius)
        case .sunglasses:
            drawSunglasses(in: context, cx: cx + shiftX, cy: cy + shiftY, radius: radius)
        case .crying:
            let tearYBase = cy + shiftY - radius * 0.1
            let flowOffset = phase * radius * 0.6
            let tearW = radius * 0.16
            let tearH = radius * 0.32
            context.saveGState()
            context.setFillColor(UIColor(red: 0.31, green: 0.76, blue: 0.97, alpha: 1.0).cgColor)
            let leftTear = CGRect(x: cx + shiftX - radius * 0.42 - tearW / 2, y: tearYBase + flowOffset, width: tearW, height: tearH)
            let rightTear = CGRect(x: cx + shiftX + radius * 0.42 - tearW / 2, y: tearYBase + flowOffset, width: tearW, height: tearH)
            context.fill(UIBezierPath(roundedRect: leftTear, cornerRadius: 20.0).cgPath)
            context.fill(UIBezierPath(roundedRect: rightTear, cornerRadius: 20.0).cgPath)
            context.restoreGState()
        case .laughing:
            let tearLeftX = cx + shiftX - radius * 0.68
            let tearRightX = cx + shiftX + radius * 0.68
            let tearY = cy + shiftY - radius * 0.05
            let tearSize = radius * 0.22

            let lp = UIBezierPath()
            lp.move(to: CGPoint(x: tearLeftX, y: tearY))
            lp.addCurve(to: CGPoint(x: tearLeftX - tearSize * 0.6, y: tearY + tearSize * 1.4),
                        controlPoint1: CGPoint(x: tearLeftX - tearSize * 1.2, y: tearY - tearSize * 0.5),
                        controlPoint2: CGPoint(x: tearLeftX - tearSize * 1.5, y: tearY + tearSize * 1.2))
            lp.addCurve(to: CGPoint(x: tearLeftX, y: tearY),
                        controlPoint1: CGPoint(x: tearLeftX, y: tearY + tearSize * 0.9),
                        controlPoint2: CGPoint(x: tearLeftX, y: tearY + tearSize * 0.3))
            lp.close()

            let rp = UIBezierPath()
            rp.move(to: CGPoint(x: tearRightX, y: tearY))
            rp.addCurve(to: CGPoint(x: tearRightX + tearSize * 0.6, y: tearY + tearSize * 1.4),
                        controlPoint1: CGPoint(x: tearRightX + tearSize * 1.2, y: tearY - tearSize * 0.5),
                        controlPoint2: CGPoint(x: tearRightX + tearSize * 1.5, y: tearY + tearSize * 1.2))
            rp.addCurve(to: CGPoint(x: tearRightX, y: tearY),
                        controlPoint1: CGPoint(x: tearRightX, y: tearY + tearSize * 0.9),
                        controlPoint2: CGPoint(x: tearRightX, y: tearY + tearSize * 0.3))
            rp.close()

            context.saveGState()
            context.setFillColor(UIColor(red: 0.16, green: 0.71, blue: 0.96, alpha: 1.0).cgColor)
            context.addPath(lp.cgPath)
            context.addPath(rp.cgPath)
            context.fillPath()

            context.setFillColor(UIColor(white: 1.0, alpha: 0.65).cgColor)
            context.fillEllipse(in: CGRect(x: tearLeftX - tearSize * 0.6 - tearSize * 0.09, y: tearY + tearSize * 0.4 - tearSize * 0.09, width: tearSize * 0.18, height: tearSize * 0.18))
            context.fillEllipse(in: CGRect(x: tearRightX + tearSize * 0.6 - tearSize * 0.09, y: tearY + tearSize * 0.4 - tearSize * 0.09, width: tearSize * 0.18, height: tearSize * 0.18))
            context.restoreGState()
        case .devil:
            let leftHorn = UIBezierPath()
            leftHorn.move(to: CGPoint(x: cx - radius * 0.58, y: cy - radius * 0.75))
            leftHorn.addCurve(to: CGPoint(x: cx - radius * 0.82, y: cy - radius * 1.40),
                              controlPoint1: CGPoint(x: cx - radius * 0.85, y: cy - radius * 1.15),
                              controlPoint2: CGPoint(x: cx - radius * 0.95, y: cy - radius * 1.35))
            leftHorn.addCurve(to: CGPoint(x: cx - radius * 0.38, y: cy - radius * 0.82),
                              controlPoint1: CGPoint(x: cx - radius * 0.65, y: cy - radius * 1.25),
                              controlPoint2: CGPoint(x: cx - radius * 0.42, y: cy - radius * 0.95))
            leftHorn.close()

            let rightHorn = UIBezierPath()
            rightHorn.move(to: CGPoint(x: cx + radius * 0.58, y: cy - radius * 0.75))
            rightHorn.addCurve(to: CGPoint(x: cx + radius * 0.82, y: cy - radius * 1.40),
                               controlPoint1: CGPoint(x: cx + radius * 0.85, y: cy - radius * 1.15),
                               controlPoint2: CGPoint(x: cx + radius * 0.95, y: cy - radius * 1.35))
            rightHorn.addCurve(to: CGPoint(x: cx + radius * 0.38, y: cy - radius * 0.82),
                               controlPoint1: CGPoint(x: cx + radius * 0.65, y: cy - radius * 1.25),
                               controlPoint2: CGPoint(x: cx + radius * 0.42, y: cy - radius * 0.95))
            rightHorn.close()

            context.saveGState()
            context.setFillColor(UIColor(red: 0.48, green: 0.12, blue: 0.64, alpha: 1.0).cgColor)
            context.addPath(leftHorn.cgPath)
            context.addPath(rightHorn.cgPath)
            context.fillPath()
            context.restoreGState()
        case .clown:
            let noseX = cx + shiftX
            let noseY = cy + shiftY + radius * 0.05
            context.saveGState()
            context.setFillColor(UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1.0).cgColor)
            context.fillEllipse(in: CGRect(x: noseX - radius * 0.20, y: noseY - radius * 0.20, width: radius * 0.40, height: radius * 0.40))
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: CGRect(x: noseX - radius * 0.10, y: noseY - radius * 0.10, width: radius * 0.10, height: radius * 0.10))

            // Orange clown hair curls
            context.setFillColor(UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0).cgColor)
            context.fillEllipse(in: CGRect(x: cx - radius * 1.24, y: cy - radius * 0.51, width: radius * 0.52, height: radius * 0.52))
            context.fillEllipse(in: CGRect(x: cx - radius * 1.29, y: cy - radius * 0.19, width: radius * 0.48, height: radius * 0.48))
            context.fillEllipse(in: CGRect(x: cx + radius * 0.72, y: cy - radius * 0.51, width: radius * 0.52, height: radius * 0.52))
            context.fillEllipse(in: CGRect(x: cx + radius * 0.81, y: cy - radius * 0.19, width: radius * 0.48, height: radius * 0.48))
            context.restoreGState()
        case .party:
            let hat = UIBezierPath()
            hat.move(to: CGPoint(x: cx - radius * 0.55, y: cy - radius * 0.75))
            hat.addLine(to: CGPoint(x: cx, y: cy - radius * 1.65))
            hat.addLine(to: CGPoint(x: cx + radius * 0.55, y: cy - radius * 0.75))
            hat.close()

            context.saveGState()
            context.setFillColor(UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1.0).cgColor)
            context.addPath(hat.cgPath)
            context.fillPath()

            context.setFillColor(UIColor(red: 1.0, green: 0.92, blue: 0.23, alpha: 1.0).cgColor)
            context.fillEllipse(in: CGRect(x: cx - radius * 0.12, y: cy - radius * 1.77, width: radius * 0.24, height: radius * 0.24))
            context.restoreGState()
        case .robot:
            context.saveGState()
            context.setStrokeColor(UIColor(red: 0.47, green: 0.56, blue: 0.61, alpha: 1.0).cgColor)
            context.setLineWidth(radius * 0.06)
            context.move(to: CGPoint(x: cx, y: cy - radius * 0.95))
            context.addLine(to: CGPoint(x: cx, y: cy - radius * 1.35))
            context.strokePath()

            context.setFillColor(UIColor(red: 1.0, green: 0.09, blue: 0.27, alpha: 1.0).cgColor)
            context.fillEllipse(in: CGRect(x: cx - radius * 0.12, y: cy - radius * 1.47, width: radius * 0.24, height: radius * 0.24))
            context.restoreGState()
        case .scream:
            context.saveGState()
            context.setFillColor(UIColor(red: 0.56, green: 0.79, blue: 0.98, alpha: 1.0).cgColor)
            let leftHand = CGRect(x: cx - radius * 1.05, y: cy + radius * 0.05, width: radius * 0.40, height: radius * 0.70)
            let rightHand = CGRect(x: cx + radius * 0.65, y: cy + radius * 0.05, width: radius * 0.40, height: radius * 0.70)
            context.fill(UIBezierPath(roundedRect: leftHand, cornerRadius: 24.0).cgPath)
            context.fill(UIBezierPath(roundedRect: rightHand, cornerRadius: 24.0).cgPath)
            context.restoreGState()
        default:
            break
        }
    }

    private static func drawCatFeatures(in context: CGContext, cx: CGFloat, cy: CGFloat, shiftX: CGFloat, shiftY: CGFloat, radius: CGFloat) {
        context.saveGState()

        let earColor = UIColor(red: 1.0, green: 0.84, blue: 0.31, alpha: 1.0).cgColor
        let innerEarColor = UIColor(red: 1.0, green: 0.50, blue: 0.67, alpha: 1.0).cgColor

        // Left Ear
        let leftEar = UIBezierPath()
        leftEar.move(to: CGPoint(x: cx - radius * 0.72, y: cy - radius * 0.70))
        leftEar.addLine(to: CGPoint(x: cx - radius * 0.92, y: cy - radius * 1.45))
        leftEar.addLine(to: CGPoint(x: cx - radius * 0.28, y: cy - radius * 0.95))
        leftEar.close()

        let leftInner = UIBezierPath()
        leftInner.move(to: CGPoint(x: cx - radius * 0.68, y: cy - radius * 0.78))
        leftInner.addLine(to: CGPoint(x: cx - radius * 0.85, y: cy - radius * 1.32))
        leftInner.addLine(to: CGPoint(x: cx - radius * 0.36, y: cy - radius * 0.96))
        leftInner.close()

        context.setFillColor(earColor)
        context.addPath(leftEar.cgPath)
        context.fillPath()
        context.setFillColor(innerEarColor)
        context.addPath(leftInner.cgPath)
        context.fillPath()

        // Right Ear
        let rightEar = UIBezierPath()
        rightEar.move(to: CGPoint(x: cx + radius * 0.72, y: cy - radius * 0.70))
        rightEar.addLine(to: CGPoint(x: cx + radius * 0.92, y: cy - radius * 1.45))
        rightEar.addLine(to: CGPoint(x: cx + radius * 0.28, y: cy - radius * 0.95))
        rightEar.close()

        let rightInner = UIBezierPath()
        rightInner.move(to: CGPoint(x: cx + radius * 0.68, y: cy - radius * 0.78))
        rightInner.addLine(to: CGPoint(x: cx + radius * 0.85, y: cy - radius * 1.32))
        rightInner.addLine(to: CGPoint(x: cx + radius * 0.36, y: cy - radius * 0.96))
        rightInner.close()

        context.setFillColor(earColor)
        context.addPath(rightEar.cgPath)
        context.fillPath()
        context.setFillColor(innerEarColor)
        context.addPath(rightInner.cgPath)
        context.fillPath()

        // Whiskers
        let cheekY = cy + shiftY + radius * 0.15
        let whiskerLen = radius * 0.42
        context.setStrokeColor(UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor)
        context.setLineWidth(radius * 0.045)
        context.setLineCap(.round)

        // Left
        context.move(to: CGPoint(x: cx + shiftX - radius * 0.50, y: cheekY - radius * 0.08))
        context.addLine(to: CGPoint(x: cx + shiftX - radius * 0.50 - whiskerLen, y: cheekY - radius * 0.18))
        context.move(to: CGPoint(x: cx + shiftX - radius * 0.52, y: cheekY))
        context.addLine(to: CGPoint(x: cx + shiftX - radius * 0.52 - whiskerLen, y: cheekY))
        context.move(to: CGPoint(x: cx + shiftX - radius * 0.50, y: cheekY + radius * 0.08))
        context.addLine(to: CGPoint(x: cx + shiftX - radius * 0.50 - whiskerLen, y: cheekY + radius * 0.18))

        // Right
        context.move(to: CGPoint(x: cx + shiftX + radius * 0.50, y: cheekY - radius * 0.08))
        context.addLine(to: CGPoint(x: cx + shiftX + radius * 0.50 + whiskerLen, y: cheekY - radius * 0.18))
        context.move(to: CGPoint(x: cx + shiftX + radius * 0.52, y: cheekY))
        context.addLine(to: CGPoint(x: cx + shiftX + radius * 0.52 + whiskerLen, y: cheekY))
        context.move(to: CGPoint(x: cx + shiftX + radius * 0.50, y: cheekY + radius * 0.08))
        context.addLine(to: CGPoint(x: cx + shiftX + radius * 0.50 + whiskerLen, y: cheekY + radius * 0.18))
        context.strokePath()

        // Pink Cat Nose
        let noseY = cy + shiftY + radius * 0.08
        let nosePath = UIBezierPath()
        nosePath.move(to: CGPoint(x: cx + shiftX - radius * 0.09, y: noseY - radius * 0.05))
        nosePath.addLine(to: CGPoint(x: cx + shiftX + radius * 0.09, y: noseY - radius * 0.05))
        nosePath.addLine(to: CGPoint(x: cx + shiftX, y: noseY + radius * 0.06))
        nosePath.close()

        context.setFillColor(UIColor(red: 1.0, green: 0.25, blue: 0.50, alpha: 1.0).cgColor)
        context.addPath(nosePath.cgPath)
        context.fillPath()
        context.restoreGState()
    }

    private static func drawSunglasses(in context: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat) {
        let glassW = radius * 0.44
        let glassH = radius * 0.32
        let glassY = cy - radius * 0.08

        context.saveGState()
        context.setFillColor(UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0).cgColor)

        let leftRect = CGRect(x: cx - radius * 0.52 - glassW / 2, y: glassY - glassH / 2, width: glassW, height: glassH)
        let rightRect = CGRect(x: cx + radius * 0.52 - glassW / 2, y: glassY - glassH / 2, width: glassW, height: glassH)
        context.fill(UIBezierPath(roundedRect: leftRect, cornerRadius: 12.0).cgPath)
        context.fill(UIBezierPath(roundedRect: rightRect, cornerRadius: 12.0).cgPath)

        // Bridge
        context.setStrokeColor(UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0).cgColor)
        context.setLineWidth(radius * 0.06)
        context.move(to: CGPoint(x: cx - radius * 0.25, y: glassY - glassH * 0.15))
        context.addLine(to: CGPoint(x: cx + radius * 0.25, y: glassY - glassH * 0.15))
        context.strokePath()

        // White glare streaks
        context.setStrokeColor(UIColor(white: 1.0, alpha: 0.55).cgColor)
        context.setLineWidth(radius * 0.035)
        context.move(to: CGPoint(x: leftRect.minX + glassW * 0.2, y: leftRect.minY + glassH * 0.2))
        context.addLine(to: CGPoint(x: leftRect.minX + glassW * 0.45, y: leftRect.maxY - glassH * 0.2))
        context.move(to: CGPoint(x: rightRect.minX + glassW * 0.2, y: rightRect.minY + glassH * 0.2))
        context.addLine(to: CGPoint(x: rightRect.minX + glassW * 0.45, y: rightRect.maxY - glassH * 0.2))
        context.strokePath()
        context.restoreGState()
    }

    private static func drawHeart(in context: CGContext, x: CGFloat, y: CGFloat, size: CGFloat, color: UIColor) {
        let p = createHeartPath(x: x, y: y, size: size)
        context.saveGState()
        context.setFillColor(color.cgColor)
        context.addPath(p.cgPath)
        context.fillPath()
        context.restoreGState()
    }

    private static func drawStar(in context: CGContext, x: CGFloat, y: CGFloat, size: CGFloat) {
        let points = 5
        let innerSize = size * 0.45
        let angleStep = .pi / Double(points)
        let p = UIBezierPath()

        for i in 0..<(points * 2) {
            let r = (i % 2 == 0) ? size : innerSize
            let angle = Double(i) * angleStep - .pi / 2.0
            let px = x + CGFloat(Double(r) * cos(angle))
            let py = y + CGFloat(Double(r) * sin(angle))
            if i == 0 {
                p.move(to: CGPoint(x: px, y: py))
            } else {
                p.addLine(to: CGPoint(x: px, y: py))
            }
        }
        p.close()

        context.saveGState()
        context.setFillColor(UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0).cgColor)
        context.addPath(p.cgPath)
        context.fillPath()
        context.restoreGState()
    }
}
