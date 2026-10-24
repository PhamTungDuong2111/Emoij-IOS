import SwiftUI

public struct CameraPermissionCard: View {
    @ObservedObject var localization = LocalizationManager.shared
    let onGrantPressed: () -> Void

    public init(onGrantPressed: @escaping () -> Void) {
        self.onGrantPressed = onGrantPressed
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("🎭")
                .font(.system(size: 54))

            Text(localization.string(for: "permission_camera_title"))
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(localization.string(for: "permission_camera_message"))
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button(action: onGrantPressed) {
                Text(localization.string(for: "grant_permission"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.emojiGold)
                    .cornerRadius(16)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.12, green: 0.13, blue: 0.18))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 32)
    }
}
