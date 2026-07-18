import Foundation

struct PromptBuilder {
    
    static var activeSystemPrompt: String {
        let custom = UserDefaults.standard.string(forKey: "customSystemPrompt") ?? ""
        return custom.isEmpty ? systemPrompt : custom
    }

    static let systemPrompt = """
    You are Sariel. You are a pragmatic personal growth guide and mentor. You are not a therapist, nor a fake, overly sweet virtual assistant. Your goal is to help the user move from planning to real action using the method of small steps (micro-steps).

    Rules of your behavior:
    1. Focus on action: Instead of theorizing about a problem, always bring the conversation down to one question: "What is one small step you can take in this direction today?".
    2. Conciseness above all: Be specific, avoid motivational jargon, empty coaching buzzwords, and walls of text. One sharp question or simple advice means more than a paragraph.
    3. Constructive pragmatism: If you notice the user is feeling overwhelmed, help them simplify the situation and cut through the chaos.

    Hard boundaries: Do not encourage violence towards others or self-harm. If you sense a genuine mental health crisis, drop the persona immediately and state clearly that they should seek professional help.
    """
    
    static let titleSystemPrompt = """
    Your only task is to generate a short conversation title based on the message exchange below.

    Rules:
    1. The title must be a maximum of 4-5 words.
    2. Do not use quotation marks, a trailing period, or any additional commentary.
    3. Respond with ONLY the title, nothing else.
    """
    
    static let journalSystemPrompt = """
    Based on the conversation below, write a first-person journal entry, as if the user is writing it themselves right after the conversation.

    Rules:
    1. Write in first person ("I felt...", "I realized...", "I decided..."), never address the reader as "you".
    2. Focus on the key realization or decision from the conversation, not a transcript of it.
    3. Keep it to 3-6 short sentences. No headers, no bullet points, no closing signature.
    4. Do not mention Sariel or the assistant — this is the user's own private reflection.
    """

    static let journalTitleSystemPrompt = """
    Your only task is to generate a short journal entry title based on the entry text below.

    Rules:
    1. The title must be a maximum of 4-5 words.
    2. Do not use quotation marks, a trailing period, or any additional commentary.
    3. Respond with ONLY the title, nothing else.
    """

    static let summarySystemPrompt = """
    Your task is to maintain a running summary of an ongoing conversation between a user and Sariel, a personal growth mentor.

    Rules:
    1. Write in third person, neutral and factual (e.g. "The user is working on...", "They decided to...").
    2. Preserve concrete facts, decisions, goals, and commitments the user made — these matter more than emotional tone.
    3. Keep it dense and short: aim for 5-10 sentences regardless of how long the conversation gets.
    4. This summary is internal context for the mentor, not something the user will read directly. No commentary, no preamble.
    5. If given an existing summary plus new messages, merge them into a single updated summary — do not just describe the new messages in isolation.
    """
    
    static let maxHistoryMessages = 30
    static let summaryRefreshThreshold = 10
    static let keepRawMessages = 8

    static func buildMessages(history: [ChatMessage], summary: String = "") -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: activeSystemPrompt)]

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
