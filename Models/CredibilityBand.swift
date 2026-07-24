import Foundation

enum CredibilityBand: String {
    case insufficientData
    case poor
    case mixed
    case solid

    var promptDescription: String {
        switch self {
        case .insufficientData: return "not enough resolved declarations yet to judge"
        case .poor:   return "poor — mostly breaks declared commitments"
        case .mixed:  return "mixed — sometimes keeps declared commitments, sometimes breaks them"
        case .solid:  return "solid — mostly keeps declared commitments"
        }
    }

    var displayName: String {
        switch self {
        case .insufficientData: return L10n.Credibility.insufficientData
        case .poor: return L10n.Credibility.poor
        case .mixed: return L10n.Credibility.mixed
        case .solid: return L10n.Credibility.solid
        }
    }

    static let sampleMinimum = 3

    static func evaluate(from commitments: [Commitment]) -> CredibilityBand {
        let resolved = commitments.filter { $0.commitmentStatus != .pending }
        guard resolved.count >= sampleMinimum else { return .insufficientData }

        let fulfilledCount = resolved.filter { $0.commitmentStatus == .fulfilled }.count
        let percentage = Double(fulfilledCount) / Double(resolved.count) * 100

        switch percentage {
        case 0..<40: return .poor
        case 40..<70: return .mixed
        default: return .solid
        }
    }

    static func percentage(from commitments: [Commitment]) -> Double? {
        let resolved = commitments.filter { $0.commitmentStatus != .pending }
        guard resolved.count >= sampleMinimum else { return nil }

        let fulfilledCount = resolved.filter { $0.commitmentStatus == .fulfilled }.count
        return Double(fulfilledCount) / Double(resolved.count) * 100
    }
}

extension L10n {
    enum Credibility {
        static var insufficientData: String {
            switch lang {
            case .en: return "insufficient data"
            case .pl: return "za mało danych"
            }
        }
        static var poor: String {
            switch lang {
            case .en: return "poor"
            case .pl: return "słaba"
            }
        }
        static var mixed: String {
            switch lang {
            case .en: return "mixed"
            case .pl: return "mieszana"
            }
        }
        static var solid: String {
            switch lang {
            case .en: return "solid"
            case .pl: return "solidna"
            }
        }
    }
}
