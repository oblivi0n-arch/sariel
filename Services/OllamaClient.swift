import Foundation

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

enum OllamaDefaults {
    static let host = "http://localhost:11434"
    static let model = "gemma4:e4b"
}

enum OllamaError: LocalizedError {
    case connectionFailed
    case modelNotFound(String)
    case serverError(Int)
    case invalidResponse
    case invalidHost

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return L10n.OllamaClient.connectionFailed
        case .modelNotFound(let model):
            return L10n.OllamaClient.modelNotFound + "\(model)"
        case .serverError(let code):
            return L10n.OllamaClient.serverError + "(\(code))"
        case .invalidResponse:
            return L10n.OllamaClient.invalidResponse
        case .invalidHost:
            return L10n.OllamaClient.invalidHost
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed:
            return L10n.OllamaClient.connectionFailedHint
        case .modelNotFound:
            return L10n.OllamaClient.modelNotFoundHint
        case .serverError, .invalidResponse:
            return nil
        case .invalidHost:
            return L10n.OllamaClient.invalidHostHint
        }
    }
}

struct OllamaClient {
    var url: URL {
        let host = UserDefaults.standard.string(forKey: "ollamaHost") ?? OllamaDefaults.host
        return URL(string: "\(host)/api/chat") ?? URL(string: "\(OllamaDefaults.host)/api/chat")!
    }
    
    var model: String {
        UserDefaults.standard.string(forKey: "ollamaModel") ?? OllamaDefaults.model
    }
    
    func streamChat(messages: [OllamaMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
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
                        try Task.checkCancellation()
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let message = json["message"] as? [String: Any],
                              let content = message["content"] as? String else { continue }

                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch let error as OllamaError {
                    continuation.finish(throwing: error)
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: OllamaError.connectionFailed)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    func complete(messages: [OllamaMessage], think: Bool = false) async throws -> String {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "model": model,
                "messages": messages.map { ["role": $0.role, "content": $0.content] },
                "stream": false,
                "think": think
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

extension OllamaClient {

    static func isValidHost(_ host: String) -> Bool {
        guard let url = URL(string: host), let scheme = url.scheme else { return false }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }

    static func isLocalHost(_ host: String) -> Bool {
        guard let hostname = URL(string: host)?.host?.lowercased() else { return false }
        return hostname == "localhost" || hostname == "127.0.0.1" || hostname == "::1"
    }

    static func fetchAvailableModels(host: String) async throws -> [String] {
        guard isValidHost(host), let url = URL(string: "\(host)/api/tags") else {
            throw OllamaError.invalidHost
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw OllamaError.connectionFailed
        }

        let decoded = try JSONDecoder().decode(TagsResponse.self, from: data)
        return decoded.models.map { $0.name }
    }

    private struct TagsResponse: Codable {
        let models: [ModelInfo]
    }

    private struct ModelInfo: Codable {
        let name: String
    }
}

extension L10n {
    enum OllamaClient {
        static var connectionFailed: String {
            switch lang {
            case .en: return "Cannot connect to Ollama."
            case .pl: return "Błąd połączenia z Ollama."
            }
        }
        
        static var modelNotFound: String {
            switch lang {
            case .en: return "Cannot find a model: "
            case .pl: return "Nie znaleziono modelu: "
            }
        }
        
        static var serverError: String {
            switch lang {
            case .en: return "Server error "
            case .pl: return "Błąd serwera "
            }
        }
        
        static var invalidResponse: String {
            switch lang {
            case .en: return "Ollama returned an invalid response."
            case .pl: return "Ollama zwróciła nieprawidłową odpowiedź."
            }
        }
        
        static var invalidHost: String {
            switch lang {
            case .en: return "Invalid Ollama host URL."
            case .pl: return "Nieprawidłowy adres serwera Ollama."
            }
        }
        
        static var connectionFailedHint: String {
            switch lang {
            case .en: return "Run 'ollama serve' in terminal."
            case .pl: return "Uruchom 'ollama serve' w terminalu."
            }
        }
        
        static var modelNotFoundHint: String {
            switch lang {
            case .en: return "Pull it or pick another one in Settings."
            case .pl: return "Pobierz lub wybierz inny w Ustawieniach."
            }
        }
        
        static var invalidHostHint: String {
            switch lang {
            case .en: return "Check Ollama host URL in Settings."
            case .pl: return "Sprawdź adres serwera Ollama w Ustawieniach."
            }
        }
    }
}
