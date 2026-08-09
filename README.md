# Sariel

_Regarding v1.23.0_

A local-first SwiftUI app for confronting your own rationalizations, powered by on-device AI (Ollama).

Sariel is not a gentle personal-growth coach. It's a mirror: a space to talk through your thoughts where the AI is built to name avoidance and rationalization directly, rather than offer comfort. Conversations can be closed into honest, first-person journal entries — and a running record of self-declared commitments (the Tribunal) holds you accountable to what you said you'd do.

Everything runs on your machine. No account, no server, no telemetry, no third-party dependencies.

## Features

- **Confrontational chat** — talk through your thoughts with a local AI persona designed to challenge rationalizations and avoidance, not soothe them.
- **Automatic journaling** — closing a conversation triggers the AI to synthesize it into an honest, first-person journal entry, tagged and saved locally. Three entry styles to choose from.
- **The Tribunal** — declare a commitment mid-conversation ("I declare...") and face a dedicated session later where the AI holds you to account: fulfilled or broken, no soft verdicts.
- **Credibility tracking** — the AI can factor your track record of kept vs. broken commitments into its tone toward you.
- **Meditation** — timed breathing sessions with an optional intention set beforehand; completed and interrupted sessions are both tracked, feeding into the achievement system.
- **Self Letters** — write a letter to your future self, sealed until a chosen date, then revealed through the same confrontational lens as the rest of the app.
- **Non-linear achievements** — unlocks based on real behavioral patterns (writing streaks, returning after silence, recovering credibility after a bad streak), not simple counters.
- **App lock** — optional 4-digit PIN with Touch ID unlock, plus auto-wipe after a configurable period of inactivity.
- **Personalization** — configurable Ollama host and model, keyboard shortcuts, light/dark theme, persistent "about me" profile distilled from a getting-acquainted conversation.
- **Data ownership** — export/import all your data to JSON, with schema versioning for safe migrations.
- **Multi-language UI** — English and Polish, switchable at any time.

## Conversation modes

Sariel runs four kinds of conversation, each with its own system prompt:

| Mode | How it starts | What it's for |
|---|---|---|
| **Standard** | You write first | Open reflection. The mirror persona, with journal and credibility context optionally injected. |
| **Provocation** | The AI writes first | A generated opening question sharp enough to be uncomfortable — for when you don't know where to start. |
| **Acquaintance** | The AI writes first | A one-time conversation the app distills into a persistent "about me" profile, so later confrontations have something to work with. |
| **Tribunal** | Unlocked by the app | A reckoning session for commitments you declared, ending in a verdict per declaration. |

## Design notes

### Keeping the model out of the driver's seat

Small local models hallucinate. Since Sariel lets AI output influence *persistent user data* — journal entries, commitment verdicts, your profile — the app is built on one rule: **the model proposes, the app validates, you confirm, and only then does anything get written.**

Concretely:

- **Commitments are created deterministically.** A declaration only exists if *you* typed the "I declare" prefix. The model has no say in whether a commitment comes into being.
- **Verdicts are parsed, not trusted.** The model must answer `FULFILLED` or `BROKEN` on the first line. An unrecognized response triggers a retry; if it still fails, the commitment stays pending and you're told which verdicts couldn't be reached.
- **Nothing is saved until you approve it.** `generateVerdicts` returns in-memory values only — you can flip any verdict in the confirmation overlay before it's written. The same applies to the generated "about me" profile, which lands in a pending draft you accept or discard.
- **The Tribunal prompt declares its list closed.** The model is told the pending declarations given to it are authoritative, that no others exist, and that any reference to a declaration outside that list is false — *including ones it may have invented earlier in the same conversation.*
- **Errors never re-enter the context.** Failed responses are stored as messages prefixed with `⚠️` and filtered out of everything sent back to the model.

### Prompts are logic, not config

The system prompts are where the app's behavior actually lives — both the confrontational tone and the crisis-safety boundary that overrides it. They're versioned Swift code, split by mode (`PromptBuilder+Provocation`, `+Tribunal`, `+Credibility`, `+Journal`, `+Acquaintance`) so each one stays independently readable and testable, with every prompt written in both English and Polish.

