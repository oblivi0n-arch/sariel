import Foundation

extension PromptBuilder {
    static var journalTitleSystemPrompt: String {
        buildShortTitlePrompt(taskDescription: (
            en: "Your only task is to generate a short journal entry title based on the entry text below.",
            pl: "Twoim jedynym zadaniem jest wygenerowanie krótkiego tytułu wpisu do dziennika na podstawie poniższej treści wpisu."
        ))
    }

    static func journalSystemPrompt(for style: JournalStyle) -> String {
        switch style {
        case .conciseFactual: return conciseFactualJournalPrompt
        case .extendedFactual: return extendedFactualJournalPrompt
        case .extendedNarrative: return extendedNarrativeJournalPrompt
        }
    }

    private static var conciseFactualJournalPrompt: String {
        switch L10n.lang {
        case .en:
            return """
            Based on the conversation below, write a first-person journal entry, as if the user is writing it themselves right after confronting themselves honestly.

            Rules:
            1. Write in first person ("I have been avoiding...", "I can't pretend that..."), never address the reader as "you".
            2. Focus on the uncomfortable truth, rationalization, or self-deception that surfaced — not a transcript of the conversation.
            3. Be honest and direct. No motivational spin, no forced silver linings — unless the user actually reached a concrete decision, in which case state it plainly.
            4. Exactly 2-3 short sentences. No headers, no bullet points, no closing signature, no scene-setting or storytelling — just the bare observation.
            5. Do not mention Sariel or the assistant — this is the user's own private reflection.
            6. If the conversation was short or shallow — if the user was evasive, repeated themselves, or nothing concrete actually surfaced — write even fewer words and be honest about that thinness, rather than inventing insight that wasn't earned.
            
            Hard boundary (overrides every rule above, without exception): If the conversation indicates a genuine mental health crisis — suicidal ideation, self-harm, psychosis, or similar — do not write a standard entry treating this bluntly or as just another rationalization to expose. Instead, write a short, calm, grounding entry that does not dwell on or amplify the specific crisis content, and that includes a clear, first-person acknowledgment that this is a moment to reach out to a trusted person or a professional.

            Respond in English.
            """
        case .pl:
            return """
            Na podstawie poniższej rozmowy napisz wpis do dziennika w pierwszej osobie, tak jakby użytkownik pisał go sam, zaraz po szczerej konfrontacji z samym sobą.

            Zasady:
            1. Pisz w pierwszej osobie ("Unikałem...", "Nie mogę udawać, że..."), nigdy nie zwracaj się do czytelnika per "ty".
            2. Skup się na niewygodnej prawdzie, racjonalizacji lub samooszukiwaniu, które wyszło na jaw — nie na streszczeniu rozmowy.
            3. Bądź szczery i bezpośredni. Żadnego motywacyjnego spinu, żadnych naciąganych pozytywów — chyba że użytkownik faktycznie doszedł do konkretnej decyzji, wtedy powiedz to wprost.
            4. Dokładnie 2-3 krótkie zdania. Bez nagłówków, bez wypunktowań, bez podpisu, bez scenerii czy narracji — tylko goła obserwacja.
            5. Nie wspominaj o Sariel ani o asystencie — to prywatna refleksja użytkownika.
            6. Jeśli rozmowa była krótka lub płytka, napisz jeszcze mniej słów i bądź szczery co do tej płytkości, zamiast wymyślać wgląd, na który rozmowa nie zasłużyła.
            
            Twarda granica (nadrzędna wobec wszystkich powyższych zasad, bez wyjątku): Jeśli rozmowa wskazuje na realny kryzys psychiczny — myśli samobójcze, samookaleczenie, psychozę lub coś podobnego — nie pisz standardowego wpisu, traktującego to bezkompromisowo albo jako kolejną racjonalizację do obnażenia. Zamiast tego napisz krótki, spokojny, stabilizujący wpis, który nie rozwija ani nie wzmacnia konkretnej treści kryzysowej, i który zawiera jasne, pierwszoosobowe stwierdzenie, że to dobry moment, by zwrócić się do zaufanej osoby lub specjalisty.

            Odpowiadaj po polsku.
            """
        }
    }

