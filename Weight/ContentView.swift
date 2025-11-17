import SwiftUI

struct ContentView: View {
    @StateObject private var store = TrackerDataStore()
    @State private var selectedDate = Date()
    @State private var selectedUserIndex = 0

    private var selectedUser: TrackerUserProfile {
        store.profiles[selectedUserIndex]
    }

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(selectedDate: $selectedDate, selectedUserIndex: $selectedUserIndex)
                    .environmentObject(store)
            }
            .tabItem {
                Label("Today", systemImage: "sun.max")
            }

            NavigationStack {
                WeekView(selectedUserIndex: $selectedUserIndex)
                    .environmentObject(store)
            }
            .tabItem {
                Label("Week", systemImage: "calendar")
            }

            NavigationStack {
                MealPlanView(selectedUserIndex: $selectedUserIndex)
                    .environmentObject(store)
            }
            .tabItem {
                Label("Meal Plan", systemImage: "fork.knife")
            }

            NavigationStack {
                SettingsView(selectedUserIndex: $selectedUserIndex)
                    .environmentObject(store)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

struct TodayView: View {
    @EnvironmentObject var store: TrackerDataStore
    @Binding var selectedDate: Date
    @Binding var selectedUserIndex: Int

    var selectedUser: TrackerUserProfile { store.profiles[selectedUserIndex] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    Spacer()
                    Picker("Profile", selection: $selectedUserIndex) {
                        ForEach(Array(store.profiles.enumerated()), id: \.offset) { index, profile in
                            Text(profile.name).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

                let entry = store.dayEntry(for: selectedUser, on: selectedDate)

                WeightCard(entry: entry, user: selectedUser) { newWeight in
                    store.setWeight(newWeight, for: selectedUser, on: selectedDate)
                }

                ComplianceToggles(entry: entry) { newValue in
                    store.updateDayEntry(for: selectedUser, on: selectedDate) { entry in
                        entry.didWorkout = newValue
                    }
                }

                StepsProgressCard(
                    entry: entry,
                    authorizationState: store.healthAuthorizationState,
                    syncingFromHealth: store.syncStepsFromHealth,
                    onRequestPermission: {
                        store.requestHealthAuthorization {
                            store.syncHealthSteps(for: selectedUser, on: selectedDate)
                        }
                    },
                    onSync: {
                        store.syncHealthSteps(for: selectedUser, on: selectedDate)
                    }
                )

                HydrationTracker(entry: entry, target: selectedUser.targetWaterOz) { servings in
                    store.updateDayEntry(for: selectedUser, on: selectedDate) { entry in
                        entry.waterOunces = Double(servings) * 12
                    }
                }

                TodayMealsCard(
                    dayOfWeek: selectedDate.shortWeekday,
                    mealsLogged: entry.mealsLogged,
                    completedMeals: entry.completedMealIds,
                    showKidVariants: store.showKidVariants,
                    templates: store.mealTemplates,
                    onMealsLoggedChange: { isOn in
                        store.updateDayEntry(for: selectedUser, on: selectedDate) { entry in
                            entry.mealsLogged = isOn
                        }
                    },
                    onMealToggle: { template, isCompleted in
                        store.updateDayEntry(for: selectedUser, on: selectedDate) { entry in
                            if isCompleted {
                                entry.completedMealIds.insert(template.id)
                            } else {
                                entry.completedMealIds.remove(template.id)
                            }

                            let todaysMeals = store.mealTemplates.filter { $0.dayOfWeek == selectedDate.shortWeekday && (store.showKidVariants || !$0.isKidVariant) }
                            entry.mealsLogged = todaysMeals.allSatisfy { entry.completedMealIds.contains($0.id) }
                        }
                    },
                    recipeProvider: { template in
                        store.recipe(for: template.recipeId)
                    }
                )
            }
            .padding()
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: { adjustDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Button(action: { adjustDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
        }
    }

    private func adjustDate(by days: Int) {
        if let nextDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = nextDate
        }
    }
}

struct WeightCard: View {
    var entry: TrackerDayEntry
    var user: TrackerUserProfile
    var onUpdate: (Double?) -> Void
    @State private var weightText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Weight", systemImage: "scalemass")
                Spacer()
                Text("Target: \(user.targetWeight, specifier: "%.1f") lb")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            TextField("Enter weight", text: Binding(
                get: { weightText.isEmpty ? formattedWeight : weightText },
                set: { newValue in
                    weightText = newValue
                    onUpdate(Double(newValue))
                }
            ))
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)

            if let currentWeight = entry.weight {
                let delta = currentWeight - user.startingWeight
                let symbol = delta >= 0 ? "+" : ""
                VStack(alignment: .leading, spacing: 6) {
                    Text("Change from start: \(symbol)\(delta, specifier: "%.1f") lb")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    let totalGoal = user.startingWeight - user.targetWeight
                    let progress = totalGoal != 0 ? (user.startingWeight - currentWeight) / totalGoal : 0
                    ProgressView(value: max(0, min(progress, 1))) {
                        Text("Progress to target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("You've lost \(max(0, user.startingWeight - currentWeight), specifier: "%.1f") lb so far")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            weightText = formattedWeight
        }
    }

    private var formattedWeight: String {
        if let weight = entry.weight {
            return String(format: "%.1f", weight)
        }
        return ""
    }
}

struct ComplianceToggles: View {
    var entry: TrackerDayEntry
    var onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habits")
                .font(.headline)

            Toggle(isOn: Binding(
                get: { entry.didWorkout },
                set: { onToggle($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Workout", systemImage: entry.didWorkout ? "dumbbell.fill" : "dumbbell")
                    Text("Today's plan: \(TodayWorkoutPlan.plan(for: entry.date.shortWeekday))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(TodayWorkoutPlan.detail(for: entry.date.shortWeekday))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StepsProgressCard: View {
    var entry: TrackerDayEntry
    var authorizationState: HealthAuthorizationState
    var syncingFromHealth: Bool
    var onRequestPermission: () -> Void
    var onSync: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Steps", systemImage: "figure.walk")
                Spacer()
                if syncingFromHealth, authorizationState == .authorized {
                    Label("Health on", systemImage: "waveform.path.ecg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            switch authorizationState {
            case .authorized:
                Text("\(entry.steps) / \(entry.stepGoal) suggested")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: Double(entry.steps), total: Double(entry.stepGoal))

                Button(action: onSync) {
                    Label("Refresh from Health", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            case .denied:
                Text("Health access denied. Turn on permissions in Settings to pull steps.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: onRequestPermission) {
                    Label("Request Health Access", systemImage: "heart")
                }
                .buttonStyle(.bordered)
            case .unavailable:
                Text("Health data isn't available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .unknown, .notDetermined:
                Text("Connect to Health to pull today's step count.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: onRequestPermission) {
                    Label("Request Health Access", systemImage: "heart")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

enum TodayWorkoutPlan {
    static func plan(for weekday: String) -> String {
        switch weekday {
        case "Mon":
            return "Upper body strength"
        case "Tue":
            return "Zone 2 walk + core"
        case "Wed":
            return "Lower body strength"
        case "Thu":
            return "Intervals or peloton"
        case "Fri":
            return "Full-body lift"
        case "Sat":
            return "Family walk or hike"
        case "Sun":
            return "Mobility + stretch"
        default:
            return "Movement day"
        }
    }

    static func detail(for weekday: String) -> String {
        switch weekday {
        case "Mon":
            return "Bench + rows, finish with 10-minute core."
        case "Tue":
            return "45-minute walk; 3x plank, dead bug, side plank."
        case "Wed":
            return "Squats, hinges, and split squats with light sled pushes."
        case "Thu":
            return "10 x 1-min pushes on the bike with 1-min recoveries."
        case "Fri":
            return "Compound lifts (press, hinge, squat) and band pull-aparts."
        case "Sat":
            return "Family cardio — stroller walk or easy hike."
        case "Sun":
            return "20-minute mobility flow: hips, hamstrings, T-spine."
        default:
            return "Stay loose with a short walk and stretching."
        }
    }
}

struct HydrationTracker: View {
    var entry: TrackerDayEntry
    var target: Int
    var onUpdate: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Hydration", systemImage: "drop.fill")
                Spacer()
                Text("Target: \(target) oz")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            let servings = Int(entry.waterOunces / 12)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(0..<8) { index in
                    let filled = index < servings
                    Button {
                        onUpdate(index + 1)
                    } label: {
                        VStack {
                            Image(systemName: filled ? "drop.fill" : "drop")
                                .foregroundStyle(filled ? .blue : .secondary)
                            Text("\((index + 1) * 12) oz")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            ProgressView(value: min(Double(servings) * 12, Double(target)), total: Double(target)) {
                Text("\(Int(entry.waterOunces)) / \(target) oz")
                    .font(.caption)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TodayMealsCard: View {
    var dayOfWeek: String
    var mealsLogged: Bool
    var completedMeals: Set<UUID>
    var showKidVariants: Bool
    var templates: [TrackerMealTemplate]
    var onMealsLoggedChange: (Bool) -> Void
    var onMealToggle: (TrackerMealTemplate, Bool) -> Void
    var recipeProvider: (TrackerMealTemplate) -> TrackerRecipe?
    @State private var selectedTemplate: TrackerMealTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's planned meals")
                    .font(.headline)
                Spacer()
                Toggle("Logged", isOn: Binding(
                    get: { mealsLogged },
                    set: { onMealsLoggedChange($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                Label("Meals logged", systemImage: mealsLogged ? "checkmark.seal.fill" : "checkmark.seal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(filteredTemplates) { template in
                HStack(alignment: .center, spacing: 8) {
                    Button {
                        let isCompleted = completedMeals.contains(template.id)
                        onMealToggle(template, !isCompleted)
                    } label: {
                        Image(systemName: completedMeals.contains(template.id) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(completedMeals.contains(template.id) ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.mealType)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(template.title)
                            .font(.body)
                        Text(template.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if template.isJillVariant {
                        Label("Jill", systemImage: "heart")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.pink)
                            .help("Jill's variant")
                    }
                    if template.isKidVariant && showKidVariants {
                        Label("Kids", systemImage: "figure.and.child.holdinghands")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.teal)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedTemplate = template
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(item: $selectedTemplate) { template in
            MealDetailView(template: template, recipe: recipeProvider(template))
        }
    }

    private var filteredTemplates: [TrackerMealTemplate] {
        templates.filter { $0.dayOfWeek == dayOfWeek && (showKidVariants || !$0.isKidVariant) }
    }
}

struct WeekView: View {
    @EnvironmentObject var store: TrackerDataStore
    @Binding var selectedUserIndex: Int

    var selectedUser: TrackerUserProfile { store.profiles[selectedUserIndex] }

    var body: some View {
        let entries = store.entriesForLastWeek(for: selectedUser, endingOn: Date())
        let rollup = WeekRollup(entries: entries, targetWater: selectedUser.targetWaterOz)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Profile", selection: $selectedUserIndex) {
                    ForEach(Array(store.profiles.enumerated()), id: \.offset) { index, profile in
                        Text(profile.name).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(entry.date.shortWeekday)
                                .font(.headline)
                            HStack {
                                Label("Workout", systemImage: entry.didWorkout ? "checkmark.circle.fill" : "circle")
                                Spacer()
                                Label("Meals", systemImage: entry.mealsLogged ? "checkmark.circle.fill" : "circle")
                            }
                            .font(.caption)
                            HStack {
                                Label("Steps", systemImage: entry.stepGoalHit ? "checkmark.circle.fill" : "circle")
                                Spacer()
                                Label("Water", systemImage: entry.waterOunces >= Double(selectedUser.targetWaterOz) ? "drop.fill" : "drop")
                            }
                            .font(.caption)
                            if let weight = entry.weight {
                                Text("Weight: \(weight, specifier: "%.1f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                WeekRollupView(rollup: rollup)

                if store.sharedRollupsEnabled {
                    SharedRollupList(selectedUserId: selectedUser.id)
                        .environmentObject(store)
                }
            }
            .padding()
        }
        .navigationTitle("Week")
    }
}

struct WeekRollup {
    var workouts: Int
    var mealsLogged: Int
    var averageWater: Double
    var weightChange: Double?

    init(entries: [TrackerDayEntry], targetWater: Int) {
        workouts = entries.filter { $0.didWorkout }.count
        mealsLogged = entries.filter { $0.mealsLogged }.count
        let totalWater = entries.reduce(0) { $0 + $1.waterOunces }
        averageWater = entries.isEmpty ? 0 : totalWater / Double(entries.count)
        let weights = entries.compactMap { $0.weight }
        if let first = weights.first, let last = weights.last {
            weightChange = last - first
        } else {
            weightChange = nil
        }
    }
}

struct WeekRollupView: View {
    var rollup: WeekRollup

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Week roll-up")
                .font(.headline)

            HStack {
                StatPill(title: "Workouts", value: "\(rollup.workouts)/7", icon: "dumbbell.fill", color: .orange)
                StatPill(title: "Meals Logged", value: "\(rollup.mealsLogged)/7", icon: "checklist", color: .green)
            }

            HStack {
                StatPill(title: "Avg Water", value: String(format: "%.0f oz", rollup.averageWater), icon: "drop.fill", color: .blue)
                StatPill(title: "Weight Trend", value: weightTrendText, icon: "scalemass.fill", color: .purple)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var weightTrendText: String {
        guard let change = rollup.weightChange else { return "--" }
        let symbol = change >= 0 ? "+" : ""
        return String(format: "%@%.1f lb", symbol, change)
    }
}

struct SharedRollupList: View {
    @EnvironmentObject var store: TrackerDataStore
    var selectedUserId: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shared roll-ups")
                .font(.headline)
                .padding(.top, 4)

            Text("See each profile's week when cloud sync is enabled or you're both connected to Health.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(store.profiles) { profile in
                let entries = store.entriesForLastWeek(for: profile, endingOn: Date())
                let rollup = WeekRollup(entries: entries, targetWater: profile.targetWaterOz)
                SharedRollupRow(profile: profile, rollup: rollup, isCurrentUser: profile.id == selectedUserId)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SharedRollupRow: View {
    var profile: TrackerUserProfile
    var rollup: WeekRollup
    var isCurrentUser: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(profile.name, systemImage: profile.isPrimary ? "person.fill.checkmark" : "person")
                    .font(.subheadline)
                    .foregroundStyle(isCurrentUser ? .primary : .secondary)
                Spacer()
                if isCurrentUser {
                    Text("Viewing")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 8) {
                StatPill(title: "Workouts", value: "\(rollup.workouts)", icon: "dumbbell.fill", color: .orange)
                StatPill(title: "Meals", value: "\(rollup.mealsLogged)", icon: "checklist", color: .green)
            }

            HStack(spacing: 8) {
                StatPill(title: "Avg Water", value: String(format: "%.0f oz", rollup.averageWater), icon: "drop.fill", color: .blue)
                StatPill(title: "Weight", value: weightTrendText, icon: "scalemass.fill", color: .purple)
            }
        }
    }

    private var weightTrendText: String {
        guard let change = rollup.weightChange else { return "--" }
        let symbol = change >= 0 ? "+" : ""
        return String(format: "%@%.1f lb", symbol, change)
    }
}

struct StatPill: View {
    var title: String
    var value: String
    var icon: String
    var color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct MealPlanView: View {
    @EnvironmentObject var store: TrackerDataStore
    @Binding var selectedUserIndex: Int
    @State private var selectedTemplate: TrackerMealTemplate?

    var body: some View {
        let grouped = Dictionary(grouping: store.mealTemplates) { $0.dayOfWeek }
        let sortedDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        List {
            Picker("Profile", selection: $selectedUserIndex) {
                ForEach(Array(store.profiles.enumerated()), id: \.offset) { index, profile in
                    Text(profile.name).tag(index)
                }
            }
            .pickerStyle(.segmented)

            ForEach(sortedDays, id: \.self) { day in
                if let meals = grouped[day] {
                    Section(dayFullName(day)) {
                        ForEach(meals.filter { store.showKidVariants || !$0.isKidVariant }) { template in
                            MealRow(template: template)
                                .onTapGesture { selectedTemplate = template }
                        }
                    }
                }
            }
        }
        .navigationTitle("Meal Plan")
        .sheet(item: $selectedTemplate) { template in
            MealDetailView(template: template, recipe: store.recipe(for: template.recipeId))
        }
    }

    private func dayFullName(_ short: String) -> String {
        let mapping: [String: String] = ["Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday", "Thu": "Thursday", "Fri": "Friday", "Sat": "Saturday", "Sun": "Sunday"]
        return mapping[short, default: short]
    }
}

struct MealRow: View {
    var template: TrackerMealTemplate

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(template.mealType)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(template.title)
                    .font(.body)
                if !template.description.isEmpty {
                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if template.isJillVariant {
                Label("Jill", systemImage: "heart")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.pink)
            }
            if template.isKidVariant {
                Label("Kids", systemImage: "figure.and.child.holdinghands")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.teal)
            }
        }
    }
}

struct MealDetailView: View {
    var template: TrackerMealTemplate
    var recipe: TrackerRecipe?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(template.title)
                        .font(.title2)
                    Text(template.description)
                        .foregroundStyle(.secondary)
                    Divider()

                    if let recipe {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Ingredients", systemImage: "list.bullet")
                                .font(.headline)
                            Text(recipe.ingredients)
                            Label("Instructions", systemImage: "text.book.closed")
                                .font(.headline)
                            Text(recipe.instructions)
                            if !recipe.notes.isEmpty {
                                Label("Notes", systemImage: "note.text")
                                    .font(.headline)
                                Text(recipe.notes)
                            }
                        }
                    } else {
                        Text("Recipe details coming soon.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle(dayLabel)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    private var dayLabel: String {
        "\(template.dayOfWeek) \(template.mealType)"
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: TrackerDataStore
    @Binding var selectedUserIndex: Int

    var body: some View {
        Form {
            Section("Profiles") {
                Picker("Profile", selection: $selectedUserIndex) {
                    ForEach(Array(store.profiles.enumerated()), id: \.offset) { index, profile in
                        Text(profile.name).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Primary profile", selection: Binding(
                    get: { store.profiles.first(where: { $0.isPrimary })?.id ?? store.profiles.first?.id ?? UUID() },
                    set: { newValue in store.setPrimaryProfile(id: newValue) }
                )) {
                    ForEach(store.profiles) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }
                .pickerStyle(.menu)

                ProfileEditor(profile: $store.profiles[selectedUserIndex])
            }

            Section("Options") {
                Toggle("Show kid variants", isOn: $store.showKidVariants)
            }

            Section("Integrations") {
                Toggle("Sync steps from Health", isOn: $store.syncStepsFromHealth)
                Toggle("Write weight to Health", isOn: $store.pushWeightToHealth)
                Toggle("Enable iCloud sync", isOn: $store.cloudSyncEnabled)
                Toggle("Share roll-ups between profiles", isOn: $store.sharedRollupsEnabled)

                Button {
                    store.requestHealthAuthorization()
                } label: {
                    Label("Request Health Access", systemImage: "heart")
                }
                .disabled(store.healthAuthorizationState == .authorized)
                .buttonStyle(.bordered)
                .padding(.top, 4)
            }
        }
        .navigationTitle("Settings")
    }
}

struct ProfileEditor: View {
    @Binding var profile: TrackerUserProfile
    @FocusState private var focusedField: Field?

    enum Field { case calories, startingWeight, targetWeight }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Targets & baselines")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LabeledContent("Starting weight") {
                TextField("Starting weight", value: $profile.startingWeight, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .startingWeight)
            }

            LabeledContent("Target weight") {
                TextField("Target weight", value: $profile.targetWeight, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .targetWeight)
            }

            LabeledContent("Target calories") {
                TextField("Target calories", value: $profile.targetCalories, format: .number)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .calories)
            }

            LabeledContent("Water target") {
                Text("\(profile.targetWaterOz) oz (auto: 1/2 body weight)")
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .onChange(of: profile.startingWeight) { newValue in
            profile.targetWaterOz = Int((newValue * 0.5).rounded())
        }
    }
}

#Preview {
    ContentView()
}
