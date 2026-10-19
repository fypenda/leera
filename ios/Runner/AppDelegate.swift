import Flutter
import Speech
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SpeechTranscriber") {
      SpeechTranscriber.register(with: registrar)
    }
  }
}

/// Transcribes a recorded presentation with Apple's speech recognition, on
/// the device whenever the device can (lib/core/audio/transcriber.dart).
///
/// Channel "app/transcription":
/// - "requestPermission" → Bool: asks for speech recognition the first time.
/// - "transcribe" {path, locale} → String: the text heard, "" if nothing was;
///   errors "not_authorized", "unavailable", "failed".
final class SpeechTranscriber: NSObject {
  private static var instance: SpeechTranscriber?
  private var channel: FlutterMethodChannel?
  private var task: SFSpeechRecognitionTask?

  static func register(with registrar: FlutterPluginRegistrar) {
    let transcriber = SpeechTranscriber()
    let channel = FlutterMethodChannel(
      name: "app/transcription",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler(transcriber.handle)
    transcriber.channel = channel
    instance = transcriber
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPermission":
      SFSpeechRecognizer.requestAuthorization { status in
        DispatchQueue.main.async { result(status == .authorized) }
      }
    case "transcribe":
      guard let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String
      else {
        result(FlutterError(code: "failed", message: "No file given.", details: nil))
        return
      }
      let locale = arguments["locale"] as? String ?? "en-US"
      transcribe(path: path, locale: locale, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func transcribe(path: String, locale: String, result: @escaping FlutterResult) {
    guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
      result(FlutterError(code: "not_authorized", message: nil, details: nil))
      return
    }
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)),
      recognizer.isAvailable
    else {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
      return
    }

    let request = SFSpeechURLRecognitionRequest(url: URL(fileURLWithPath: path))
    request.shouldReportPartialResults = false
    // On the device whenever it can: the recording then never leaves it.
    if recognizer.supportsOnDeviceRecognition {
      request.requiresOnDeviceRecognition = true
    }
    if #available(iOS 16, *) {
      request.addsPunctuation = true
    }

    var answered = false
    func answer(_ value: Any?) {
      if answered { return }
      answered = true
      task = nil
      DispatchQueue.main.async { result(value) }
    }

    task?.cancel()
    task = recognizer.recognitionTask(with: request) { recognition, error in
      if let recognition, recognition.isFinal {
        answer(recognition.bestTranscription.formattedString)
      } else if let error {
        let nsError = error as NSError
        // "No speech detected": nothing was heard, which is an answer.
        if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
          answer("")
        } else {
          answer(
            FlutterError(code: "failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
