import Foundation

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

enum OllamaError: LocalizedError {
    case connectionFailed
    case modelNotFound(String)
    case serverError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Cannot connect to Ollama."
        case .modelNotFound(let model):
            return "Model '\(model)' not found."
        case .serverError(let code):
            return "Ollama returned an error (\(code))."
        case .invalidResponse:
            return "Ollama returned an invalid response."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed:
            return "Run 'ollama serve' in terminal."
        case .modelNotFound:
            return "Pull it or pick another one in Settings."
        case .serverError, .invalidResponse:
            return nil
        }
    }
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
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OllamaError.connectionFailed
                    }
                    guard httpResponse.statusCode == 200 else {
                        throw error(forStatusCode: httpResponse.statusCode)
                    }
                    
                    for try await line in bytes.lines {
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let message = json["message"] as? [String: Any],
                              let content = message["content"] as? String else { continue }
                        
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch let error as OllamaError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(throwing: OllamaError.connectionFailed)
                }
            }
        }
    }
    
    func complete(messages: [OllamaMessage]) async throws -> String {
        do {
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

            guard let httpResponse = response as? HTTPURLResponse else {
                throw OllamaError.connectionFailed
            }
            guard httpResponse.statusCode == 200 else {
                throw error(forStatusCode: httpResponse.statusCode)
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let message = json["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw OllamaError.invalidResponse
            }

            return content
        } catch let error as OllamaError {
            throw error
        } catch {
            throw OllamaError.connectionFailed
        }
    }

    private func error(forStatusCode code: Int) -> OllamaError {
        switch code {
        case 404:
            return .modelNotFound(model)
        default:
            return .serverError(code)
        }
    }
}

