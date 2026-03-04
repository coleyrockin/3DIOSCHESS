import Foundation

enum AIDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var depth: Int {
        switch self {
        case .easy:
            return 1
        case .medium:
            return 2
        case .hard:
            return 3
        }
    }

    var description: String {
        switch self {
        case .easy:
            return "Easy - AI thinks 1 move ahead"
        case .medium:
            return "Medium - AI thinks 2 moves ahead"
        case .hard:
            return "Hard - AI thinks 3 moves ahead (slower)"
        }
    }
}
