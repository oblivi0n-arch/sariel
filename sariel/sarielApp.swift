import SwiftUI
import SwiftData

@main
struct SarielApp: App {
    let container: ModelContainer
    @StateObject private var connectionMonitor = ConnectionMonitor()

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
                .environmentObject(connectionMonitor)
        }
        .windowStyle(.hiddenTitleBar)
        .modelContainer(container)
        .defaultSize(width: 700, height: 560)
    }
}
