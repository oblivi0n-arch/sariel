import Testing
import SwiftData
import Foundation
@testable import sariel

struct SelfLetterServiceTests {

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([SelfLetter.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        return ModelContext(container)
    }

    // MARK: - sealed -> available transition

    @Test @MainActor
    func sealedLetterWithPastOpenDateBecomesAvailable() throws {
        let context = try makeInMemoryContext()
        let now = Date()

        let letter = SelfLetter(content: "treść", openDate: now.addingTimeInterval(-60))
        letter.letterStatus = .sealed
        context.insert(letter)
        try context.save()

        SelfLetterService.refreshAvailability(context: context, now: now)

        #expect(letter.letterStatus == .available)
    }

    @Test @MainActor
    func sealedLetterWithFutureOpenDateStaysSealed() throws {
        let context = try makeInMemoryContext()
        let now = Date()

        let letter = SelfLetter(content: "treść", openDate: now.addingTimeInterval(60))
        letter.letterStatus = .sealed
        context.insert(letter)
        try context.save()

        SelfLetterService.refreshAvailability(context: context, now: now)

        #expect(letter.letterStatus == .sealed)
    }

    @Test @MainActor
    func sealedLetterWithOpenDateExactlyNowBecomesAvailable() throws {
        let context = try makeInMemoryContext()
        let now = Date()

        let letter = SelfLetter(content: "treść", openDate: now)
        letter.letterStatus = .sealed
        context.insert(letter)
        try context.save()

        SelfLetterService.refreshAvailability(context: context, now: now)

        #expect(letter.letterStatus == .available)
    }

    // MARK: - other statuses are left untouched

    @Test @MainActor
    func draftLetterIsNeverTouchedRegardlessOfOpenDate() throws {
        let context = try makeInMemoryContext()
        let now = Date()

        let letter = SelfLetter(content: "treść", openDate: now.addingTimeInterval(-60))
        
        context.insert(letter)
        try context.save()

        SelfLetterService.refreshAvailability(context: context, now: now)

        #expect(letter.letterStatus == .draft)
    }

    @Test @MainActor
    func alreadyAvailableLetterIsNotModified() throws {
        let context = try makeInMemoryContext()
        let now = Date()

        let letter = SelfLetter(content: "treść", openDate: now.addingTimeInterval(-60))
        letter.letterStatus = .available
        context.insert(letter)
        try context.save()

        SelfLetterService.refreshAvailability(context: context, now: now)

        #expect(letter.letterStatus == .available)
    }

    @Test @MainActor
    func openedLetterIsNotModified() throws {
        let context = try makeInMemoryContext()
        let now = Date()

        let letter = SelfLetter(content: "treść", openDate: now.addingTimeInterval(-60))
        letter.letterStatus = .opened
        context.insert(letter)
        try context.save()

        SelfLetterService.refreshAvailability(context: context, now: now)

        #expect(letter.letterStatus == .opened)
    }

    // MARK: - return value

    @Test @MainActor
    func returnsOnlyLettersThatJustBecameAvailable() throws {
        let context = try makeInMemoryContext()
        let now = Date()

        let shouldBecomeAvailable = SelfLetter(title: "Odblokowany", content: "treść", openDate: now.addingTimeInterval(-60))
        shouldBecomeAvailable.letterStatus = .sealed

        let stillSealed = SelfLetter(title: "Wciąż zapieczętowany", content: "treść", openDate: now.addingTimeInterval(60))
        stillSealed.letterStatus = .sealed

        let alreadyAvailable = SelfLetter(title: "Już dostępny", content: "treść", openDate: now.addingTimeInterval(-60))
        alreadyAvailable.letterStatus = .available

        [shouldBecomeAvailable, stillSealed, alreadyAvailable].forEach { context.insert($0) }
        try context.save()

        let result = SelfLetterService.refreshAvailability(context: context, now: now)

        #expect(result.count == 1)
        #expect(result.first?.id == shouldBecomeAvailable.id)
    }

    @Test @MainActor
    func returnsEmptyArrayWhenNothingBecomesAvailable() throws {
        let context = try makeInMemoryContext()
        let now = Date()

        let letter = SelfLetter(content: "treść", openDate: now.addingTimeInterval(60))
        letter.letterStatus = .sealed
        context.insert(letter)
        try context.save()

        let result = SelfLetterService.refreshAvailability(context: context, now: now)

        #expect(result.isEmpty)
    }
}
