import UIKit
import CoreGraphics

public class ImageCompositor {

    public static func compositeMaskOnPhoto(
        photo: UIImage,
        faceStates: [FaceExpressionState],
        maskType: EmojiMaskType,
        isCutoutMode: Bool,
        isFrontCam: Bool,
        imageW: Int,
        imageH: Int
    ) -> UIImage {
        let size = photo.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            // 1. Draw base photo
            photo.draw(in: CGRect(origin: .zero, size: size))

            let context = ctx.cgContext
            let pw = size.width
            let ph = size.height

            let imgWidth = CGFloat(imageW > 0 ? imageW : Int(pw))
            let imgHeight = CGFloat(imageH > 0 ? imageH : Int(ph))

            let scale = max(pw / imgWidth, ph / imgHeight)
            let offsetX = (pw - imgWidth * scale) / 2.0
            let offsetY = (ph - imgHeight * scale) / 2.0

            for state in faceStates {
                guard state.isFaceDetected else { continue }

                let mappedCenterX: CGFloat = isFrontCam
                    ? (pw - (state.centerX * scale + offsetX))
                    : (state.centerX * scale + offsetX)
                let mappedCenterY: CGFloat = state.centerY * scale + offsetY

                let faceDim = max(state.faceWidth, state.faceHeight)
                let radius = max(pw * 0.18, (faceDim * scale) * 0.72)

                EmojiMaskRenderer.drawEmojiMask(
                    in: context,
                    cx: mappedCenterX,
                    cy: mappedCenterY,
                    radius: radius,
                    state: state,
                    maskType: maskType,
                    isFrontCam: isFrontCam,
                    phase: 0.5,
                    scale: scale,
                    offsetX: offsetX,
                    offsetY: offsetY,
                    viewW: pw,
                    isCutoutMode: isCutoutMode
                )
            }
        }
    }
}
