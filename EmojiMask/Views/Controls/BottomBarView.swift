import SwiftUI

public struct BottomBarView: View {
    let onCapturePressed: () -> Void
    let onFlipCameraPressed: () -> Void

    @State private var isShutterPressed = false

    public init(
        onCapturePressed: @escaping () -> Void,
        onFlipCameraPressed: @escaping () -> Void
    ) {
        self.onCapturePressed = onCapturePressed
        self.onFlipCameraPressed = onFlipCameraPressed
    }

    public var body: some View {
        HStack {
            // Left spacer to balance layout
            Color.clear
                .frame(width: 54, height: 54)

            Spacer()

            // Capture Shutter Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                onCapturePressed()
            }) {
                ZStack {
                    // Outer Ring
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 82, height: 82)

                    // Inner Circle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 66, height: 66)
                        .scaleEffect(isShutterPressed ? 0.90 : 1.0)
                }
            }
            .buttonStyle(ShutterPressStyle(isPressedBinding: $isShutterPressed))

            Spacer()

            // Flip Camera Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onFlipCameraPressed()
            }) {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .glassCard(cornerRadius: 27)
            }
        }
        .padding(.horizontal, 24)
    }
}

struct ShutterPressStyle: ButtonStyle {
    @Binding var isPressedBinding: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                isPressedBinding = newValue
            }
    }
}
