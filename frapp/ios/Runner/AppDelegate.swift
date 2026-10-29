import Flutter
import AVFoundation
import PDFKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var nativeChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    nativeChannel = FlutterMethodChannel(
      name: "frapp/native",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    nativeChannel?.setMethodCallHandler { call, result in
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let output: FlutterStandardTypedData
          switch call.method {
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
    guard let data = UIImage(cgImage: image).jpegData(compressionQuality: 0.92) else {
      throw NSError(
        domain: "FrameReader",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "The video frame could not be encoded."]
      )
    }
    return FlutterStandardTypedData(bytes: data)
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
    guard let image = page.thumbnail(of: size, for: .mediaBox).jpegData(compressionQuality: 0.92) else {
      throw NSError(
        domain: "FrameReader",
        code: 4,
        userInfo: [NSLocalizedDescriptionKey: "The PDF page could not be rendered."]
      )
    }
    return FlutterStandardTypedData(bytes: image)
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
