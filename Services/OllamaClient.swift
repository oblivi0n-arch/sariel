import Foundation

enum OllamaError: LocalizedError {
    case connectionFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "Cannot connect to Ollama. Run 'ollama serve' in terminal."
        case .invalidResponse: return "Ollama returned an invalid response."
        }
    }
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

struct OllamaClient {
    var url: URL {
        let host = UserDefaults.standard.string(forKey: "ollamaHost") ?? "http://localhost:11434"
        return URL(string: "\(host)/api/chat") ?? URL(string: "http://localhost:11434/api/chat")!
    }

    var model: String {
        UserDefaults.standard.string(forKey: "ollamaModel") ?? "gemma3:12b"
    }

    func streamChat(messages: [OllamaMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let body: [String: Any] = [
                        "model": model,
                        "messages": messages.map { ["role": $0.role, "content": $0.content] },
                        "stream": true
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                        throw OllamaError.invalidResponse
                    }

                    for try await line in bytes.lines {
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let message = json["message"] as? [String: Any],
                              let content = message["content"] as? String else { continue }
                        
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: OllamaError.connectionFailed)
                }
            }
        }
    }
    
    func complete(messages: [OllamaMessage]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw OllamaError.invalidResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OllamaError.invalidResponse
        }

        return content
    }
}
