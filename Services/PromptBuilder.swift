import Foundation

struct PromptBuilder {

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
    
    static let maxHistoryMessages = 30

    static func buildMessages(history: [ChatMessage]) -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: systemPrompt)]

        let trimmedHistory = history.suffix(maxHistoryMessages)
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
}
