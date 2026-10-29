import Cocoa
import FlutterMacOS
import AVFoundation
import PDFKit
import ImageIO
import Vision

class MainFlutterWindow: NSWindow {
  private var nativeChannel: FlutterMethodChannel?

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

    nativeChannel = FlutterMethodChannel(
      name: "frapp/native",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    nativeChannel?.setMethodCallHandler { call, result in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let output: Any
          switch call.method {
          case "recognizeText":
            output = try Self.recognizeText(call.arguments)
          case "extractVideoFrame":
            output = try Self.extractVideoFrame(call.arguments)
          case "renderPdfPage":
            output = try Self.renderPdfPage(call.arguments)
          case "pdfPageCount":
            let count = try Self.pdfPageCount(call.arguments)
            DispatchQueue.main.async { result(count) }
            return
          default:
            DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
            return
          }
          DispatchQueue.main.async { result(output) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "native_media_failed",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      }
    }

    super.awakeFromNib()
  }

  private static func extractVideoFrame(_ arguments: Any?) throws -> FlutterStandardTypedData {
    guard
      let values = arguments as? [String: Any],
      let path = values["path"] as? String,
      let positionMs = values["positionMs"] as? NSNumber,
      positionMs.int64Value >= 0
    else {
      throw NSError(
        domain: "FrameReader",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "A valid video path and position are required."]
      )
    }

    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: 3000, height: 3000)
    let time = CMTime(value: positionMs.int64Value, timescale: 1000)
    let image = try generator.copyCGImage(at: time, actualTime: nil)
    let representation = NSBitmapImageRep(cgImage: image)
    guard let data = representation.representation(
      using: .jpeg,
      properties: [.compressionFactor: 0.92]
    ) else {
      throw NSError(
        domain: "FrameReader",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "The video frame could not be encoded."]
      )
    }
    return FlutterStandardTypedData(bytes: data)
  }

  private static func recognizeText(_ arguments: Any?) throws -> [String: Any] {
    guard
      let values = arguments as? [String: Any],
      let typedData = values["bytes"] as? FlutterStandardTypedData,
      let source = CGImageSourceCreateWithData(typedData.data as CFData, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      throw NSError(
        domain: "FrameReader",
        code: 6,
        userInfo: [NSLocalizedDescriptionKey: "The image could not be decoded."]
      )
    }

    let language = values["language"] as? String ?? "en"
    let locale = [
      "en": "en-US",
      "ur": "ur",
      "ar": "ar",
      "es": "es-ES",
      "fr": "fr-FR",
      "de": "de-DE",
      "zh": "zh-Hans",
      "hi": "hi-IN",
    ][language] ?? "en-US"
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    let supportedLanguages = try request.supportedRecognitionLanguages()
    guard supportedLanguages.contains(locale) else {
      throw NSError(
        domain: "FrameReader",
        code: 7,
        userInfo: [NSLocalizedDescriptionKey: "Text recognition for \(language) is unavailable on this Mac."]
      )
    }
    request.recognitionLanguages = [locale]
    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])

    var words: [[String: Any]] = []
    let observations = request.results ?? []
    for observation in observations {
      guard let candidate = observation.topCandidates(1).first else { continue }
      let text = candidate.string
      let nsText = text as NSString
      let lineBounds = observation.boundingBox
      let left = lineBounds.minX * CGFloat(image.width)
      let top = (1 - lineBounds.maxY) * CGFloat(image.height)
      let lineWidth = lineBounds.width * CGFloat(image.width)
      let lineHeight = lineBounds.height * CGFloat(image.height)
      var searchLocation = 0

      for token in text.split(whereSeparator: { $0.isWhitespace }).map(String.init) {
        let searchRange = NSRange(
          location: searchLocation,
          length: nsText.length - searchLocation
        )
        let tokenRange = nsText.range(of: token, options: [], range: searchRange)
        guard tokenRange.location != NSNotFound, nsText.length > 0 else { continue }
        searchLocation = tokenRange.location + tokenRange.length
        let start = CGFloat(tokenRange.location) / CGFloat(nsText.length)
        let width = CGFloat(tokenRange.length) / CGFloat(nsText.length)
        words.append([
          "text": token,
          "x": left + lineWidth * start,
          "y": top,
          "width": lineWidth * width,
          "height": lineHeight,
          "confidence": candidate.confidence,
        ])
      }
    }

    return [
      "text": observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n"),
      "words": words,
      "imageWidth": image.width,
      "imageHeight": image.height,
    ]
  }

  private static func renderPdfPage(_ arguments: Any?) throws -> FlutterStandardTypedData {
    guard
      let values = arguments as? [String: Any],
      let typedData = values["bytes"] as? FlutterStandardTypedData,
      let pageIndex = values["pageIndex"] as? Int,
      pageIndex >= 0,
      let document = PDFDocument(data: typedData.data),
      let page = document.page(at: pageIndex)
    else {
      throw NSError(
        domain: "FrameReader",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "The PDF page could not be opened."]
      )
    }

    let bounds = page.bounds(for: .mediaBox)
    let scale = min(2, 3000 / max(bounds.width, bounds.height))
    let size = CGSize(
      width: max(1, bounds.width * scale),
      height: max(1, bounds.height * scale)
    )
    let thumbnail = page.thumbnail(of: size, for: .mediaBox)
    guard let cgImage = thumbnail.cgImage(
      forProposedRect: nil,
      context: nil,
      hints: nil
    ) else {
      throw NSError(
        domain: "FrameReader",
        code: 4,
        userInfo: [NSLocalizedDescriptionKey: "The PDF page could not be rendered."]
      )
    }
    let representation = NSBitmapImageRep(cgImage: cgImage)
    guard let data = representation.representation(
      using: .jpeg,
      properties: [.compressionFactor: 0.92]
    ) else {
      throw NSError(
        domain: "FrameReader",
        code: 4,
        userInfo: [NSLocalizedDescriptionKey: "The PDF page could not be rendered."]
      )
    }
    return FlutterStandardTypedData(bytes: data)
  }

  private static func pdfPageCount(_ arguments: Any?) throws -> Int {
    guard
      let values = arguments as? [String: Any],
      let typedData = values["bytes"] as? FlutterStandardTypedData,
      let document = PDFDocument(data: typedData.data),
      document.pageCount > 0
    else {
      throw NSError(
        domain: "FrameReader",
        code: 5,
        userInfo: [NSLocalizedDescriptionKey: "The PDF does not contain any readable pages."]
      )
    }
    return document.pageCount
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
