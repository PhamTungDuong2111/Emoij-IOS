import Foundation
import AVFoundation
import UIKit
import Combine

public enum FlashState: String, CaseIterable {
    case auto = "flash_auto"
    case on = "flash_on"
    case off = "flash_off"

    public var systemIconName: String {
        switch self {
        case .auto: return "bolt.badge.a.fill"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        }
    }
}

public class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    public static let shared = CameraManager()

    public let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.emojimask.camera.sessionQueue")
    private let videoOutputQueue = DispatchQueue(label: "com.emojimask.camera.videoOutputQueue", qos: .userInteractive)

    @Published public var isSessionRunning: Bool = false
    @Published public var isFrontCamera: Bool = true
    @Published public var flashState: FlashState = .auto
    @Published public var permissionGranted: Bool = false
    @Published public var isSimulator: Bool = false

    public var onFrameCaptured: ((CVPixelBuffer, CGImagePropertyOrientation) -> Void)?
    private var photoCaptureCompletion: ((UIImage?) -> Void)?

    override public init() {
        super.init()
        #if targetEnvironment(simulator)
        self.isSimulator = true
        self.permissionGranted = true
        #else
        checkCameraPermission()
        #endif
    }

    public func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.permissionGranted = true
            setupAndStartSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupAndStartSession()
                    }
                }
            }
        default:
            self.permissionGranted = false
        }
    }

    public func setupAndStartSession() {
        #if targetEnvironment(simulator)
        self.isSimulator = true
        self.isSessionRunning = true
        return
        #endif

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .high

            let position: AVCaptureDevice.Position = self.isFrontCamera ? .front : .back
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async { self.isSimulator = true }
                return
            }

            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                }

                self.videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)

                if self.captureSession.canAddOutput(self.videoDataOutput) {
                    self.captureSession.addOutput(self.videoDataOutput)
                }

                if self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addOutput(self.photoOutput)
                }

                self.captureSession.commitConfiguration()
                self.captureSession.startRunning()

                DispatchQueue.main.async {
                    self.isSessionRunning = self.captureSession.isRunning
                }
            } catch {
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async { self.isSimulator = true }
            }
        }
    }

    public func flipCamera() {
        isFrontCamera.toggle()
        #if targetEnvironment(simulator)
        return
        #endif

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            let position: AVCaptureDevice.Position = self.isFrontCamera ? .front : .back
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                  let newInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(newInput) else {
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.addInput(newInput)
            self.videoDeviceInput = newInput
            self.captureSession.commitConfiguration()
        }
    }

    public func cycleFlashMode() {
        switch flashState {
        case .auto:
            flashState = .on
            setTorch(enabled: true)
        case .on:
            flashState = .off
            setTorch(enabled: false)
        case .off:
            flashState = .auto
            setTorch(enabled: false)
        }
    }

    private func setTorch(enabled: Bool) {
        guard let device = videoDeviceInput?.device, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            if enabled && device.isTorchModeSupported(.on) {
                device.torchMode = .on
            } else if device.isTorchModeSupported(.off) {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {}
    }

    public func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.photoCaptureCompletion = completion

        #if targetEnvironment(simulator)
        // In simulator, generate a realistic photo
        let mockImage = generateSimulatorPhoto()
        completion(mockImage)
        return
        #else
        let settings = AVCapturePhotoSettings()
        if let input = videoDeviceInput, input.device.hasFlash {
            switch flashState {
            case .auto: settings.flashMode = .auto
            case .on: settings.flashMode = .on
            case .off: settings.flashMode = .off
            }
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
        #endif
    }

    // AVCapturePhotoCaptureDelegate
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoCaptureCompletion?(nil)
            return
        }
        photoCaptureCompletion?(image)
    }

    // AVCaptureVideoDataOutputSampleBufferDelegate
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orientation: CGImagePropertyOrientation = isFrontCamera ? .leftMirrored : .right
        onFrameCaptured?(pixelBuffer, orientation)
    }

    private func generateSimulatorPhoto() -> UIImage {
        let size = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Realistic selfie gradient
            let colors = [
                UIColor(red: 0.15, green: 0.16, blue: 0.22, alpha: 1.0).cgColor,
                UIColor(red: 0.25, green: 0.28, blue: 0.38, alpha: 1.0).cgColor,
                UIColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 1.0).cgColor
            ] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0.0, 0.5, 1.0]) {
                ctx.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
            }
        }
    }
}
