import SwiftUI
import SwiftData

@main
struct SarielApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Conversation.self, ChatMessage.self)
        } catch {
            fatalError("Cannot initialize container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .defaultSize(width: 700, height: 560)
    }
}
