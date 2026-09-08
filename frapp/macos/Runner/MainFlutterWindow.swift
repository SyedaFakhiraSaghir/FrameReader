import Cocoa
import FlutterMacOS
import AVFoundation

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let cameraService = CameraCaptureService()
    let cameraChannel = FlutterMethodChannel(
      name: "frapp/camera",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    cameraChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "capturePhoto":
        cameraService.capturePhoto(result: result)
      case "captureVideo":
        cameraService.captureVideo(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}

private final class CameraCaptureService: NSObject, AVCapturePhotoCaptureDelegate,
  AVCaptureFileOutputRecordingDelegate {
  private let session = AVCaptureSession()
  private let photoOutput = AVCapturePhotoOutput()
  private let movieOutput = AVCaptureMovieFileOutput()
  private var completion: FlutterResult?

  func capturePhoto(result: @escaping FlutterResult) {
    requestAccess(includeAudio: false) { [weak self] granted in
      guard let self else { return result("Camera access was denied.") }
      guard granted else { return result("Camera access was denied.") }
      guard self.configureSession(includeAudio: false) else {
        return result("No camera is available on this Mac.")
      }
      self.completion = result
      self.session.startRunning()
      self.photoOutput.capturePhoto(
        with: AVCapturePhotoSettings(),
        delegate: self
      )
    }
  }

  func captureVideo(result: @escaping FlutterResult) {
    requestAccess(includeAudio: true) { [weak self] granted in
      guard let self else { return result("Camera access was denied.") }
      guard granted else { return result("Camera and microphone access were denied.") }
      guard self.configureSession(includeAudio: true) else {
        return result("No camera or microphone is available on this Mac.")
      }
      self.completion = result
      self.session.startRunning()
      let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("frapp-video-\(UUID().uuidString).mov")
      self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
      DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
        guard let self, self.movieOutput.isRecording else { return }
        self.movieOutput.stopRecording()
      }
    }
  }

  private func requestAccess(
    includeAudio: Bool,
    completion: @escaping (Bool) -> Void
  ) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
      guard granted else {
        DispatchQueue.main.async { completion(false) }
        return
      }
      guard includeAudio else {
        DispatchQueue.main.async { completion(true) }
        return
      }
      AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
        DispatchQueue.main.async { completion(audioGranted) }
      }
    }
  }

  private func configureSession(includeAudio: Bool) -> Bool {
    session.beginConfiguration()
    defer { session.commitConfiguration() }
    session.inputs.forEach { session.removeInput($0) }
    session.outputs.forEach { session.removeOutput($0) }

    guard let camera = AVCaptureDevice.default(for: .video),
          let cameraInput = try? AVCaptureDeviceInput(device: camera),
          session.canAddInput(cameraInput) else { return false }
    session.addInput(cameraInput)

    if includeAudio,
       let microphone = AVCaptureDevice.default(for: .audio),
       let audioInput = try? AVCaptureDeviceInput(device: microphone),
       session.canAddInput(audioInput) {
      session.addInput(audioInput)
    }

    if session.canAddOutput(photoOutput) {
      session.addOutput(photoOutput)
    }
    if includeAudio, session.canAddOutput(movieOutput) {
      session.addOutput(movieOutput)
    }
    return true
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    defer {
      session.stopRunning()
      completion = nil
    }
    guard error == nil, let data = photo.fileDataRepresentation() else {
      completion?(FlutterError(
        code: "CAPTURE_FAILED",
        message: "The photo could not be captured.",
        details: nil
      ))
      return
    }
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("frapp-photo-\(UUID().uuidString).jpg")
    do {
      try data.write(to: url)
      completion?(url.path)
    } catch {
      completion?(FlutterError(
        code: "SAVE_FAILED",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }

  func fileOutput(
    _ output: AVCaptureFileOutput,
    didFinishRecordingTo outputFileURL: URL,
    from connections: [AVCaptureConnection],
    error: Error?
  ) {
    session.stopRunning()
    defer { completion = nil }
    if let error {
      completion?(FlutterError(
        code: "CAPTURE_FAILED",
        message: error.localizedDescription,
        details: nil
      ))
      return
    }
    completion?(outputFileURL.path)
  }
}
