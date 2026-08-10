import Foundation
import OSLog

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "sariel"

    static let chat = Logger(subsystem: subsystem, category: "chat")
    static let ollama = Logger(subsystem: subsystem, category: "ollama")
    static let data = Logger(subsystem: subsystem, category: "data")
}
