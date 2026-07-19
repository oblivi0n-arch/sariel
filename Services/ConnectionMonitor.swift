import Foundation
import Combine

@MainActor
final class ConnectionMonitor: ObservableObject {
    @Published var isConnected: Bool = false

    private var monitorTask: Task<Void, Never>?
    private let checkInterval: UInt64 = 5_000_000_000

    init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitorTask = Task {
            while !Task.isCancelled {
                let connected = await checkConnection()
                isConnected = connected
                try? await Task.sleep(nanoseconds: checkInterval)
            }
        }
    }

    private func checkConnection() async -> Bool {
        let host = UserDefaults.standard.string(forKey: "ollamaHost") ?? "http://localhost:11434"
        guard let url = URL(string: host) else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func stopMonitoring() {
        monitorTask?.cancel()
        monitorTask = nil
    }
}
