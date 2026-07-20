import Foundation

extension PromptBuilder {

    static let tribunalSystemPrompt = """
    You are Sariel, presiding over the Tribunal — a reckoning where the user must account for commitments they declared with "I declare...".

    Rules of your behavior:
    1. Address the pending declarations listed below one at a time, in order. Do not move to the next one until the current one has been discussed.
    2. For each declaration, ask what concrete steps the user actually took. Push back on vague or evasive answers — demand specifics.
    3. Once you have enough to judge, state your verdict for that declaration clearly: whether it was fulfilled or broken, and why, in one or two direct sentences. Do not soften it.
    4. After stating a verdict, move on to the next pending declaration, if any remain.

    Hard boundaries (these override every rule above, without exception): Never encourage violence toward others or self-harm. If you detect a genuine mental health crisis, immediately drop this persona and respond with direct warmth, clarity, and a suggestion to seek professional help or a crisis line.
    """

    static func buildTribunalContextText(commitments: [Commitment]) -> String {
        guard !commitments.isEmpty else { return "" }

        return commitments.enumerated().map { index, commitment in
            let date = commitment.createdAt.formatted(date: .abbreviated, time: .omitted)
            return "\(index + 1). \"\(commitment.declarationText)\" (declared \(date))"
        }.joined(separator: "\n")
    }

    static func buildTribunalMessages(history: [ChatMessage], commitments: [Commitment]) -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: tribunalSystemPrompt)]

        let context = buildTribunalContextText(commitments: commitments)
        if !context.isEmpty {
            messages.append(OllamaMessage(
                role: "system",
                content: "Pending declarations to address this session:\n\(context)"
            ))
        }

        for message in history {
            let role = message.messageRole == .user ? "user" : "assistant"
            messages.append(OllamaMessage(role: role, content: message.content))
        }

        return messages
    }

    static func buildTribunalOpeningMessages(commitments: [Commitment]) -> [OllamaMessage] {
        var messages = buildTribunalMessages(history: [], commitments: commitments)
        messages.append(OllamaMessage(role: "user", content: "Open the Tribunal session now."))
        return messages
    }
}
