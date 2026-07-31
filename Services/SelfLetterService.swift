import Foundation
import SwiftData

enum SelfLetterService {
    static func refreshAvailability(context: ModelContext, now: Date = Date()) {
        let descriptor = FetchDescriptor<SelfLetter>()
        guard let letters = try? context.fetch(descriptor) else { return }

        for letter in letters where letter.letterStatus == .sealed {
            if letter.openDate <= now {
                letter.letterStatus = .available
            }
        }

        try? context.save()
    }
}
