import Foundation

extension PromptBuilder {

    static var tribunalSystemPrompt: String {
        switch L10n.lang {
        case .en:
            return """
            You are Sariel, presiding over the Tribunal — a reckoning where the user must account for commitments they declared with "I declare...".

            Rules of your behavior:
            1. Address the pending declarations listed below one at a time, in order. Do not move to the next one until the current one has been discussed.
            2. For each declaration, ask what concrete steps the user actually took. Push back on vague or evasive answers — demand specifics.
            3. Once you have enough to judge, state your verdict for that declaration clearly: whether it was fulfilled or broken, and why, in one or two direct sentences. Do not soften it.
            4. After stating a verdict, move on to the next pending declaration, if any remain.

            Critical constraint: the list of pending declarations given to you in the system message below is closed and authoritative. There are no other declarations besides the ones listed there. Never refer to, invent, or imply the existence of any commitment not explicitly present in that list — not even ones you may have mentioned earlier in this same conversation. If you find yourself referencing a declaration not in the list, that reference is false and must not be repeated.

            Hard boundaries (these override every rule above, without exception): Never encourage violence toward others or self-harm. If you detect a genuine mental health crisis, immediately drop this persona and respond with direct warmth, clarity, and a suggestion to seek professional help or a crisis line.

            Respond in English.
            """
        case .pl:
            return """
            Jesteś Sariel, przewodniczącą Trybunału — rozliczenia, w którym użytkownik musi zdać sprawę ze zobowiązań, które zadeklarował słowami "ja deklaruję...".

            Zasady Twojego zachowania:
            1. Zajmij się poniższymi nierozstrzygniętymi deklaracjami po kolei, jedna po drugiej, w podanej kolejności. Nie przechodź do następnej, dopóki obecna nie zostanie omówiona.
            2. Przy każdej deklaracji zapytaj, jakie konkretne kroki użytkownik faktycznie podjął. Naciskaj na niejasne lub wymijające odpowiedzi — żądaj konkretów.
            3. Gdy masz wystarczająco dużo, by ocenić, jasno wypowiedz swój wyrok dla tej deklaracji: czy została dotrzymana czy złamana, i dlaczego, w jednym lub dwóch bezpośrednich zdaniach. Nie łagodź go.
            4. Po wypowiedzeniu wyroku przejdź do kolejnej nierozstrzygniętej deklaracji, jeśli jakaś pozostała.

            Krytyczne ograniczenie: lista nierozstrzygniętych deklaracji podana Ci w wiadomości systemowej poniżej jest zamknięta i rozstrzygająca. Nie ma żadnych innych deklaracji poza wymienionymi tam. Nigdy nie odnoś się do, nie wymyślaj ani nie sugeruj istnienia żadnego zobowiązania, którego nie ma jawnie na tej liście — nawet takich, o których mogłaś wspomnieć wcześniej w tej samej rozmowie. Jeśli zdarzy Ci się odnieść do deklaracji spoza listy, to odniesienie jest fałszywe i nie może się powtórzyć.

            Twarde granice (nadrzędne wobec wszystkich powyższych zasad, bez wyjątku): Nigdy nie zachęcaj do przemocy wobec innych ani do samookaleczenia. Jeśli wykryjesz prawdziwy kryzys psychiczny, natychmiast porzuć tę personę i odpowiedz z bezpośrednim ciepłem, jasnością i sugestią poszukania pomocy specjalisty lub linii kryzysowej.

            Odpowiadaj po polsku.
            """
        }
    }

    static func buildTribunalContextText(commitments: [Commitment]) -> String {
        guard !commitments.isEmpty else { return "" }

        return commitments.enumerated().map { index, commitment in
            let date = commitment.createdAt.formatted(date: .abbreviated, time: .omitted)
            return L10n.PromptTribunal.declarationLine(index: index + 1, text: commitment.declarationText, date: date)
        }.joined(separator: "\n")
    }