This is also why there's **no user-facing prompt editor**. An earlier version had one, and it was removed: it could only override the main chat prompt out of fourteen, producing an app with a split personality — and because the safety boundary lives inside those same strings, editing the prompt meant being one keystroke away from deleting it. Reintroducing the feature safely would require splitting every prompt into an editable persona block and an immutable safety block. That's a future change, not a settings toggle.

### Context window management

Long conversations are handled without dropping facts: up to 30 recent messages go to the model directly, and once more than 10 messages are unsummarized, a separate call folds them into a running third-person summary while the raw window shrinks to the last 8. Deleting messages reconciles the summary, so the model can't "remember" something you erased.

## Tech Stack

- **SwiftUI** — declarative UI, macOS target
- **SwiftData** — local persistence for conversations, journal entries, commitments, letters, meditation sessions, and achievements
- **Ollama** — local LLM runtime; the app talks to it over HTTP
- **Swift Testing** — unit tests (see [Testing](#testing))
- **CryptoKit / Keychain / LocalAuthentication** — PIN hashing, secure storage, Touch ID

**Zero third-party dependencies.** Everything above ships with the platform. For an app whose main promise is that your data stays put, there's no third-party code to audit for telemetry.

## Architecture

The project is organized by responsibility rather than by feature:

```
sariel/
├── Core/             # App-wide constants, navigation enum, transient UI state (AppLimits, AppSection, Toast)
├── DesignSystem/     # Colors, typography, localization strings
├── Models/
│   ├── Persistence/  # SwiftData @Model classes (Conversation, JournalEntry, Commitment, etc.)
│   ├── Domain/       # Pure domain enums with no persistence (AchievementKind, CredibilityBand, JournalStyle, TribunalVerdict)
│   └── DTO/          # Codable snapshot types used for export/import
├── Services/         # Business logic: chat orchestration, Ollama client, prompt building
├── Utilities/        # Non-UI helpers used across the app (e.g. Date+DayKey)
└── Views/            # SwiftUI views, grouped by feature (Chat, Journal, Dashboard, Onboarding, Tribunal,
                      # Meditation, PinEntry, Sidebar), plus a Shared/ subfolder for reused components
```

Splitting `Domain` from `Persistence` keeps business rules (credibility thresholds, achievement conditions, interruption logic) testable without spinning up a SwiftData container. Splitting `DTO` from both lets the export file format be versioned independently of the database schema.

`ChatService` follows the same by-mode split as `PromptBuilder` (`ChatService+Provocation`, `+Acquaintance`, `+Tribunal`).

## Requirements

- macOS (SwiftUI/SwiftData target)
- Xcode 16+
- [Ollama](https://ollama.com) installed locally

## Getting Started

1. Install Ollama (via Homebrew or the [official installer](https://ollama.com/download)).
2. Pull a model that supports system-role instructions well, e.g.: `ollama pull gemma4:e4b`.
3. Clone this repository and open it in Xcode.
4. Build and run. On first launch, Sariel can start the Ollama server automatically (configurable in Settings), or you can start it manually with `ollama serve`.
5. Configure the Ollama host and model in Settings if you're not using the defaults.

### Choosing a model

This matters more than it looks. Sariel sends up to six separate `system` messages per request — persona, your name, your profile, journal context, credibility context, and the running summary. **A model that doesn't reliably honor system-role instructions will hold neither the confrontational tone nor the safety boundary**, which makes model choice a configuration decision rather than a technical detail.

Default: `gemma4:e4b`. The model picker in Settings lists whatever you've pulled locally.

### Keyboard shortcuts

`⌘1` Dashboard · `⌘2` Chat · `⌘3` Journal · `⌘4` Tribunal · `⌘5` Meditation — all remappable in Settings.

## Testing

Sariel uses [Swift Testing](https://developer.apple.com/documentation/testing) (not XCTest) for unit tests, run against an in-memory SwiftData container so no real user data is touched. **140 automated test cases across 18 test suites**, plus a documented manual test protocol for anything that depends on real LLM output.

Run tests with `Cmd+U` in Xcode, or `xcodebuild test` from the command line.

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

**Not automated, by design:** AI response quality — prompt behavior, edge cases, and adherence to the crisis-safety boundary — is not something a unit test can meaningfully assert, since it depends on the LLM's output. These are validated manually against a documented test protocol instead. UI tests (XCUITest) are likewise out of scope for this release; see the project's test-plan documentation for the reasoning.

> **Note:** `AppResetServiceTests` touches the real macOS Keychain (there is currently no mocking layer for `PinKeychainStore`). It's safe on a dev machine with no PIN in daily use, but is a known limitation worth revisiting if that changes.
>
> **Note:** `generateVerdicts` and `startTribunal` (in `ChatService+Tribunal`) call the Ollama client over the network past their guard clauses. Only the guard-clause paths are covered by automated tests; the network-dependent behavior is validated manually, same as other LLM-output-dependent logic.

## Privacy

Everything you write stays on this device. Conversations, journal entries, commitments, letters, and meditation sessions are stored locally via SwiftData and are never sent anywhere except to your local Ollama instance for processing.

Where things live:

| Data | Storage | In exports | Wiped on reset |
|---|---|---|---|
| Conversations, journal, commitments, letters, sessions, achievements | SwiftData (local store) | yes | yes |
| Settings, profile, shortcuts, preferences | `UserDefaults` | yes | yes |
| App-lock PIN (SHA-256 hash) | Keychain | **no** | yes |

There is no account system, no sync service, no crash reporting, and no analytics. The `.gitignore` excludes SwiftData store files outright, so user data can't be committed by accident.

**One honest caveat:** the Ollama host is user-configurable and accepts any `http`/`https` address, not just `localhost`. Pointing it at a remote server will send your conversations to that server. The app warns you when the configured host isn't local, but the choice is yours — the "stays on this device" guarantee describes the default configuration, not a hard technical constraint.

## Known Limitations

- **App Sandbox is disabled.** Automatically launching the Ollama server as a subprocess at a filesystem path outside the app's container isn't possible under App Sandbox without fragile temporary-exception entitlements that Apple's App Store review rejects in practice. This is a deliberate trade-off for a locally-run, non-App-Store tool — it means the app can, in principle, access the filesystem and spawn processes beyond its own container.
- **The app lock is a door, not a vault.** The PIN is a 4-digit code hashed with a single pass of SHA-256 and stored in the Keychain, with no rate limiting on attempts. It stops someone from casually opening your journal; it will not stop anyone determined who has access to your Keychain.
- **No schema migration plan yet.** SwiftData models aren't versioned with `VersionedSchema`/`SchemaMigrationPlan`. Breaking model changes may require an export → reset → import cycle.
- **No logging.** Failures in non-critical paths (title generation, summary refresh, Ollama launch) are swallowed silently, which makes diagnosing issues on someone else's machine difficult.
- **Context window is counted in messages, not tokens.** With a small-context model and long messages, overflow is still possible.

## Troubleshooting

**"Cannot connect to Ollama."** The server isn't running. Either enable auto-start in Settings, or run `ollama serve` yourself. The connection indicator in Settings polls every few seconds.

**Auto-start doesn't work.** Sariel looks for the binary at `/opt/homebrew/bin/ollama`, `/usr/local/bin/ollama`, and `/Applications/Ollama.app/Contents/Resources/ollama`. If yours is elsewhere, set the path manually under "Can't find Ollama?" in Settings.

**"Model 'x' not found."** Pull it with `ollama pull <model>`, then refresh the model list in Settings.

**Sariel accuses me of avoiding things when I'm just thinking.** The prompt explicitly instructs the model that uncertainty and short replies are not evidence of avoidance — but weaker models don't always follow it. This is usually a sign to try a model with stronger system-role adherence.

## A Note on Safety

Sariel is not therapy or a crisis service, and was never designed to be one. Its confrontational tone is a deliberate design choice for self-reflection, not a substitute for professional support. If you are in crisis or having thoughts of self-harm, please reach out to a mental health professional or a crisis line.

This boundary is stated to the user on first launch and enforced as a hard override in **every** system prompt that can produce user-facing text — chat, Tribunal, verdicts, and all three journal styles. In each case the instruction is explicit that it overrides every other rule without exception: drop the mirror persona, respond with direct warmth, and point toward professional help. The journal prompts go further and require a calm, grounding entry that does not dwell on or amplify crisis content, because a journal entry is something you come back to.

## License

Sariel is licensed under the [GNU General Public License v3.0](LICENSE). You're free to use, study, modify, and redistribute it, including commercially — but any distributed copy or modified version must remain under the same license, with source code made available to its recipients.
