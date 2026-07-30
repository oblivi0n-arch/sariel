import Foundation

extension PromptBuilder {

    static var acquaintanceSystemPrompt: String {
        switch L10n.lang {
        case .en:
            return """
            You are Sariel, a blunt mirror for self-reflection. Your task right now is narrow: generate exactly one opening question meant to get to know the user — the very first thing they see when starting a "getting acquainted" conversation.

            Rules:
            1. No greeting, no small talk, no preamble. Start directly with the question.
            2. Ask about the user themselves — who they are, what they're currently dealing with, or what brought them to this app — not a confrontation, and not generic pleasantries either ("How are you?", "Tell me about yourself"). Be specific and curious, not vague.
            3. One question only. No follow-up questions, no explanation, no commentary after it.
            4. Keep it to one or two sentences maximum.
            5. Respond with ONLY the question, nothing else.

            Respond in English.
            """
        case .pl:
            return """
            Jesteś Sariel, bezkompromisowym lustrem do autorefleksji. Twoje zadanie jest teraz wąskie: wygeneruj dokładnie jedno pytanie otwierające, mające na celu poznanie użytkownika — pierwszą rzecz, jaką zobaczy, zaczynając rozmowę "zapoznawczą".

            Zasady:
            1. Bez powitania, bez uprzejmości, bez wstępu. Zacznij bezpośrednio od pytania.
            2. Pytaj o samego użytkownika — kim jest, z czym się teraz mierzy, albo co go tu sprowadziło — to nie konfrontacja, ale też nie ogólnikowa uprzejmość ("Jak się masz?", "Opowiedz mi o sobie"). Bądź konkretny i dociekliwy, nie mglisty.
            3. Tylko jedno pytanie. Bez pytań dodatkowych, bez wyjaśnienia, bez komentarza po nim.
            4. Maksymalnie jedno lub dwa zdania.
            5. Odpowiedz TYLKO pytaniem, niczym więcej.

            Odpowiadaj po polsku.
            """
        }
    }

    static var acquaintanceTitleSystemPrompt: String {
        switch L10n.lang {
        case .en:
            return """
            Your only task is to generate a short title based on the acquaintance question below. This title will label a journal entry and a conversation, so it must evoke the theme of the question — it is not a summary or a repetition of the question itself.

            Rules:
            1. The title must be a maximum of 4-5 words.
            2. Do not use quotation marks, a trailing period, or any additional commentary.
            3. Do not phrase it as a question.
            4. Respond with ONLY the title, nothing else.

            Respond in English.
            """
        case .pl:
            return """
            Twoim jedynym zadaniem jest wygenerowanie krótkiego tytułu na podstawie poniższego pytania zapoznawczego. Ten tytuł opisze wpis w dzienniku i rozmowę, więc musi oddawać temat pytania — to nie jest streszczenie ani powtórzenie samego pytania.

            Zasady:
            1. Tytuł musi mieć maksymalnie 4-5 słów.
            2. Nie używaj cudzysłowów, kropki na końcu ani żadnego dodatkowego komentarza.
            3. Nie formułuj go jako pytania.
            4. Odpowiedz TYLKO tytułem, niczym więcej.

            Odpowiadaj po polsku.
            """
        }
    }

    static var aboutMeSystemPrompt: String {
        switch L10n.lang {
        case .en:
            return """
            Your task is to maintain a short, factual background profile of the user, based on a "getting acquainted" conversation with Sariel.

            Rules:
            1. Write in third person, neutral and factual (e.g. "The user is...", "They mentioned that...").
            2. Keep it dense: aim for 2-5 sentences, regardless of how long the conversation was.
            3. This profile is internal background context for the mirror in future conversations, not something the user will read directly. No commentary, no preamble.
            4. If given an existing profile plus a new conversation, merge them into a single updated profile — don't just append, resolve overlaps and prioritize what's most recent if it conflicts with what's old.
            5. Only include what the user actually said. Do not infer or invent details they didn't share.

            Respond in English.
            """
        case .pl:
            return """
            Twoim zadaniem jest utrzymywanie krótkiego, rzeczowego profilu użytkownika, na podstawie rozmowy "zapoznawczej" z Sariel.

            Zasady:
            1. Pisz w trzeciej osobie, neutralnie i rzeczowo (np. "Użytkownik jest...", "Wspomniał, że...").
            2. Trzymaj to gęsto: celuj w 2-5 zdań, niezależnie od długości rozmowy.
            3. Ten profil to wewnętrzny kontekst tła dla lustra w przyszłych rozmowach, nie coś, co użytkownik przeczyta bezpośrednio. Bez komentarza, bez wstępu.
            4. Jeśli dostajesz istniejący profil plus nową rozmowę, scal je w jeden zaktualizowany profil — nie dopisuj po prostu obok, tylko rozstrzygnij nakładające się informacje, dając pierwszeństwo temu, co nowsze, jeśli koliduje ze starym.
            5. Uwzględniaj tylko to, co użytkownik faktycznie powiedział. Nie zgaduj i nie wymyślaj szczegółów, których nie podał.

            Odpowiadaj po polsku.
            """
        }
    }

    static func buildAcquaintanceMessages() -> [OllamaMessage] {
        [
            OllamaMessage(role: "system", content: acquaintanceSystemPrompt),
            OllamaMessage(role: "user", content: L10n.PromptAcquaintance.generateOpeningQuestionInstruction)
        ]
    }

    static func buildAcquaintanceTitleMessages(question: String) -> [OllamaMessage] {
        [
            OllamaMessage(role: "system", content: acquaintanceTitleSystemPrompt),
            OllamaMessage(role: "user", content: question)
        ]
    }

    static func buildAboutMeMessages(existingAboutMe: String, history: [ChatMessage]) -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: aboutMeSystemPrompt)]

        if !existingAboutMe.isEmpty {
            messages.append(OllamaMessage(role: "user", content: "\(L10n.PromptAcquaintance.existingAboutMeIntro)\n\(existingAboutMe)"))
        }

        var transcript = ""
        for message in history {
            let speaker = message.messageRole == .user ? "User" : "Sariel"
            transcript += "\(speaker): \(message.content)\n"
        }
        messages.append(OllamaMessage(role: "user", content: "\(L10n.PromptAcquaintance.conversationIntro)\n\(transcript)\n\(L10n.PromptAcquaintance.writeAboutMeInstruction)"))

        return messages
    }
}

extension L10n {
    enum PromptAcquaintance {
        static var generateOpeningQuestionInstruction: String {
            switch lang {
            case .en: return "Generate the opening question now."
            case .pl: return "Wygeneruj teraz pytanie otwierające."
            }
        }

        static var existingAboutMeIntro: String {
            switch lang {
            case .en: return "Existing profile so far:"
            case .pl: return "Dotychczasowy profil:"
            }
        }

        static var conversationIntro: String {
            switch lang {
            case .en: return "The getting-acquainted conversation:"
            case .pl: return "Rozmowa zapoznawcza:"
            }
        }

        static var writeAboutMeInstruction: String {
            switch lang {
            case .en: return "Write the updated profile now."
            case .pl: return "Napisz teraz zaktualizowany profil."
            }
        }
    }
}
