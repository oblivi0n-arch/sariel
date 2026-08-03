import Testing
import SwiftData
import Foundation
@testable import sariel

struct AchievementServiceTests {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            Conversation.self,
            ChatMessage.self,
            JournalEntry.self,
            JournalEntryTag.self,
            Commitment.self,
            AchievementUnlock.self,
            SelfLetter.self,
            MeditationSession.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return ModelContext(container)
    }

    @MainActor
    private func unlock(for kind: AchievementKind, service: AchievementService, context: ModelContext) -> AchievementUnlock? {
        service.allUnlocks(modelContext: context).first { $0.achievementKind == kind }
    }

    // MARK: - nightOwl

    @Test @MainActor
    func entryJustBeforeFourAMCountsAsNightOwl() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let entry = JournalEntry(title: "t", content: "c")
        entry.createdAt = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 3, minute: 59))!
        context.insert(entry)
        try context.save()

        service.checkNightOwl(modelContext: context)

        let result = try #require(unlock(for: .nightOwl, service: service, context: context))
        #expect(result.progress == 1)
    }

    @Test @MainActor
    func entryAtFourAMDoesNotCountAsNightOwl() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let entry = JournalEntry(title: "t", content: "c")
        entry.createdAt = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 4, minute: 0))!
        context.insert(entry)
        try context.save()

        service.checkNightOwl(modelContext: context)

        let result = try #require(unlock(for: .nightOwl, service: service, context: context))
        #expect(result.progress == 0)
    }

    // MARK: - consistencyStreak

    @Test @MainActor
    func consecutiveDailyEntriesBuildStreak() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let today = Date()
        let entries = (0..<3).map { daysAgo -> JournalEntry in
            let entry = JournalEntry(title: "t\(daysAgo)", content: "c")
            entry.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            return entry
        }
        entries.forEach { context.insert($0) }
        try context.save()

        service.checkConsistencyStreak(modelContext: context)

        let result = try #require(unlock(for: .consistencyStreak, service: service, context: context))
        #expect(result.progress == 3)
    }

    @Test @MainActor
    func gapInEntriesBreaksTheStreak() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let today = Date()
        let entries = [0, 1, 3].map { daysAgo -> JournalEntry in
            let entry = JournalEntry(title: "t\(daysAgo)", content: "c")
            entry.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
            return entry
        }
        entries.forEach { context.insert($0) }
        try context.save()

        service.checkConsistencyStreak(modelContext: context)

        let result = try #require(unlock(for: .consistencyStreak, service: service, context: context))
        #expect(result.progress == 2)
    }

    // MARK: - returnedAfterSilence

    @Test @MainActor
    func gapOverTwentyOneDaysUnlocksReturnedAfterSilence() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let older = JournalEntry(title: "old", content: "c")
        older.createdAt = Date().addingTimeInterval(-21 * 24 * 60 * 60 - 60)
        let recent = JournalEntry(title: "new", content: "c")
        recent.createdAt = Date()

        context.insert(older)
        context.insert(recent)
        try context.save()

        service.checkReturnedAfterSilence(modelContext: context)

        let result = try #require(unlock(for: .returnedAfterSilence, service: service, context: context))
        #expect(result.isUnlocked == true)
    }

    @Test @MainActor
    func gapOfTwentyDaysDoesNotUnlockReturnedAfterSilence() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let older = JournalEntry(title: "old", content: "c")
        older.createdAt = Date().addingTimeInterval(-20 * 24 * 60 * 60)
        let recent = JournalEntry(title: "new", content: "c")
        recent.createdAt = Date()

        context.insert(older)
        context.insert(recent)
        try context.save()

        service.checkReturnedAfterSilence(modelContext: context)

        let result = try #require(unlock(for: .returnedAfterSilence, service: service, context: context))
        #expect(result.isUnlocked == false)
    }

    // MARK: - writingSpiral

    @Test @MainActor
    func threeEntriesWithinOneHourUnlockWritingSpiral() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let now = Date()
        let entries = (0..<3).map { offset -> JournalEntry in
            let entry = JournalEntry(title: "t\(offset)", content: "c")
            entry.createdAt = now.addingTimeInterval(Double(offset) * 10 * 60)
            return entry
        }
        entries.forEach { context.insert($0) }
        try context.save()

        service.checkWritingSpiral(modelContext: context)

        let result = try #require(unlock(for: .writingSpiral, service: service, context: context))
        #expect(result.isUnlocked == true)
    }

    @Test @MainActor
    func threeEntriesSpreadOverTwoHoursDoNotUnlockWritingSpiral() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let now = Date()
        let entries = (0..<3).map { offset -> JournalEntry in
            let entry = JournalEntry(title: "t\(offset)", content: "c")
            entry.createdAt = now.addingTimeInterval(Double(offset) * 60 * 60)
            return entry
        }
        entries.forEach { context.insert($0) }
        try context.save()

        service.checkWritingSpiral(modelContext: context)

        let result = try #require(unlock(for: .writingSpiral, service: service, context: context))
        #expect(result.isUnlocked == false)
    }

    // MARK: - commitmentsKept / firstKeptAfterBroken

    @Test @MainActor
    func streakOfFulfilledCommitmentsUpdatesCommitmentsKeptProgress() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let now = Date()
        let commitments = (0..<3).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "d\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .fulfilled
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset) * 60)
            return commitment
        }
        commitments.forEach { context.insert($0) }
        try context.save()

        service.checkCommitmentStreaks(modelContext: context)

        let result = try #require(unlock(for: .commitmentsKept, service: service, context: context))
        #expect(result.progress == 3)
    }

    @Test @MainActor
    func brokenCommitmentStopsTheKeptStreakCount() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let now = Date()
        let statuses: [CommitmentStatus] = [.fulfilled, .fulfilled, .broken]
        let commitments = statuses.enumerated().map { offset, status -> Commitment in
            let commitment = Commitment(declarationText: "d\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = status
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset) * 60)
            return commitment
        }
        commitments.forEach { context.insert($0) }
        try context.save()

        service.checkCommitmentStreaks(modelContext: context)

        let result = try #require(unlock(for: .commitmentsKept, service: service, context: context))
        #expect(result.progress == 2)
    }

    @Test @MainActor
    func firstKeptAfterBrokenRequiresExactPattern() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let now = Date()
        let statuses: [CommitmentStatus] = [.fulfilled, .broken]
        let commitments = statuses.enumerated().map { offset, status -> Commitment in
            let commitment = Commitment(declarationText: "d\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = status
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset) * 60)
            return commitment
        }
        commitments.forEach { context.insert($0) }
        try context.save()

        service.checkCommitmentStreaks(modelContext: context)

        let result = try #require(unlock(for: .firstKeptAfterBroken, service: service, context: context))
        #expect(result.isUnlocked == true)
    }

    // MARK: - tribunalFaced

    @Test @MainActor
    func firstResolvedCommitmentUnlocksTribunalFaced() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let commitment = Commitment(declarationText: "d", failureMeaning: "f")
        commitment.commitmentStatus = .fulfilled
        commitment.resolvedAt = Date()
        context.insert(commitment)
        try context.save()

        service.checkTribunalFaced(modelContext: context)

        let result = try #require(unlock(for: .tribunalFaced, service: service, context: context))
        #expect(result.isUnlocked == true)
    }

    @Test @MainActor
    func noResolvedCommitmentsDoesNotUnlockTribunalFaced() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let commitment = Commitment(declarationText: "d", failureMeaning: "f")
        context.insert(commitment)
        try context.save()

        service.checkTribunalFaced(modelContext: context)

        let result = try #require(unlock(for: .tribunalFaced, service: service, context: context))
        #expect(result.isUnlocked == false)
    }

    // MARK: - recurringTag

    @Test @MainActor
    func progressReflectsTheMostRepeatedTagAcrossEntries() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let frequentTag = JournalEntryTag(name: "anxiety")
        let rareTag = JournalEntryTag(name: "work")
        context.insert(frequentTag)
        context.insert(rareTag)

        for i in 0..<3 {
            let entry = JournalEntry(title: "t\(i)", content: "c")
            entry.tags = [frequentTag]
            context.insert(entry)
        }
        let workEntry = JournalEntry(title: "work entry", content: "c")
        workEntry.tags = [rareTag]
        context.insert(workEntry)

        try context.save()

        service.checkRecurringTag(modelContext: context)

        let result = try #require(unlock(for: .recurringTag, service: service, context: context))
        #expect(result.progress == 3)
    }

    // MARK: - tribunalVerdictsAccepted

    @Test @MainActor
    func onlyBrokenResolvedCommitmentsCountTowardVerdictsAccepted() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let now = Date()
        let brokenOnes = (0..<3).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "b\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .broken
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset) * 60)
            return commitment
        }
        let fulfilledOnes = (0..<2).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "f\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .fulfilled
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset - 10) * 60)
            return commitment
        }
        (brokenOnes + fulfilledOnes).forEach { context.insert($0) }
        try context.save()

        service.checkTribunalVerdictsAccepted(modelContext: context)

        let result = try #require(unlock(for: .tribunalVerdictsAccepted, service: service, context: context))
        #expect(result.progress == 3)
    }

    // MARK: - credibilityRecovered

    @Test @MainActor
    func credibilityRecoveredUnlocksOnlyAfterGoingFromPoorToSolid() throws {
        let key = "achievement_hasBeenPoorCredibility"
        let defaults = UserDefaults.standard
        let previousValue = defaults.bool(forKey: key)
        defaults.removeObject(forKey: key)
        defer { defaults.set(previousValue, forKey: key) }

        let context = try makeInMemoryContext()
        let service = AchievementService()
        let now = Date()

        let poorCommitments = (0..<3).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "d\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .broken
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset) * 60)
            return commitment
        }
        poorCommitments.forEach { context.insert($0) }
        try context.save()

        service.checkCredibilityRecovered(modelContext: context)
        let stillPoor = try #require(unlock(for: .credibilityRecovered, service: service, context: context))
        #expect(stillPoor.isUnlocked == false)

        let solidCommitments = (0..<10).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "s\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .fulfilled
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset - 10) * 60)
            return commitment
        }
        solidCommitments.forEach { context.insert($0) }
        try context.save()

        service.checkCredibilityRecovered(modelContext: context)
        let recovered = try #require(unlock(for: .credibilityRecovered, service: service, context: context))
        #expect(recovered.isUnlocked == true)
    }
    
    // MARK: - commitmentsBroken

    @Test @MainActor
    func brokenStreakBelowTargetDoesNotUnlockYet() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let now = Date()
        let commitments = (0..<2).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "d\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .broken
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset) * 60)
            return commitment
        }
        commitments.forEach { context.insert($0) }
        try context.save()

        service.checkCommitmentStreaks(modelContext: context)

        let result = try #require(unlock(for: .commitmentsBroken, service: service, context: context))
        #expect(result.progress == 2)
        #expect(result.isUnlocked == false)
    }
    
    @Test @MainActor
    func brokenStreakOfThreeUnlocksCommitmentsBroken() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let now = Date()
        
        let commitments = (0..<3).map { offset -> Commitment in
            let commitment = Commitment(declarationText: "d\(offset)", failureMeaning: "f")
            commitment.commitmentStatus = .broken
            commitment.resolvedAt = now.addingTimeInterval(Double(-offset) * 60)
            return commitment
        }
        commitments.forEach { context.insert($0) }
        try context.save()

        service.checkCommitmentStreaks(modelContext: context)

        let result = try #require(unlock(for: .commitmentsBroken, service: service, context: context))
        #expect(result.progress == 3)
        #expect(result.isUnlocked == true)
    }
    
    // MARK: - idempotency after unlock

    @Test @MainActor
    func onceUnlockedProgressAndUnlockDateDoNotChangeOnSubsequentChecks() throws {
        let context = try makeInMemoryContext()
        let service = AchievementService()

        let unlocks = service.allUnlocks(modelContext: context)
        let nightOwlUnlock = try #require(unlocks.first { $0.achievementKind == .nightOwl })
        let fixedUnlockDate = Date().addingTimeInterval(-1000)
        nightOwlUnlock.progress = 7
        nightOwlUnlock.unlockedAt = fixedUnlockDate
        try context.save()

        for i in 0..<10 {
            let entry = JournalEntry(title: "t\(i)", content: "c")
            entry.createdAt = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: i + 1, hour: 2))!
            context.insert(entry)
        }
        try context.save()

        service.checkNightOwl(modelContext: context)

        let result = try #require(unlock(for: .nightOwl, service: service, context: context))
        #expect(result.progress == 7)
        #expect(result.unlockedAt == fixedUnlockDate)
    }
    
    // MARK: - selfLetterFirstSealed

        @Test @MainActor
        func sealingALetterUnlocksSelfLetterFirstSealed() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let letter = SelfLetter(content: "treść", openDate: Date().addingTimeInterval(86_400))
            letter.letterStatus = .sealed
            context.insert(letter)
            try context.save()

            service.checkSelfLetterFirstSealed(modelContext: context)

            let result = try #require(unlock(for: .selfLetterFirstSealed, service: service, context: context))
            #expect(result.isUnlocked == true)
        }

        @Test @MainActor
        func onlyDraftLettersDoNotUnlockSelfLetterFirstSealed() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let letter = SelfLetter(content: "treść", openDate: Date().addingTimeInterval(86_400))
            
            context.insert(letter)
            try context.save()

            service.checkSelfLetterFirstSealed(modelContext: context)

            let result = try #require(unlock(for: .selfLetterFirstSealed, service: service, context: context))
            #expect(result.isUnlocked == false)
        }

        // MARK: - selfLetterFirstOpened

        @Test @MainActor
        func openingALetterUnlocksSelfLetterFirstOpened() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let letter = SelfLetter(content: "treść", openDate: Date())
            letter.letterStatus = .opened
            context.insert(letter)
            try context.save()

            service.checkSelfLetterFirstOpened(modelContext: context)

            let result = try #require(unlock(for: .selfLetterFirstOpened, service: service, context: context))
            #expect(result.isUnlocked == true)
        }

        @Test @MainActor
        func sealedButUnopenedLetterDoesNotUnlockSelfLetterFirstOpened() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let letter = SelfLetter(content: "treść", openDate: Date().addingTimeInterval(86_400))
            letter.letterStatus = .sealed
            context.insert(letter)
            try context.save()

            service.checkSelfLetterFirstOpened(modelContext: context)

            let result = try #require(unlock(for: .selfLetterFirstOpened, service: service, context: context))
            #expect(result.isUnlocked == false)
        }

        // MARK: - selfLetterLongestDelay

        @Test @MainActor
        func letterSealedForThreeHundredDaysUnlocksSelfLetterLongestDelay() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let now = Date()
            let letter = SelfLetter(content: "treść", openDate: Calendar.current.date(byAdding: .day, value: 300, to: now)!)
            letter.createdAt = now
            context.insert(letter)
            try context.save()

            service.checkSelfLetterLongestDelay(modelContext: context)

            let result = try #require(unlock(for: .selfLetterLongestDelay, service: service, context: context))
            #expect(result.isUnlocked == true)
        }

        @Test @MainActor
        func letterSealedForOneMonthDoesNotUnlockSelfLetterLongestDelay() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let now = Date()
            let letter = SelfLetter(content: "treść", openDate: Calendar.current.date(byAdding: .month, value: 1, to: now)!)
            letter.createdAt = now
            context.insert(letter)
            try context.save()

            service.checkSelfLetterLongestDelay(modelContext: context)

            let result = try #require(unlock(for: .selfLetterLongestDelay, service: service, context: context))
            #expect(result.isUnlocked == false)
        }

        // MARK: - meditationConsistency

        @Test @MainActor
        func threeConsecutiveDaysOfMeditationBuildStreak() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let today = Date()
            let sessions = (0..<3).map { daysAgo -> MeditationSession in
                let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 600)
                session.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
                return session
            }
            sessions.forEach { context.insert($0) }
            try context.save()

            service.checkMeditationConsistency(modelContext: context)

            let result = try #require(unlock(for: .meditationConsistency, service: service, context: context))
            #expect(result.progress == 3)
        }

        @Test @MainActor
        func gapInMeditationDaysBreaksTheStreak() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let today = Date()
            let sessions = [0, 1, 3].map { daysAgo -> MeditationSession in
                let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 600)
                session.createdAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!
                return session
            }
            sessions.forEach { context.insert($0) }
            try context.save()

            service.checkMeditationConsistency(modelContext: context)

            let result = try #require(unlock(for: .meditationConsistency, service: service, context: context))
            #expect(result.progress == 2)
        }

        // MARK: - meditationAbandonedPattern

        @Test @MainActor
        func threeConsecutiveInterruptedSessionsUnlockAbandonedPattern() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let now = Date()
            let sessions = (0..<3).map { offset -> MeditationSession in
                let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 100)
                session.createdAt = now.addingTimeInterval(Double(-offset) * 60)
                return session
            }
            sessions.forEach { context.insert($0) }
            try context.save()

            service.checkMeditationAbandonedPattern(modelContext: context)

            let result = try #require(unlock(for: .meditationAbandonedPattern, service: service, context: context))
            #expect(result.progress == 3)
            #expect(result.isUnlocked == true)
        }

        @Test @MainActor
        func mostRecentFullSessionResetsAbandonedPatternProgressToZero() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let now = Date()
            let interruptedOnes = (1..<4).map { offset -> MeditationSession in
                let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 100)
                session.createdAt = now.addingTimeInterval(Double(-offset) * 60)
                return session
            }
            let mostRecentFullSession = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 600)
            mostRecentFullSession.createdAt = now

            (interruptedOnes + [mostRecentFullSession]).forEach { context.insert($0) }
            try context.save()

            service.checkMeditationAbandonedPattern(modelContext: context)

            let result = try #require(unlock(for: .meditationAbandonedPattern, service: service, context: context))
            #expect(result.progress == 0)
        }

        // MARK: - meditationFirstFullSession

        @Test @MainActor
        func completingASessionInFullUnlocksMeditationFirstFullSession() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 600)
            context.insert(session)
            try context.save()

            service.checkMeditationFirstFullSession(modelContext: context)

            let result = try #require(unlock(for: .meditationFirstFullSession, service: service, context: context))
            #expect(result.isUnlocked == true)
        }

        @Test @MainActor
        func onlyInterruptedSessionsDoNotUnlockMeditationFirstFullSession() throws {
            let context = try makeInMemoryContext()
            let service = AchievementService()

            let session = MeditationSession(intention: "spokój", plannedDuration: 600, actualDuration: 100)
            context.insert(session)
            try context.save()

            service.checkMeditationFirstFullSession(modelContext: context)

            let result = try #require(unlock(for: .meditationFirstFullSession, service: service, context: context))
            #expect(result.isUnlocked == false)
        }
}