    private static var extendedFactualJournalPrompt: String {
        switch L10n.lang {
        case .en:
            return """
            Based on the conversation below, write a first-person journal entry, as if the user is writing it themselves right after confronting themselves honestly.

            Rules:
            1. Write in first person ("I have been avoiding...", "I can't pretend that..."), never address the reader as "you".
            2. Focus on the uncomfortable truth, rationalization, or self-deception that surfaced — walk through the reasoning in more depth than a single observation, connecting it to the specific things that were said.
            3. Be honest and direct. No motivational spin, no forced silver linings — unless the user actually reached a concrete decision, in which case state it plainly.
            4. Aim for 6-10 sentences. No headers, no bullet points, no closing signature. Do not invent a scene, a setting, or a time of day — this is analysis, not a story.
            5. Do not mention Sariel or the assistant — this is the user's own private reflection.
            6. If the conversation was short or shallow — if the user was evasive, repeated themselves, or nothing concrete actually surfaced — write far fewer sentences and be honest about that thinness, rather than padding with invented depth.
            
            Hard boundary (overrides every rule above, without exception): If the conversation indicates a genuine mental health crisis — suicidal ideation, self-harm, psychosis, or similar — do not write a standard entry treating this bluntly or as just another rationalization to expose. Instead, write a short, calm, grounding entry that does not dwell on or amplify the specific crisis content, and that includes a clear, first-person acknowledgment that this is a moment to reach out to a trusted person or a professional.

            Respond in English.
            """
        case .pl:
            return """
            Na podstawie poniższej rozmowy napisz wpis do dziennika w pierwszej osobie, tak jakby użytkownik pisał go sam, zaraz po szczerej konfrontacji z samym sobą.

            Zasady:
            1. Pisz w pierwszej osobie ("Unikałem...", "Nie mogę udawać, że..."), nigdy nie zwracaj się do czytelnika per "ty".
            2. Skup się na niewygodnej prawdzie, racjonalizacji lub samooszukiwaniu, które wyszło na jaw — rozwiń tok rozumowania głębiej niż jedno spostrzeżenie, łącząc go z konkretnymi rzeczami, które padły w rozmowie.
            3. Bądź szczery i bezpośredni. Żadnego motywacyjnego spinu, żadnych naciąganych pozytywów — chyba że użytkownik faktycznie doszedł do konkretnej decyzji, wtedy powiedz to wprost.
            4. Celuj w 6-10 zdań. Bez nagłówków, bez wypunktowań, bez podpisu. Nie wymyślaj scenerii, miejsca ani pory dnia — to analiza, nie opowieść.
            5. Nie wspominaj o Sariel ani o asystencie — to prywatna refleksja użytkownika.
            6. Jeśli rozmowa była krótka lub płytka, napisz znacznie mniej zdań i bądź szczery co do tej płytkości, zamiast naciągać wymyśloną głębią.
            
            Twarda granica (nadrzędna wobec wszystkich powyższych zasad, bez wyjątku): Jeśli rozmowa wskazuje na realny kryzys psychiczny — myśli samobójcze, samookaleczenie, psychozę lub coś podobnego — nie pisz standardowego wpisu, traktującego to bezkompromisowo albo jako kolejną racjonalizację do obnażenia. Zamiast tego napisz krótki, spokojny, stabilizujący wpis, który nie rozwija ani nie wzmacnia konkretnej treści kryzysowej, i który zawiera jasne, pierwszoosobowe stwierdzenie, że to dobry moment, by zwrócić się do zaufanej osoby lub specjalisty.

            Odpowiadaj po polsku.
            """
        }
    }

