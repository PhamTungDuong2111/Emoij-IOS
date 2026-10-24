import SwiftUI
import AVFoundation

public struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }

    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.videoPreviewLayer.session = cameraManager.captureSession
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        if uiView.videoPreviewLayer.session != cameraManager.captureSession {
            uiView.videoPreviewLayer.session = cameraManager.captureSession
        }
    }
}

public class CameraPreviewUIView: UIView {
    override public class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

// Simulated camera view when running in Xcode Simulator or when device has no camera
public struct SimulatedCameraBackgroundView: View {
    @State private var phase: CGFloat = 0.0

    public var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.20),
                    Color(red: 0.20, green: 0.24, blue: 0.35),
                    Color(red: 0.10, green: 0.11, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white.opacity(0.35))
                Text("Simulator Camera Mode")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                Text("Simulating live face tracking")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}
