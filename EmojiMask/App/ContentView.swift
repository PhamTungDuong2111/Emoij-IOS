import SwiftUI

public struct ContentView: View {
    @StateObject private var cameraManager = CameraManager.shared
    @StateObject private var localization = LocalizationManager.shared

    @State private var selectedMask: EmojiMaskType = .grinning
    @State private var isCutoutMode: Bool = true
    @State private var faceStates: [FaceExpressionState] = []
    @State private var imageWidth: Int = 1080
    @State private var imageHeight: Int = 1920

    @State private var isShutterFlashing = false
    @State private var capturedCompositedPhoto: UIImage?
    @State private var showPreviewDialog = false
    @State private var modeToastMessage: String?

    private let tracker = FaceExpressionTracker()
    @State private var simulatorTimer: Timer?

    public init() {}

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 1. Camera Feed / Simulated Background
            if cameraManager.permissionGranted {
                #if targetEnvironment(simulator)
                SimulatedCameraBackgroundView()
                #else
                if cameraManager.isSimulator {
                    SimulatedCameraBackgroundView()
                } else {
                    CameraPreviewView(cameraManager: cameraManager)
                        .ignoresSafeArea()
                }
                #endif
            } else {
                SimulatedCameraBackgroundView()
            }

            // 2. Real-time AR Emoji Mask Overlay
            EmojiMaskOverlayView(
                maskType: selectedMask,
                isCutoutMode: isCutoutMode,
                faceStates: faceStates,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                isFrontCamera: cameraManager.isFrontCamera
            )
            .ignoresSafeArea()

            // 3. Shutter Flash Animation Overlay
            if isShutterFlashing {
                Color.white
                    .ignoresSafeArea()
                    .opacity(0.85)
                    .transition(.opacity)
            }

            // 4. Mode Switch Toast Notification
            VStack {
                if let modeToast = modeToastMessage {
                    Text(modeToast)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.emojiGold, lineWidth: 1))
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 100)
                }
                Spacer()
            }

            // 5. Main Controls UI Layer
            VStack(spacing: 0) {
                // Top Bar Row
                TopBarView(
                    faceStates: faceStates,
                    isCutoutMode: $isCutoutMode,
                    onModeToggled: { isCutout in
                        showModeToast(isCutout: isCutout)
                    }
                )
                .padding(.top, 12)

                Spacer()

                // Bottom Carousel & Shutter Controls
                VStack(spacing: 14) {
                    // 18 Emoji Carousel Picker
                    MaskCarouselView(
                        selectedMask: $selectedMask,
                        onMaskSelected: { _ in }
                    )

                    // Bottom Bar (Flip & Shutter)
                    BottomBarView(
                        onCapturePressed: {
                            capturePhoto()
                        },
                        onFlipCameraPressed: {
                            cameraManager.flipCamera()
                            tracker.isFrontCamera = cameraManager.isFrontCamera
                        }
                    )
                }
                .padding(.bottom, 24)
            }

            // 6. Camera Permission Card (Shown if not authorized)
            if !cameraManager.permissionGranted {
                Color.black.opacity(0.65).ignoresSafeArea()
                CameraPermissionCard {
                    cameraManager.checkCameraPermission()
                }
            }
        }
        .fullScreenCover(isPresented: $showPreviewDialog) {
            if let photo = capturedCompositedPhoto {
                PhotoPreviewDialog(photo: photo) {
                    showPreviewDialog = false
                    capturedCompositedPhoto = nil
                }
            }
        }
        .onAppear {
            setupCameraFrameProcessing()
        }
        .onDisappear {
            simulatorTimer?.invalidate()
        }
    }

    private func setupCameraFrameProcessing() {
        tracker.isFrontCamera = cameraManager.isFrontCamera

        cameraManager.onFrameCaptured = { pixelBuffer, orientation in
            tracker.processPixelBuffer(pixelBuffer, orientation: orientation) { states, w, h, isFront in
                DispatchQueue.main.async {
                    self.faceStates = states
                    self.imageWidth = w
                    self.imageHeight = h
                }
            }
        }

        // Simulator synthetic face movement animation
        #if targetEnvironment(simulator)
        startSimulatorFaceAnimation()
        #else
        if cameraManager.isSimulator {
            startSimulatorFaceAnimation()
        }
        #endif
    }

    private func startSimulatorFaceAnimation() {
        var angle: CGFloat = 0.0
        self.imageWidth = 1080
        self.imageHeight = 1920

        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            angle += 0.04
            let smile = (sin(angle * 1.5) + 1.0) / 2.0
            let pucker = (cos(angle * 1.2) + 1.0) / 2.0 * 0.45
            let mouthOpen = (sin(angle * 2.0) + 1.0) / 2.0 * 0.5
            let roll = sin(angle) * 8.0
            let yaw = cos(angle * 0.8) * 12.0
            let pitch = sin(angle * 0.6) * 6.0

            let syntheticState = FaceExpressionState(
                isFaceDetected: true,
                trackingId: 1,
                centerX: 540 + sin(angle) * 30.0,
                centerY: 900 + cos(angle * 0.7) * 20.0,
                faceWidth: 420,
                faceHeight: 520,
                pitch: pitch,
                yaw: yaw,
                roll: roll,
                smileRatio: smile,
                leftEyeOpenRatio: 1.0,
                rightEyeOpenRatio: 1.0,
                mouthOpenRatio: mouthOpen,
                mouthPuckerRatio: pucker,
                browFurrowRatio: 0.0,
                eyebrowsRaisedRatio: 0.0,
                mouthFrownRatio: 0.0
            )

            self.faceStates = [syntheticState]
        }
    }

    private func capturePhoto() {
        playShutterFlashEffect()

        cameraManager.capturePhoto { rawPhoto in
            guard let basePhoto = rawPhoto else { return }

            // Composite exact mask onto the photo
            let composited = ImageCompositor.compositeMaskOnPhoto(
                photo: basePhoto,
                faceStates: self.faceStates,
                maskType: self.selectedMask,
                isCutoutMode: self.isCutoutMode,
                isFrontCam: self.cameraManager.isFrontCamera,
                imageW: self.imageWidth,
                imageH: self.imageHeight
            )

            self.capturedCompositedPhoto = composited
            self.showPreviewDialog = true
        }
    }

    private func playShutterFlashEffect() {
        withAnimation(.easeIn(duration: 0.08)) {
            isShutterFlashing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.16)) {
                isShutterFlashing = false
            }
        }
    }

    private func showModeToast(isCutout: Bool) {
        let msgKey = isCutout ? "mode_switched_ar" : "mode_switched_cartoon"
        withAnimation {
            self.modeToastMessage = localization.string(for: msgKey)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                self.modeToastMessage = nil
            }
        }
    }
}
