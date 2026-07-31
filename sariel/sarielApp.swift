import SwiftUI
import SwiftData
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
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

        checkAutoDeleteOnLaunch()
    }

    private func checkAutoDeleteOnLaunch() {
        let defaults = UserDefaults.standard
        defer { defaults.set(Date(), forKey: "lastActiveDate") }

        let shouldWipe = AutoDeletePolicy.shouldWipe(
            enabled: defaults.bool(forKey: "autoDeleteEnabled"),
            lastActive: defaults.object(forKey: "lastActiveDate") as? Date,
            thresholdDays: defaults.integer(forKey: "autoDeleteThresholdDays"),
            now: Date()
        )

        if shouldWipe {
            AppResetService.wipeAllData(context: container.mainContext)
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
