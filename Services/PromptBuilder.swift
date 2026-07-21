import Foundation

struct PromptBuilder {

    static let systemPrompt = """
    You are Sariel. You are not a coach, not a friend, and not a therapist — you are a mirror. Your only function is to reflect the user's own thinking back to them with total honesty, so they see themselves clearly.

    Rules of your behavior:
    1. Confront, don't comfort. If the user rationalizes, deflects, or lies to themselves, name it directly. Do not soften an observation just to spare their feelings.
    2. No empty encouragement. Never say things like "you've got this" or "I'm proud of you" unless it is earned by a concrete action the user has actually taken. Praise is evidence, not decoration.
    3. Precision over sympathy. Ask the one sharp question that exposes the gap between what the user says they want and what they are actually doing. Avoid motivational jargon and walls of text.
    4. Silence is a valid response. If the user is stalling or repeating themselves, say so plainly instead of filling the space with reassurance.

    Hard boundaries (these override every rule above, without exception): Never encourage violence toward others or self-harm. If you detect a genuine mental health crisis — suicidal ideation, self-harm, psychosis, or similar — immediately drop the mirror persona. Respond with direct warmth and clarity, and state plainly that the user should seek professional help or a crisis line. The confrontational tone above is never an excuse to withhold support in a real crisis.
    """
    
    static let titleSystemPrompt = """
    Your only task is to generate a short conversation title based on the message exchange below.

    Rules:
    1. The title must be a maximum of 4-5 words.
    2. Do not use quotation marks, a trailing period, or any additional commentary.
    3. Respond with ONLY the title, nothing else.
    """
    
    static let journalSystemPrompt = """
    Based on the conversation below, write a first-person journal entry, as if the user is writing it themselves right after confronting themselves honestly.

    Rules:
    1. Write in first person ("I have been avoiding...", "I can't pretend that..."), never address the reader as "you".
    2. Focus on the uncomfortable truth, rationalization, or self-deception that surfaced — not a transcript of the conversation.
    3. Be honest and direct. No motivational spin, no forced silver linings — unless the user actually reached a concrete decision, in which case state it plainly.
    4. Normally 3-6 short sentences. No headers, no bullet points, no closing signature.
    5. Do not mention Sariel or the assistant — this is the user's own private reflection.
    6. If the conversation was short or shallow — if the user was evasive, repeated themselves, or nothing concrete actually surfaced — write fewer sentences (even 1-2) and be honest about that thinness, rather than inventing insight that wasn't earned. A vague conversation should produce a vague, short entry, not a padded one.
    """

    static let journalTitleSystemPrompt = """
    Your only task is to generate a short journal entry title based on the entry text below.

    Rules:
    1. The title must be a maximum of 4-5 words.
    2. Do not use quotation marks, a trailing period, or any additional commentary.
    3. Respond with ONLY the title, nothing else.
    """

    static let summarySystemPrompt = """
    Your task is to maintain a running summary of an ongoing conversation between a user and Sariel, a blunt mirror for self-reflection.

    Rules:
    1. Write in third person, neutral and factual (e.g. "The user is avoiding...", "They admitted that...").
    2. Preserve concrete facts, decisions, rationalizations, and commitments the user made — these matter more than emotional tone.
    3. Keep it dense and short: aim for 5-10 sentences regardless of how long the conversation gets.
    4. This summary is internal context for the mirror, not something the user will read directly. No commentary, no preamble.
    5. If given an existing summary plus new messages, merge them into a single updated summary — do not just describe the new messages in isolation.
    """
    
    static let maxHistoryMessages = 30
    static let summaryRefreshThreshold = 10
    static let keepRawMessages = 8
    static let journalContextEntryCount = 5
    static let journalContextExcerptLength = 200

    static func buildJournalContextText(entries: [JournalEntry]) -> String {
        guard !entries.isEmpty else { return "" }

        return entries.map { entry in
            let excerpt = entry.content.count > journalContextExcerptLength
                ? String(entry.content.prefix(journalContextExcerptLength)) + "…"
                : entry.content
            return "- [\(entry.entryMood.rawValue)] \(entry.title): \(excerpt)"
        }.joined(separator: "\n")
    }

    static func buildMessages(history: [ChatMessage], summary: String = "", journalContext: String = "", credibilityContext: String = "") -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: systemPrompt)]

        if !journalContext.isEmpty {
            messages.append(OllamaMessage(
                role: "system",
                content: "Recent journal entries from the user, for spotting recurring patterns. Use them only if relevant — don't force references to them:\n\(journalContext)"
            ))
        }

        if !credibilityContext.isEmpty {
            messages.append(OllamaMessage(
                role: "system",
                content: "Context on the user's track record with declared commitments, from past Tribunal sessions. Use it to calibrate your tone toward them — don't force references to it if it isn't relevant to what they're saying right now:\n\(credibilityContext)"
            ))
        }

        if !summary.isEmpty {
            messages.append(OllamaMessage(role: "system", content: "Summary of the conversation so far: \(summary)"))
        }

        let windowSize = summary.isEmpty ? maxHistoryMessages : keepRawMessages
        let trimmedHistory = history.suffix(windowSize)
        for message in trimmedHistory {
            let role = message.messageRole == .user ? "user" : "assistant"
            messages.append(OllamaMessage(role: role, content: message.content))
        }

        return messages
    }
    
    static func buildTitleMessages(userText: String, guideText: String) -> [OllamaMessage] {
        [
            OllamaMessage(role: "system", content: titleSystemPrompt),
            OllamaMessage(role: "user", content: userText),
            OllamaMessage(role: "assistant", content: guideText),
            OllamaMessage(role: "user", content: "Generate a title for this conversation.")
        ]
    }
    
    static func buildJournalMessages(history: [ChatMessage], summary: String = "") -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: journalSystemPrompt)]

        if !summary.isEmpty {
            messages.append(OllamaMessage(role: "user", content: "Summary of the earlier part of the conversation: \(summary)"))
        }

        for message in history {
            let role = message.messageRole == .user ? "user" : "assistant"
            messages.append(OllamaMessage(role: role, content: message.content))
        }
        
        messages.append(OllamaMessage(role: "user", content: "Write the journal entry now, based on our conversation above."))

        return messages
    }

    static func buildJournalTitleMessages(entryContent: String) -> [OllamaMessage] {
        [
            OllamaMessage(role: "system", content: journalTitleSystemPrompt),
            OllamaMessage(role: "user", content: entryContent)
        ]
    }

    static func buildSummaryMessages(existingSummary: String, newMessages: [ChatMessage]) -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: summarySystemPrompt)]

        if !existingSummary.isEmpty {
            messages.append(OllamaMessage(role: "user", content: "Existing summary so far:\n\(existingSummary)"))
        }

        var transcript = ""
        for message in newMessages {
            let speaker = message.messageRole == .user ? "User" : "Sariel"
            transcript += "\(speaker): \(message.content)\n"
        }
        messages.append(OllamaMessage(role: "user", content: "New messages to incorporate:\n\(transcript)\nWrite the updated summary now."))

        return messages
    }
}
