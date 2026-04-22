import Foundation

enum HabitGoal: String, CaseIterable, Codable, Identifiable {
    case sports = "Sports"
    case study = "Study"
    case supplements = "Supplements"
    case protein = "Protein"
    case friends = "Friends"
    case x = "X"
    case read = "Read"
    case bedtime = "Bedtime"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sports:
            return "figure.strengthtraining.traditional"
        case .study:
            return "graduationcap.fill"
        case .supplements:
            return "pills.fill"
        case .protein:
            return "takeoutbag.and.cup.and.straw.fill"
        case .friends:
            return "person.2.fill"
        case .x:
            return "xmark"
        case .read:
            return "book.fill"
        case .bedtime:
            return "moon.zzz.fill"
        }
    }
}

struct DayRecord: Codable, Equatable {
    var toggles: [String: Bool] = [:]
    var studyHours: Double = 0
    var proteinGrams: Int = 0
    var bedtime: String = ""
    var notes: String = ""

    func isMet(_ goal: HabitGoal, settings: MonthSettings) -> Bool {
        switch goal {
        case .study:
            return studyHours >= settings.studyGoalHours
        case .protein:
            return proteinGrams >= settings.proteinGoalGrams
        case .bedtime:
            return !bedtime.isEmpty && bedtime <= settings.bedtimeGoal
        default:
            return toggles[goal.rawValue] == true
        }
    }

    func metCount(settings: MonthSettings) -> Int {
        HabitGoal.allCases.filter { isMet($0, settings: settings) }.count
    }
}

struct MonthSettings: Codable, Equatable {
    var studyGoalHours: Double = 1.5
    var proteinGoalGrams: Int = 150
    var bedtimeGoal: String = "23:59"
}

struct HabitData: Codable, Equatable {
    var records: [String: DayRecord] = [:]
    var monthSettings: [String: MonthSettings] = [:]
}

final class HabitStore: ObservableObject {
    @Published private(set) var data: HabitData = HabitData()

    private let storageKey = "habit-tracker-ios-data-v1"
    private let calendar = Calendar(identifier: .gregorian)

    init() {
        load()
    }

    func record(for date: Date) -> DayRecord {
        data.records[dayKey(date)] ?? DayRecord()
    }

    func settings(for date: Date) -> MonthSettings {
        data.monthSettings[monthKey(date)] ?? MonthSettings()
    }

    func daysInMonth(containing date: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: date),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
    }

    func updateRecord(for date: Date, _ update: (inout DayRecord) -> Void) {
        var next = record(for: date)
        update(&next)
        data.records[dayKey(date)] = next
        save()
    }

    func updateSettings(for date: Date, _ update: (inout MonthSettings) -> Void) {
        var next = settings(for: date)
        update(&next)
        data.monthSettings[monthKey(date)] = next
        save()
    }

    func metCount(for date: Date) -> Int {
        record(for: date).metCount(settings: settings(for: date))
    }

    func monthCompletion(for date: Date) -> Double {
        let days = daysInMonth(containing: date)
        guard !days.isEmpty else { return 0 }
        let met = days.reduce(0) { $0 + metCount(for: $1) }
        return Double(met) / Double(days.count * HabitGoal.allCases.count)
    }

    func yearCompletion(for year: Int) -> Double {
        let months = (1...12).compactMap { month -> Date? in
            DateComponents(calendar: calendar, year: year, month: month, day: 1).date
        }
        let days = months.flatMap { daysInMonth(containing: $0) }
        guard !days.isEmpty else { return 0 }
        let met = days.reduce(0) { $0 + metCount(for: $1) }
        return Double(met) / Double(days.count * HabitGoal.allCases.count)
    }

    private func load() {
        guard let raw = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(HabitData.self, from: raw) else {
            data = HabitData()
            return
        }
        data = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: storageKey)
    }

    private func dayKey(_ date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private func monthKey(_ date: Date) -> String {
        Self.monthFormatter.string(from: date)
    }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()
}
