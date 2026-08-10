import SwiftUI
import SwiftData
import AppKit
import os

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
    let container: ModelContainer?
    let containerError: Error?

    @StateObject private var connectionMonitor = ConnectionMonitor()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        var created: ModelContainer?
        var failure: Error?

        do {
            created = try ModelContainer(for: Conversation.self, ChatMessage.self, JournalEntry.self, JournalEntryTag.self, Commitment.self, AchievementUnlock.self, SelfLetter.self, MeditationSession.self)
        } catch {
            failure = error
            Log.data.fault("ModelContainer initialization failed: \(error.localizedDescription, privacy: .public)")
        }

        container = created
        containerError = failure

        if let created {
            checkAutoDeleteOnLaunch(context: created.mainContext)
        }
    }

    private func checkAutoDeleteOnLaunch(context: ModelContext) {
        let defaults = UserDefaults.standard
        defer { defaults.set(Date(), forKey: "lastActiveDate") }

        let shouldWipe = AutoDeletePolicy.shouldWipe(
            enabled: defaults.bool(forKey: "autoDeleteEnabled"),
            lastActive: defaults.object(forKey: "lastActiveDate") as? Date,
            thresholdDays: defaults.integer(forKey: "autoDeleteThresholdDays"),
            now: Date()
        )

        if shouldWipe {
            AppResetService.wipeAllData(context: context)
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                ContentView()
                    .environmentObject(connectionMonitor)
                    .modelContainer(container)
            } else {
                LaunchFailureView(message: containerError?.localizedDescription ?? "")
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 700, height: 560)
    }
}
