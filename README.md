# Sariel

_Regarding v1.21.3_

A local-first SwiftUI app for confronting your own rationalizations, powered by on-device AI (Ollama).

Sariel is not a gentle personal-growth coach. It's a mirror: a space to talk through your thoughts where the AI is built to name avoidance and rationalization directly, rather than offer comfort. Conversations can be closed into honest, first-person journal entries — and a running record of self-declared commitments (the Tribunal) holds you accountable to what you said you'd do.

## Features

- **Confrontational chat** — talk through your thoughts with a local AI persona designed to challenge rationalizations and avoidance, not soothe them.
- **Automatic journaling** — closing a conversation triggers the AI to synthesize it into an honest, first-person journal entry, tagged and saved locally.
- **The Tribunal** — declare a commitment mid-conversation ("I declare...") and face a dedicated session later where the AI holds you to account: fulfilled or broken, no soft verdicts.
- **Credibility tracking** — the AI can factor your track record of kept vs. broken commitments into its tone toward you.
- **Meditation** — timed breathing sessions with an optional intention set beforehand; completed and interrupted sessions are both tracked, feeding into the achievement system.
- **Self Letters** — write a letter to your future self, sealed until a chosen date, then revealed through the same confrontational lens as the rest of the app.
- **Non-linear achievements** — unlocks based on real behavioral patterns (writing streaks, returning after silence, recovering credibility after a bad streak), not simple counters.
- **Full personalization** — configurable Ollama host/model, custom personality prompt override, keyboard shortcuts, light/dark theme.
- **Data ownership** — export/import all your data to JSON, with schema versioning for safe migrations.
- **Multi-language UI** — English and Polish, switchable at any time.

## Tech Stack

