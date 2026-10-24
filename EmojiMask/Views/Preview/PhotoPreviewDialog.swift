import SwiftUI
import UIKit

public struct PhotoPreviewDialog: View {
    let photo: UIImage
    let onDismiss: () -> Void

    @ObservedObject var localization = LocalizationManager.shared
    @State private var toastMessage: String?
    @State private var showShareSheet = false

    public init(photo: UIImage, onDismiss: @escaping () -> Void) {
        self.photo = photo
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Captured Photo
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()

            // Top Control Bar
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .glassCard(cornerRadius: 20)
                    }

                    Spacer()

                    Text(localization.string(for: "preview_title"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    // Balance placeholder
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 50)

                Spacer()

                // Toast Banner
                if let msg = toastMessage {
                    Text(msg)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.emojiGold, lineWidth: 1))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 12)
                }

                // Bottom Action Buttons
                HStack(spacing: 16) {
                    // Retake
                    Button(action: onDismiss) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text(localization.string(for: "retake_photo"))
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .glassCard(cornerRadius: 16)
                    }

                    // Save
                    Button(action: savePhoto) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                            Text(localization.string(for: "save_photo"))
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.emojiGold)
                        .cornerRadius(16)
                    }

                    // Share
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text(localization.string(for: "share_photo"))
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .glassCard(cornerRadius: 16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                photo,
                localization.string(for: "share_text")
            ])
        }
    }

    private func savePhoto() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        PhotoManager.shared.savePhotoToGallery(image: photo) { success in
            withAnimation {
                self.toastMessage = localization.string(for: success ? "photo_saved_success" : "photo_save_failed")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    self.toastMessage = nil
                }
            }
        }
    }
}

// UIActivityViewController Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
