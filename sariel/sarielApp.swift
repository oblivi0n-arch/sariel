import SwiftUI
import SwiftData
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(Date(), forKey: "lastActiveDate")
        Task {
            await OllamaLauncher.shared.startIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        OllamaLauncher.shared.stopIfWeStartedIt()
    }
}

@main
struct SarielApp: App {
    let container: ModelContainer
    @StateObject private var connectionMonitor = ConnectionMonitor()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        do {
            container = try ModelContainer(for: Conversation.self, ChatMessage.self, JournalEntry.self, JournalEntryTag.self, Commitment.self, AchievementUnlock.self)
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
