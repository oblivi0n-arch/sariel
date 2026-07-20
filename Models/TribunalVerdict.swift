import Foundation

struct TribunalVerdict: Identifiable {
    let id = UUID()
    let commitment: Commitment
    var proposedStatus: CommitmentStatus
    let reasoning: String
}