- **SwiftUI** — declarative UI, macOS target
- **SwiftData** — local persistence for conversations, journal entries, commitments, and achievements
- **Ollama** — local LLM runtime; the app communicates with it over HTTP (no data ever leaves the device)
- **Swift Testing** — unit tests (see [Testing](#testing))

## Architecture

The project is organized by responsibility rather than by feature:

```
sariel/
├── Core/            # App-wide constants, navigation enum, transient UI state (AppLimits, AppSection, Toast)
├── DesignSystem/     # Colors, typography, localization strings
├── Models/
│   ├── Persistence/  # SwiftData @Model classes (Conversation, JournalEntry, Commitment, etc.)
│   ├── Domain/       # Pure domain enums with no persistence (AchievementKind, CredibilityBand, JournalStyle, TribunalVerdict)
│   └── DTO/          # Codable snapshot types used for export/import
├── Services/         # Business logic: chat orchestration, Ollama client, prompt building
├── Utilities/        # Non-UI helpers used across the app (e.g. Date+DayKey)
└── Views/            # SwiftUI views, grouped by feature (Chat, Journal, Dashboard, Onboarding, Tribunal, Sidebar),
                       # plus a Shared/ subfolder for UI components reused across more than one feature
```

Prompt construction is split by conversation mode (`PromptBuilder_Provocation`, `PromptBuilder_Tribunal`, `PromptBuilder_Credibility`, `PromptBuilder_Journal`, `PromptBuilder_Acquaintance`) rather than kept in one large file, to keep each system prompt independently readable and testable. `ChatService` follows the same pattern for its mode-specific orchestration logic (`ChatService_Provocation`, `ChatService_Acquaintance`, `ChatService_Tribunal`).

## Requirements

- macOS (SwiftUI/SwiftData target)
- Xcode 16+
- [Ollama](https://ollama.com) installed locally

## Known Limitations

- **App Sandbox is disabled.** Automatically launching the Ollama server as a subprocess at a filesystem path outside the app's container isn't possible under App Sandbox without fragile temporary-exception entitlements that Apple's App Store review rejects in practice. This is a deliberate trade-off for a locally-run, non-App-Store tool — it means the app can, in principle, access the filesystem and spawn processes beyond its own container.

## Getting Started

1. Install Ollama (via Homebrew or the [official installer](https://ollama.com/download)).
2. Pull a model that supports system-role instructions well, e.g.: `ollama pull gemma4:e4b`.
3. Clone this repository and open it in Xcode.
4. Build and run. On first launch, Sariel can start the Ollama server automatically (configurable in Settings), or you can start it manually with `ollama serve`.
5. Configure the Ollama host and model in Settings if you're not using the defaults.

## Testing

Sariel uses [Swift Testing](https://developer.apple.com/documentation/testing) (not XCTest) for unit tests, run against an in-memory SwiftData container so no real user data is touched. **~140 automated test cases across 18 test suites**, plus a documented manual test protocol for anything that depends on real LLM output.

**Automated coverage:**
- `CommitmentTests` — declaration prefix detection (`isDeclaration`)
- `CredibilityBandTests` — credibility threshold logic, including exact percentage boundaries
- `DateDayKeyTests` — day-key formatting used for streak calculations
- `ChatServiceTribunalTests` — verdict response parsing (distinguishing a genuine BROKEN judgment from an unrecognized/malformed model response), in-progress/resolved tribunal lookup, session numbering, verdict application, and the guard clauses of `generateVerdicts`/`startTribunal` that return before any network call is made
- `PromptBuilderTests` — structure of the core message arrays sent to Ollama (section ordering, history window trimming, title-prompt generation)
- `PromptBuilderJournalTests` — journal message/prompt building, including per-style prompt distinctness
- `PromptBuilderTribunalTests` — tribunal context text, pending-declaration/summary insertion, tribunal opening messages
- `PromptBuilderAcquaintanceTests` — acquaintance opening question, "about me" profile message building (existing-profile merge, speaker-labeled transcript)
- `PromptBuilderCredibilityTests` — credibility context text, including the insufficient-data guard
- `PromptBuilderProvocationTests` — provocation opening question and title message building
- `DataExportRoundTripTests` — full export/import round-trip (including self letters and meditation sessions), empty-database edge case, all achievement kinds, schema-version and corrupted-file error handling
- `AchievementServiceTests` — every unlock condition, including night-owl hour boundary, consistency streaks, silence/spiral thresholds, commitment streaks, credibility recovery, self-letter sealing/opening/long-delay, and meditation consistency/abandonment/first-full-session
- `ChatServiceTests` — declaration limit enforcement, commitment creation, message deletion and summary reconciliation
- `SelfLetterServiceTests` — sealed→available availability transitions around the openDate boundary, and that other statuses (draft/available/opened) are left untouched
- `MeditationSessionTests` — the `wasInterrupted` boundary (shorter/equal/longer than planned duration)
- `AutoDeletePolicyTests` — inactivity-wipe threshold logic, including the exact-boundary case and a safe fallback when the threshold is misconfigured to zero
- `PinKeychainStoreTests` — PIN hashing correctness (determinism, distinctness, format)
- `AppResetServiceTests` — full data wipe correctness: all SwiftData model types (including self letters and meditation sessions) are cleared, and the PIN/app-lock state is reset

> **Note:** `AppResetServiceTests` touches the real macOS Keychain (there is currently no mocking layer for `PinKeychainStore`). It's safe on a dev machine with no PIN in daily use, but is a known limitation worth revisiting if that changes.
>
> **Note:** `generateVerdicts` and `startTribunal` (in `ChatService_Tribunal`) call the Ollama client over the network past their guard clauses. Only the guard-clause paths are covered by automated tests; the network-dependent behavior is validated manually, same as other LLM-output-dependent logic.

**Not automated, by design:** AI response quality — prompt behavior, edge cases, and adherence to the crisis-safety boundary — is not something a unit test can meaningfully assert, since it depends on the LLM's output. These are validated manually against a documented test protocol instead. UI tests (XCUITest) are likewise out of scope for this release; see the project's test-plan documentation for the reasoning.

Run tests with `Cmd+U` in Xcode, or `xcodebuild test` from the command line.

## Privacy

Everything you write stays on this device. Conversations, journal entries, and commitments are stored locally via SwiftData and are never sent anywhere except to your local Ollama instance for processing.

## A Note on Safety

Sariel is not therapy or a crisis service, and was never designed to be one. Its confrontational tone is a deliberate design choice for self-reflection, not a substitute for professional support. If you are in crisis or having thoughts of self-harm, please reach out to a mental health professional or a crisis line. This boundary is stated to the user on first launch and is enforced as a hard override in the AI's system prompt.

## License

Sariel is licensed under the [GNU General Public License v3.0](LICENSE). You're free to use, study, modify, and redistribute it, including commercially — but any distributed copy or modified version must remain under the same license, with source code made available to its recipients.
