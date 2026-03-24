import Foundation

struct DailyEntry: Codable {
    let tired: String
    let wanted: String
    let colorName: String
    let colorHex: String
    let colorAssociation: String
    let advice: String
    var playModeActivated: Bool
    var completedIdeaIDs: [Int]
}

struct IdeaTimerState: Codable {
    var remainingSeconds: Int
    var isRunning: Bool
    var startedAt: TimeInterval?
    var isDone: Bool
}

struct PlayDayState: Codable {
    var shownIdeaIDs: [Int]
    var currentIdeaIDs: [Int]
    var timers: [Int: IdeaTimerState]
}

struct PlayIdea: Identifiable, Codable {
    let id: Int
    let title: String
    let category: String
    let minutes: Int
}

struct PaletteColor {
    let name: String
    let hex: String
    let meaning: String
}

struct DayEntry {
    let color: PaletteColor
    let tired: String
    let wanted: String
    let advice: String
}

enum AppTab {
    case light
    case calendar
    case stats
}

enum PlayModeStage {
    case intro
    case tasks
}
