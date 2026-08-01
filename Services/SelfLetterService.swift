import Foundation
import SwiftData

enum SelfLetterService {
    @discardableResult
    static func refreshAvailability(context: ModelContext, now: Date = Date()) -> [SelfLetter] {
        let descriptor = FetchDescriptor<SelfLetter>()
        guard let letters = try? context.fetch(descriptor) else { return [] }

        var newlyAvailable: [SelfLetter] = []
        for letter in letters where letter.letterStatus == .sealed {
            if letter.openDate <= now {
                letter.letterStatus = .available
                newlyAvailable.append(letter)
            }
        }

        try? context.save()
        return newlyAvailable
    }
}