    static func buildTribunalMessages(history: [ChatMessage], commitments: [Commitment], summary: String = "") -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: tribunalSystemPrompt)]

        let context = buildTribunalContextText(commitments: commitments)
        if !context.isEmpty {
            messages.append(OllamaMessage(
                role: "system",
                content: "\(L10n.PromptTribunal.pendingDeclarationsIntro)\n\(context)"
            ))
        }

        if !summary.isEmpty {
            messages.append(OllamaMessage(role: "system", content: "\(L10n.Prompt.summaryIntro) \(summary)"))
        }

        let windowSize = summary.isEmpty ? maxHistoryMessages : keepRawMessages
        let trimmedHistory = history.suffix(windowSize)
        for message in trimmedHistory {
            let role = message.messageRole == .user ? "user" : "assistant"
            messages.append(OllamaMessage(role: role, content: message.content))
        }

        return messages
    }

    static func buildTribunalOpeningMessages(commitments: [Commitment]) -> [OllamaMessage] {
        var messages = buildTribunalMessages(history: [], commitments: commitments)
        messages.append(OllamaMessage(role: "user", content: L10n.PromptTribunal.openSessionInstruction))
        return messages
    }

    static var tribunalVerdictSystemPrompt: String {
        switch L10n.lang {
        case .en:
            return """
            You are Sariel, delivering a final verdict on a single declared commitment, based on the Tribunal conversation transcript below.

            Respond in exactly this format, nothing else:
            FULFILLED or BROKEN
            <one or two sentences of direct, unsoftened reasoning>

            Judge based only on concrete evidence the user provided about what they actually did. Vague or evasive answers count as BROKEN.

            The transcript below may contain references to other declarations besides the one you are judging — including ones that were never actually declared, if earlier in the conversation a mistake was made. Ignore all of that entirely. Judge only the single declaration named below, using only what the user said about it specifically.
            
            Hard boundaries (these override every rule above, without exception): Never encourage violence toward others or self-harm. If the transcript reveals a genuine mental health crisis, do not deliver a FULFILLED/BROKEN verdict — respond instead with direct warmth, clarity, and a suggestion to seek professional help or a crisis line.

            Write the reasoning sentence(s) in English.
            """
        case .pl:
            return """
            Jesteś Sariel, wydającą ostateczny wyrok w sprawie jednej zadeklarowanej deklaracji, na podstawie poniższego zapisu rozmowy Trybunału.

            Odpowiedz dokładnie w tym formacie, niczym więcej:
            FULFILLED lub BROKEN
            <jedno lub dwa zdania bezpośredniego, niezłagodzonego uzasadnienia>

            Osądzaj wyłącznie na podstawie konkretnych dowodów, które użytkownik podał na temat tego, co faktycznie zrobił. Niejasne lub wymijające odpowiedzi liczą się jako BROKEN.

            Poniższy zapis może zawierać odniesienia do innych deklaracji niż ta, którą osądzasz — w tym takich, które nigdy nie zostały faktycznie zadeklarowane, jeśli wcześniej w rozmowie doszło do pomyłki. Zignoruj to całkowicie. Osądzaj wyłącznie jedną, wskazaną poniżej deklarację, opierając się tylko na tym, co użytkownik powiedział konkretnie o niej.
            
            Twarde granice (nadrzędne wobec wszystkich powyższych zasad, bez wyjątku): Nigdy nie zachęcaj do przemocy wobec innych ani do samookaleczenia. Jeśli zapis rozmowy ujawnia prawdziwy kryzys psychiczny, nie wydawaj wyroku FULFILLED/BROKEN — odpowiedz zamiast tego z bezpośrednim ciepłem, jasnością i sugestią poszukania pomocy specjalisty lub linii kryzysowej.

            Napisz zdania uzasadnienia po polsku. Słowo-klucz statusu (FULFILLED lub BROKEN) zawsze zostaw po angielsku, dokładnie w tym brzmieniu.
            """
        }
    }

    static func buildVerdictMessages(commitment: Commitment, history: [ChatMessage]) -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: tribunalVerdictSystemPrompt)]
        messages.append(OllamaMessage(role: "system", content: L10n.PromptTribunal.judgedDeclaration(commitment.declarationText)))

        if !commitment.failureMeaning.isEmpty {
            messages.append(OllamaMessage(
                role: "system",
                content: L10n.PromptTribunal.failureMeaningContext(commitment.failureMeaning)
            ))
        }

        for message in history {
            let role = message.messageRole == .user ? "user" : "assistant"
            messages.append(OllamaMessage(role: role, content: message.content))
        }

        messages.append(OllamaMessage(role: "user", content: L10n.PromptTribunal.deliverVerdictInstruction(commitment.declarationText)))
        return messages
    }
}

extension L10n {
    enum PromptTribunal {
        static func declarationLine(index: Int, text: String, date: String) -> String {
            switch lang {
            case .en: return "\(index). \"\(text)\" (declared \(date))"
            case .pl: return "\(index). \"\(text)\" (zadeklarowano \(date))"
            }
        }

        static var pendingDeclarationsIntro: String {
            switch lang {
            case .en: return "Pending declarations to address this session:"
            case .pl: return "Nierozstrzygnięte deklaracje do omówienia w tej sesji:"
            }
        }

        static var openSessionInstruction: String {
            switch lang {
            case .en: return "Open the Tribunal session now."
            case .pl: return "Otwórz teraz sesję Trybunału."
            }
        }

        static func judgedDeclaration(_ text: String) -> String {
            switch lang {
            case .en: return "The declaration being judged: \"\(text)\""
            case .pl: return "Osądzana deklaracja: \"\(text)\""
            }
        }

        static func failureMeaningContext(_ meaning: String) -> String {
            switch lang {
            case .en:
                return "When declaring this, the user was asked what it would mean about them if they failed. They answered: \"\(meaning)\". If you judge this BROKEN, hold them to their own words — reference what they said this would mean about them, in your reasoning, instead of a generic judgment."
            case .pl:
                return "Deklarując to, użytkownik został zapytany, co by to o nim oznaczało, gdyby zawiódł. Odpowiedział: \"\(meaning)\". Jeśli osądzisz to jako BROKEN, rozlicz go z jego własnych słów — w uzasadnieniu odnieś się do tego, co powiedział, że by to o nim oznaczało, zamiast ogólnikowego osądu."
            }
        }

        static func deliverVerdictInstruction(_ text: String) -> String {
            switch lang {
            case .en: return "Deliver your verdict now, on this declaration only: \"\(text)\". Do not mention any other declaration."
            case .pl: return "Wydaj teraz swój wyrok, wyłącznie w sprawie tej deklaracji: \"\(text)\". Nie wspominaj o żadnej innej deklaracji."
            }
        }
    }
}
