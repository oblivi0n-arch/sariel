# Sariel

A local-first SwiftUI app for confronting your own rationalizations, powered by on-device AI (Ollama).

Sariel is not a gentle personal-growth coach. It's a mirror: a space to talk through your thoughts where the AI is built to name avoidance and rationalization directly, rather than offer comfort. Conversations can be closed into honest, first-person journal entries — and a running record of self-declared commitments (the Tribunal) holds you accountable to what you said you'd do.

## Features

- **Confrontational chat** — talk through your thoughts with a local AI persona designed to challenge rationalizations and avoidance, not soothe them.
- **Automatic journaling** — closing a conversation triggers the AI to synthesize it into an honest, first-person journal entry, tagged and saved locally.
- **The Tribunal** — declare a commitment mid-conversation ("I declare...") and face a dedicated session later where the AI holds you to account: fulfilled or broken, no soft verdicts.
- **Credibility tracking** — the AI can factor your track record of kept vs. broken commitments into its tone toward you.
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
├── DesignSystem/ # Colors, typography, localization strings
├── Models/ # SwiftData models (Conversation, JournalEntry, Commitment, etc.)
├── Services/ # Business logic: chat orchestration, Ollama client, prompt building
├── Views/ # SwiftUI views, grouped by feature (Chat, Journal, Dashboard, Onboarding, Tribunal)
└── Shared/ # Reusable UI components and helpers used across features
```

Prompt construction is split by conversation mode (`PromptBuilder+Provocation`, `PromptBuilder+Tribunal`, `PromptBuilder+Credibility`) rather than kept in one large file, to keep each system prompt independently readable and testable.

## Requirements

- macOS (SwiftUI/SwiftData target)
- Xcode 16+
- [Ollama](https://ollama.com) installed locally

## Known Limitations

- **App Sandbox is disabled.** Automatically launching the Ollama server as a subprocess at a filesystem path outside the app's container isn't possible under App Sandbox without fragile temporary-exception entitlements that Apple's App Store review rejects in practice. This is a deliberate trade-off for a locally-run, non-App-Store tool — it means the app can, in principle, access the filesystem and spawn processes beyond its own container.

## Getting Started

1. Install Ollama (via Homebrew or the [official installer](https://ollama.com/download)).
2. Pull a model that supports system-role instructions well, e.g.: 'ollama pull gemma4:e4b'.
3.  Clone this repository and open it in Xcode.
4. Build and run. On first launch, Sariel can start the Ollama server automatically (configurable in Settings), or you can start it manually with `ollama serve`.
5. Configure the Ollama host and model in Settings if you're not using the defaults.

## Testing

Sariel uses [Swift Testing](https://developer.apple.com/documentation/testing) (not XCTest) for unit tests, run against an in-memory SwiftData container so no real user data is touched. **62 automated test cases** across 8 test suites, plus a documented manual test protocol for anything that depends on real LLM output.

**Automated coverage:**
- `CommitmentTests` — declaration prefix detection (`isDeclaration`)
- `CredibilityBandTests` — credibility threshold logic, including exact percentage boundaries
- `DateDayKeyTests` — day-key formatting used for streak calculations
- `TribunalVerdictParsingTests` — verdict response parsing, distinguishing a genuine BROKEN judgment from an unrecognized/malformed model response
- `PromptBuilderTests` — structure of the message arrays sent to Ollama (section ordering, history window trimming, title-prompt generation)
- `DataExportRoundTripTests` — full export/import round-trip, empty-database edge case, all achievement kinds, schema-version and corrupted-file error handling
- `AchievementServiceTests` — every unlock condition (night-owl hour boundary, consistency streaks, silence/spiral thresholds, commitment streaks, credibility recovery)
- `ChatServiceTests` — declaration limit enforcement, commitment creation, message deletion and summary reconciliation

**Not automated, by design:** AI response quality — prompt behavior, edge cases, and adherence to the crisis-safety boundary — is not something a unit test can meaningfully assert, since it depends on the LLM's output. These are validated manually against a documented test protocol instead. UI tests (XCUITest) are likewise out of scope for this release; see the project's test-plan documentation for the reasoning.

Run tests with `Cmd+U` in Xcode, or `xcodebuild test` from the command line.

## Privacy

Everything you write stays on this device. Conversations, journal entries, and commitments are stored locally via SwiftData and are never sent anywhere except to your local Ollama instance for processing.

## A Note on Safety

Sariel is not therapy or a crisis service, and was never designed to be one. Its confrontational tone is a deliberate design choice for self-reflection, not a substitute for professional support. If you are in crisis or having thoughts of self-harm, please reach out to a mental health professional or a crisis line. This boundary is stated to the user on first launch and is enforced as a hard override in the AI's system prompt.

## License

Sariel is licensed under the [GNU General Public License v3.0](LICENSE). You're free to use, study, modify, and redistribute it, including commercially — but any distributed copy or modified version must remain under the same license, with source code made available to its recipients.
