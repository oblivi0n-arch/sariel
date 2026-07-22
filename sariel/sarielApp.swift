import SwiftUI
import SwiftData

// Baseline before Stellaris map hub rework (v2.0.0)

@main
struct SarielApp: App {
    let container: ModelContainer
    @StateObject private var connectionMonitor = ConnectionMonitor()

    init() {
        do {
            container = try ModelContainer(for: Conversation.self, ChatMessage.self, JournalEntry.self, JournalEntryTag.self, Commitment.self)
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
