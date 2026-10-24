import SwiftUI

public struct TopBarView: View {
    @ObservedObject var localization = LocalizationManager.shared
    @ObservedObject var cameraManager = CameraManager.shared
    let faceStates: [FaceExpressionState]
    @Binding var isCutoutMode: Bool
    let onModeToggled: (Bool) -> Void

    public init(
        faceStates: [FaceExpressionState],
        isCutoutMode: Binding<Bool>,
        onModeToggled: @escaping (Bool) -> Void
    ) {
        self.faceStates = faceStates
        self._isCutoutMode = isCutoutMode
        self.onModeToggled = onModeToggled
    }

    private var primaryEmotionText: String {
        guard let first = faceStates.first, first.isFaceDetected else {
            return localization.string(for: "no_face_detected")
        }
        let emotionStr = localization.string(for: first.getDetectedEmotionKey())
        if faceStates.count > 1 {
            return "\(emotionStr) (\(faceStates.count))"
        }
        return emotionStr
    }

    private var hasFace: Bool {
        return faceStates.contains(where: { $0.isFaceDetected })
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Main Top Bar Row
            HStack(spacing: 12) {
                // Language Toggle Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    localization.toggleLanguage()
                }) {
                    Text(localization.currentLanguage.displayName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .glassCard(cornerRadius: 16)
                }

                Spacer()

                // Real-time Facial Expression Status Badge
                HStack(spacing: 8) {
                    Circle()
                        .fill(hasFace ? Color.trackingGreen : Color.gray.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .shadow(color: hasFace ? Color.trackingGreen : Color.clear, radius: 4)

                    Text(primaryEmotionText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 18)

                Spacer()

                // Flash Mode Toggle Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    cameraManager.cycleFlashMode()
                }) {
                    Image(systemName: cameraManager.flashState.systemIconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .glassCard(cornerRadius: 19)
                }
            }
            .padding(.horizontal, 16)

            // Sub-row: AR Mask Mode Toggle & Offline Badge
            HStack(spacing: 10) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    isCutoutMode.toggle()
                    onModeToggled(isCutoutMode)
                }) {
                    HStack(spacing: 6) {
                        Text(isCutoutMode ? localization.string(for: "mode_ar_cutout") : localization.string(for: "mode_cartoon"))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isCutoutMode ? Color.emojiGold : Color.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .glassCard(cornerRadius: 14)
                }

                // 100% On-Device Badge
                Text(localization.string(for: "offline_badge"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassCard(cornerRadius: 14)
            }
        }
    }
}
