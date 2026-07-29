import Foundation

/// Available transcription models to use with OpenAI Whisper API.
enum TranscriptionModel: String, CaseIterable, Identifiable {
    case gptTranscribe = "gpt-transcribe"
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"

    /// Model used when no valid selection has been saved.
    static let defaultModel: TranscriptionModel = .gptTranscribe

    var id: String { rawValue }
    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .gptTranscribe:
            return "gpt-transcribe"
        case .gpt4oTranscribe:
            return "gpt-4o-transcribe"
        case .gpt4oMiniTranscribe:
            return "gpt-4o-mini-transcribe"
        }
    }
}

/// Manages persistence of application settings, such as custom prompt and transcription model selection.
struct SettingsManager {
    private static let promptFileName = "prompt.txt"
    private static let modelFileName = "model.txt"
    private static let appDirectoryName = "WhisperDictate"

    /// Returns the URL to the application-specific directory in Application Support.
    private static var directoryURL: URL? {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            guard let dir = appSupport?.appendingPathComponent(appDirectoryName, isDirectory: true) else {
                return nil
            }
            // Ensure the directory exists
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            return dir
        } catch {
            logError("Failed to create Settings directory: \(error)")
            return nil
        }
    }

    /// Saves the custom prompt to a file in Application Support.
    static func savePrompt(_ prompt: String) {
        guard let fileURL = directoryURL?.appendingPathComponent(promptFileName) else {
            logError("Cannot determine file URL for saving prompt")
            return
        }
        do {
            try prompt.write(to: fileURL, atomically: true, encoding: .utf8)
            logInfo("Prompt saved to \(fileURL.path)")
        } catch {
            logError("Failed to save prompt: \(error)")
        }
    }

    /// Loads the custom prompt from a file in Application Support. Returns an empty string if not found or upon error.
    static func loadPrompt() -> String {
        guard let fileURL = directoryURL?.appendingPathComponent(promptFileName) else {
            logError("Cannot determine file URL for loading prompt")
            return ""
        }
        do {
            let prompt = try String(contentsOf: fileURL, encoding: .utf8)
            logInfo("Prompt loaded from \(fileURL.path)")
            return prompt
        } catch {
            // No file or failed read: return empty prompt
            return ""
        }
    }

    /// Saves the selected transcription model to a file in Application Support.
    static func saveModel(_ model: TranscriptionModel) {
        guard let fileURL = directoryURL?.appendingPathComponent(modelFileName) else {
            logError("Cannot determine file URL for saving model")
            return
        }
        do {
            try model.rawValue.write(to: fileURL, atomically: true, encoding: .utf8)
            logInfo("Selected model saved to \(fileURL.path)")
        } catch {
            logError("Failed to save selected model: \(error)")
        }
    }

    /// Loads the selected transcription model from a file in Application Support. Returns default if not found or upon error.
    static func loadModel() -> TranscriptionModel {
        guard let fileURL = directoryURL?.appendingPathComponent(modelFileName) else {
            logError("Cannot determine file URL for loading model")
            return .defaultModel
        }
        do {
            let raw = try String(contentsOf: fileURL, encoding: .utf8)
            if let model = TranscriptionModel(rawValue: raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
                logInfo("Loaded selected model \(model.rawValue) from \(fileURL.path)")
                return model
            } else {
                logError("Unknown model value \(raw), using default")
                return .defaultModel
            }
        } catch {
            // No file or failed read: return default model
            return .defaultModel
        }
    }
}