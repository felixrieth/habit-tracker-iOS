import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MonthlyView()
                .tabItem {
                    Label("Monthly", systemImage: "calendar")
                }

            YearlyStatsView()
                .tabItem {
                    Label("Yearly", systemImage: "chart.bar.fill")
                }
        }
    }
}

struct MonthlyView: View {
    @EnvironmentObject private var store: HabitStore
    @State private var selectedMonth = Date()
    @State private var expandedDays: Set<String> = []

    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    TodaySummaryCard(date: Date())

                    monthControls
                    MonthSettingsCard(month: selectedMonth)

                    ForEach(store.daysInMonth(containing: selectedMonth), id: \.self) { day in
                        DayDisclosureCard(
                            date: day,
                            isExpanded: bindingForDay(day)
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Habit Tracker")
        }
    }

    private var monthControls: some View {
        HStack(spacing: 12) {
            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text(monthTitle)
                .font(.headline)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func bindingForDay(_ day: Date) -> Binding<Bool> {
        let key = HabitStore.dayFormatter.string(from: day)
        return Binding(
            get: { expandedDays.contains(key) },
            set: { isExpanded in
                if isExpanded {
                    expandedDays.insert(key)
                } else {
                    expandedDays.remove(key)
                }
            }
        )
    }
}

struct TodaySummaryCard: View {
    @EnvironmentObject private var store: HabitStore
    let date: Date

    var body: some View {
        let count = store.metCount(for: date)

        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline) {
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.title2.weight(.bold))

                Spacer()

                Text("\(count)/8")
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(count == 8 ? Color.green.opacity(0.16) : Color.orange.opacity(0.16))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct MonthSettingsCard: View {
    @EnvironmentObject private var store: HabitStore
    let month: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Goals")
                .font(.headline)

            LabeledContent("Study") {
                TextField("1.5", value: studyGoal, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Protein") {
                TextField("150", value: proteinGoal, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Bedtime") {
                TextField("23:59", text: bedtimeGoal)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var studyGoal: Binding<Double> {
        Binding(
            get: { store.settings(for: month).studyGoalHours },
            set: { value in store.updateSettings(for: month) { $0.studyGoalHours = value } }
        )
    }

    private var proteinGoal: Binding<Int> {
        Binding(
            get: { store.settings(for: month).proteinGoalGrams },
            set: { value in store.updateSettings(for: month) { $0.proteinGoalGrams = value } }
        )
    }

    private var bedtimeGoal: Binding<String> {
        Binding(
            get: { store.settings(for: month).bedtimeGoal },
            set: { value in store.updateSettings(for: month) { $0.bedtimeGoal = normalizedTime(value) } }
        )
    }
}

struct DayDisclosureCard: View {
    @EnvironmentObject private var store: HabitStore
    let date: Date
    @Binding var isExpanded: Bool

    var body: some View {
        let settings = store.settings(for: date)
        let metCount = store.metCount(for: date)

        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 10) {
                ForEach(HabitGoal.allCases) { goal in
                    GoalInputRow(date: date, goal: goal)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: notes)
                        .frame(minHeight: 96)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.top, 12)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .font(.headline)
                    Text(settings.bedtimeGoal.isEmpty ? "No bedtime goal" : "Goal bedtime \(settings.bedtimeGoal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(metCount)/8 goals met")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(metCount == 8 ? Color.green.opacity(0.16) : Color.orange.opacity(0.16))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var notes: Binding<String> {
        Binding(
            get: { store.record(for: date).notes },
            set: { value in store.updateRecord(for: date) { $0.notes = value } }
        )
    }
}

struct GoalInputRow: View {
    @EnvironmentObject private var store: HabitStore
    let date: Date
    let goal: HabitGoal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: goal.icon)
                .frame(width: 26)
                .foregroundStyle(isMet ? .green : .secondary)

            Text(goal.rawValue)
                .font(.body.weight(.medium))

            Spacer()

            input
        }
        .padding(12)
        .background(isMet ? Color.green.opacity(0.10) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var input: some View {
        switch goal {
        case .study:
            TextField("0", value: studyHours, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 88)
        case .protein:
            TextField("0", value: proteinGrams, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 88)
        case .bedtime:
            TextField("23:30", text: bedtime)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.never)
                .frame(width: 88)
        default:
            Toggle("", isOn: toggleBinding)
                .labelsHidden()
        }
    }

    private var isMet: Bool {
        store.record(for: date).isMet(goal, settings: store.settings(for: date))
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { store.record(for: date).toggles[goal.rawValue] == true },
            set: { value in store.updateRecord(for: date) { $0.toggles[goal.rawValue] = value } }
        )
    }

    private var studyHours: Binding<Double> {
        Binding(
            get: { store.record(for: date).studyHours },
            set: { value in store.updateRecord(for: date) { $0.studyHours = value } }
        )
    }

    private var proteinGrams: Binding<Int> {
        Binding(
            get: { store.record(for: date).proteinGrams },
            set: { value in store.updateRecord(for: date) { $0.proteinGrams = value } }
        )
    }

    private var bedtime: Binding<String> {
        Binding(
            get: { store.record(for: date).bedtime },
            set: { value in store.updateRecord(for: date) { $0.bedtime = normalizedTime(value) } }
        )
    }
}

struct YearlyStatsView: View {
    @EnvironmentObject private var store: HabitStore
    @State private var year = Calendar.current.component(.year, from: Date())

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Stepper("Year: \(year)", value: $year, in: 2020...2035)

                    let completion = store.yearCompletion(for: year)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Year Completion")
                            .font(.headline)
                        ProgressView(value: completion)
                        Text(completion.formatted(.percent.precision(.fractionLength(0))))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Months") {
                    ForEach(1...12, id: \.self) { month in
                        if let date = DateComponents(calendar: Calendar.current, year: year, month: month, day: 1).date {
                            HStack {
                                Text(date.formatted(.dateTime.month(.wide)))
                                Spacer()
                                Text(store.monthCompletion(for: date).formatted(.percent.precision(.fractionLength(0))))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Yearly Stats")
        }
    }
}

private func normalizedTime(_ value: String) -> String {
    let digits = value.filter(\.isNumber).prefix(4)
    guard !digits.isEmpty else { return "" }

    let padded: String
    if digits.count <= 2 {
        padded = String(digits).leftPadding(toLength: 2, withPad: "0") + "00"
    } else {
        padded = String(digits).leftPadding(toLength: 4, withPad: "0")
    }

    let hours = min(Int(padded.prefix(2)) ?? 0, 23)
    let minutes = min(Int(padded.suffix(2)) ?? 0, 59)
    return String(format: "%02d:%02d", hours, minutes)
}

private extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let paddingCount = max(0, toLength - count)
        return String(repeating: String(character), count: paddingCount) + self
    }
}

#Preview {
    ContentView()
        .environmentObject(HabitStore())
}
