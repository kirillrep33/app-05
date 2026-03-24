import Foundation

final class DaySurveyViewModel: ObservableObject {
    private let entriesKey = "hca_entries_v1"
    private let playStateKey = "hca_play_state_v1"

    func loadEntries() -> [String: DailyEntry] {
        guard let data = UserDefaults.standard.data(forKey: entriesKey) else { return [:] }
        return (try? JSONDecoder().decode([String: DailyEntry].self, from: data)) ?? [:]
    }

    func loadPlayStates() -> [String: PlayDayState] {
        guard let data = UserDefaults.standard.data(forKey: playStateKey) else { return [:] }
        return (try? JSONDecoder().decode([String: PlayDayState].self, from: data)) ?? [:]
    }

    func saveEntries(_ entries: [String: DailyEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: entriesKey)
    }

    func savePlayStates(_ states: [String: PlayDayState]) {
        guard let data = try? JSONEncoder().encode(states) else { return }
        UserDefaults.standard.set(data, forKey: playStateKey)
    }

    func generateAdvice(tired: String?, wanted: String?, colorName: String?) -> String {
        guard let tired, let wanted else {
            return "Take a short pause and listen to what your evening needs."
        }
        if colorName == "Black" {
            return "Your body needs sleep. Go to bed one hour earlier tonight."
        }
        if colorName == "Gray" {
            return "Work took too much today. Switch on Play Mode now."
        }
        switch (tired, wanted) {
        case ("Body", "Silence"):
            return "You need green peace. Take a hot bath without your phone."
        case ("Body", "Movement"):
            return "Wake up your muscles with a light stretch and your favorite playlist."
        case ("Body", "Communication"):
            return "Meet someone close and keep it simple. No plans, just connection."
        case ("Mind", "Silence"):
            return "Do an information detox. Turn off notifications for the next two hours."
        case ("Mind", "Movement"):
            return "Take a walk with no destination and let your thoughts rest."
        case ("Mind", "Communication"):
            return "Talk to someone outside your work context and reset your perspective."
        case ("Soul", "Silence"):
            return "Spend quiet time with yourself: journal, meditate, or simply breathe."
        case ("Soul", "Movement"):
            return "Dance like nobody is watching and release emotion through movement."
        case ("Soul", "Communication"):
            return "Call someone who inspires you and share dreams, not problems."
        default:
            return "Take one kind action for yourself tonight."
        }
    }

    func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func dateFromKey(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    var playIdeasPool: [PlayIdea] {
        [
            PlayIdea(id: 1, title: "Draw something silly with your non-dominant hand", category: "Creativity", minutes: 10),
            PlayIdea(id: 2, title: "Call a friend you have not heard from in a month", category: "Connection", minutes: 15),
            PlayIdea(id: 3, title: "Dance for 3 minutes to your favorite song", category: "Movement", minutes: 3),
            PlayIdea(id: 4, title: "Make a drink you have never tried", category: "Experiment", minutes: 20),
            PlayIdea(id: 5, title: "Look at clouds and find 5 shapes", category: "Observation", minutes: 10),
            PlayIdea(id: 6, title: "Write a letter to your future self", category: "Reflection", minutes: 15),
            PlayIdea(id: 7, title: "Sing a song out loud", category: "Creativity", minutes: 5),
            PlayIdea(id: 8, title: "Rearrange one desk or shelf", category: "Order", minutes: 30),
            PlayIdea(id: 9, title: "Walk without headphones", category: "Mindfulness", minutes: 20),
            PlayIdea(id: 10, title: "Watch an old funny movie", category: "Fun", minutes: 90),
            PlayIdea(id: 11, title: "Play with your pet", category: "Care", minutes: 15),
            PlayIdea(id: 12, title: "Learn 5 words in a new language", category: "Learning", minutes: 10),
            PlayIdea(id: 13, title: "Give yourself a hand massage", category: "Care", minutes: 10),
            PlayIdea(id: 14, title: "Write a short review of a book or movie", category: "Creativity", minutes: 15),
            PlayIdea(id: 15, title: "Lie on the floor and do nothing", category: "Rest", minutes: 5),
            PlayIdea(id: 16, title: "Call your parents for no reason", category: "Connection", minutes: 10),
            PlayIdea(id: 17, title: "Invent a story about a random passerby", category: "Imagination", minutes: 10),
            PlayIdea(id: 18, title: "Do 20 squats", category: "Movement", minutes: 2),
            PlayIdea(id: 19, title: "Sketch your wish map", category: "Planning", minutes: 20),
            PlayIdea(id: 20, title: "Listen to a genre you usually avoid", category: "Experiment", minutes: 15),
            PlayIdea(id: 21, title: "Bake something simple", category: "Creativity", minutes: 40),
            PlayIdea(id: 22, title: "Write 3 gratitudes for today", category: "Reflection", minutes: 5),
            PlayIdea(id: 23, title: "Watch cute cat videos", category: "Fun", minutes: 10),
            PlayIdea(id: 24, title: "Walk barefoot around home", category: "Grounding", minutes: 5),
            PlayIdea(id: 25, title: "Thank a support agent sincerely", category: "Experiment", minutes: 5),
            PlayIdea(id: 26, title: "Assemble a puzzle or Rubik's cube", category: "Focus", minutes: 30),
            PlayIdea(id: 27, title: "Tell a joke to the mirror", category: "Humor", minutes: 2),
            PlayIdea(id: 28, title: "Drink one glass of water slowly", category: "Mindfulness", minutes: 2),
            PlayIdea(id: 29, title: "Find 5 red things at home", category: "Game", minutes: 5),
            PlayIdea(id: 30, title: "Go to bed 30 minutes earlier", category: "Rest", minutes: 30)
        ]
    }
}