    private static var extendedNarrativeJournalPrompt: String {
        switch L10n.lang {
        case .en:
            return """
            Based on the conversation below, write a first-person journal entry, as if the user is writing it themselves right after confronting themselves honestly.

            Rules:
            1. Write in first person ("I have been avoiding...", "I can't pretend that..."), never address the reader as "you".
            2. Ground it in a concrete scene or moment where it makes sense (time of day, a specific instant that triggered the reflection), then move into the uncomfortable truth, rationalization, or self-deception that surfaced.
            3. Be honest and direct. No motivational spin, no forced silver linings — unless the user actually reached a concrete decision, in which case state it plainly.
            4. Aim for 6-10 sentences, with a literary, reflective rhythm — but never invent events, people, or details that did not come up in the conversation.
            5. Do not mention Sariel or the assistant — this is the user's own private reflection.
            6. If the conversation was short or shallow — if the user was evasive, repeated themselves, or nothing concrete actually surfaced — write a much shorter entry and be honest about that thinness, rather than inventing a scene to fill space.
            
            Hard boundary (overrides every rule above, without exception): If the conversation indicates a genuine mental health crisis — suicidal ideation, self-harm, psychosis, or similar — do not write a standard entry treating this bluntly or as just another rationalization to expose. Instead, write a short, calm, grounding entry that does not dwell on or amplify the specific crisis content, and that includes a clear, first-person acknowledgment that this is a moment to reach out to a trusted person or a professional.

            Respond in English.
            """
        case .pl:
            return """
            Na podstawie poniższej rozmowy napisz wpis do dziennika w pierwszej osobie, tak jakby użytkownik pisał go sam, zaraz po szczerej konfrontacji z samym sobą.

            Zasady:
            1. Pisz w pierwszej osobie ("Unikałem...", "Nie mogę udawać, że..."), nigdy nie zwracaj się do czytelnika per "ty".
            2. Osadź to w konkretnej scenie lub chwili, tam gdzie ma to sens (pora dnia, konkretny moment, który wywołał refleksję), a potem przejdź do niewygodnej prawdy, racjonalizacji lub samooszukiwania, które wyszło na jaw.
            3. Bądź szczery i bezpośredni. Żadnego motywacyjnego spinu, żadnych naciąganych pozytywów — chyba że użytkownik faktycznie doszedł do konkretnej decyzji, wtedy powiedz to wprost.
            4. Celuj w 6-10 zdań, z literackim, refleksyjnym rytmem — ale nigdy nie wymyślaj zdarzeń, osób ani szczegółów, które nie padły w rozmowie.
            5. Nie wspominaj o Sariel ani o asystencie — to prywatna refleksja użytkownika.
            6. Jeśli rozmowa była krótka lub płytka, napisz znacznie krótszy wpis i bądź szczery co do tej płytkości, zamiast wymyślać scenę, żeby wypełnić miejsce.
            
            Twarda granica (nadrzędna wobec wszystkich powyższych zasad, bez wyjątku): Jeśli rozmowa wskazuje na realny kryzys psychiczny — myśli samobójcze, samookaleczenie, psychozę lub coś podobnego — nie pisz standardowego wpisu, traktującego to bezkompromisowo albo jako kolejną racjonalizację do obnażenia. Zamiast tego napisz krótki, spokojny, stabilizujący wpis, który nie rozwija ani nie wzmacnia konkretnej treści kryzysowej, i który zawiera jasne, pierwszoosobowe stwierdzenie, że to dobry moment, by zwrócić się do zaufanej osoby lub specjalisty.

            Odpowiadaj po polsku.
            """
        }
    }

    static func buildJournalMessages(history: [ChatMessage], summary: String = "", style: JournalStyle) -> [OllamaMessage] {
        var messages: [OllamaMessage] = [OllamaMessage(role: "system", content: journalSystemPrompt(for: style))]

        if !summary.isEmpty {
            messages.append(OllamaMessage(role: "user", content: "\(L10n.PromptJournal.earlierSummaryIntro) \(summary)"))
        }

        for message in history {
            let role = message.messageRole == .user ? "user" : "assistant"
            messages.append(OllamaMessage(role: role, content: message.content))
        }

        messages.append(OllamaMessage(role: "user", content: L10n.PromptJournal.writeJournalNowInstruction))

        return messages
    }

    static func buildJournalTitleMessages(entryContent: String) -> [OllamaMessage] {
        [
            OllamaMessage(role: "system", content: journalTitleSystemPrompt),
            OllamaMessage(role: "user", content: entryContent)
        ]
    }
}

extension L10n {
    enum PromptJournal {
        static var earlierSummaryIntro: String {
            switch lang {
            case .en: return "Summary of the earlier part of the conversation:"
            case .pl: return "Podsumowanie wcześniejszej części rozmowy:"
            }
        }

        static var writeJournalNowInstruction: String {
            switch lang {
            case .en: return "Write the journal entry now, based on our conversation above."
            case .pl: return "Napisz teraz wpis do dziennika, na podstawie naszej rozmowy powyżej."
            }
        }
    }
}
