import Foundation

@MainActor
final class OllamaLauncher {
    static let shared = OllamaLauncher()

    private var process: Process?
    private var didStartProcess = false

    private init() {}

    private static let candidatePaths = [
        "/opt/homebrew/bin/ollama",
        "/usr/local/bin/ollama",
        "/Applications/Ollama.app/Contents/Resources/ollama"
    ]

    func startIfNeeded() async {
        guard UserDefaults.standard.bool(forKey: "autoStartOllama") else { return }
        guard await !isServerReachable() else { return }

        let manualPath = UserDefaults.standard.string(forKey: "ollamaExecutablePath") ?? ""
        let resolvedPath: String?

        if !manualPath.isEmpty, FileManager.default.isExecutableFile(atPath: manualPath) {
            resolvedPath = manualPath
        } else {
            resolvedPath = Self.candidatePaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
        }

        guard let path = resolvedPath else { return }
        launch(at: path)
    }

    private func isServerReachable() async -> Bool {
        let host = UserDefaults.standard.string(forKey: "ollamaHost") ?? OllamaDefaults.host
        guard let url = URL(string: host) else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        return (try? await URLSession.shared.data(for: request)) != nil
    }

    private func launch(at path: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = ["serve"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            process = task
            didStartProcess = true
        } catch {
            
        }
    }

    func stopIfWeStartedIt() {
        guard didStartProcess, let process, process.isRunning else { return }
        process.terminate()
    }
}
