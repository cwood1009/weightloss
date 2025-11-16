//
//  ContentView.swift
//  Weight
//
//  Created by Chris Wood on 11/16/25.
//

import SwiftUI

struct UserProfile: Identifiable, Hashable {
    let id: UUID
    var name: String
    var targetCalories: Int
    var targetWaterOz: Int
    var targetWeight: Double
    var startingWeight: Double
    var isPrimary: Bool
}

struct DayEntry: Identifiable {
    let id: UUID
    var date: Date
    var userId: UUID
    var weight: Double?
    var didWorkout: Bool
    var mealsLogged: Bool
    var stepGoalHit: Bool
    var waterOunces: Double
    var notes: String?
}

struct MealTemplate: Identifiable {
    let id: UUID
    var dayOfWeek: String
    var mealType: String
    var title: String
    var description: String
    var isJillVariant: Bool
    var isKidVariant: Bool
    var recipeId: UUID?
}

struct Recipe: Identifiable {
    let id: UUID
    var title: String
    var category: String
    var ingredients: String
    var instructions: String
    var notes: String
}

final class DataStore: ObservableObject {
    @Published var profiles: [UserProfile]
    @Published var entries: [Date: [UUID: DayEntry]]
    @Published var showKidVariants: Bool
    let mealTemplates: [MealTemplate]
    let recipes: [Recipe]

    private let calendar = Calendar.current

    init() {
        let chris = UserProfile(id: UUID(), name: "Chris", targetCalories: 2100, targetWaterOz: 96, targetWeight: 185, startingWeight: 198, isPrimary: true)
        let jill = UserProfile(id: UUID(), name: "Jill", targetCalories: 1700, targetWaterOz: 90, targetWeight: 145, startingWeight: 155, isPrimary: false)

        self.profiles = [chris, jill]
        self.entries = [:]
        self.showKidVariants = false

        let oatsRecipe = Recipe(
            id: UUID(),
            title: "Blueberry Overnight Oats",
            category: "Breakfast",
            ingredients: "Rolled oats, almond milk, chia seeds, maple syrup, blueberries",
            instructions: "Combine ingredients in a jar, chill overnight, top with berries and nuts.",
            notes: "Prep 2 jars at once for Jill's early mornings."
        )

        let tacoRecipe = Recipe(
            id: UUID(),
            title: "Sheet-Pan Chicken Tacos",
            category: "Dinner",
            ingredients: "Chicken thighs, peppers, onions, taco seasoning, tortillas, salsa",
            instructions: "Season chicken and veggies, roast at 425°F for 20 minutes, serve with warm tortillas.",
            notes: "Kids version uses mild seasoning and shredded cheese."
        )

        let saladRecipe = Recipe(
            id: UUID(),
            title: "Mediterranean Power Salad",
            category: "Lunch",
            ingredients: "Mixed greens, quinoa, cucumbers, tomatoes, olives, feta, lemon vinaigrette",
            instructions: "Layer greens and grains, add veggies, toss with vinaigrette before serving.",
            notes: "Great with leftover grilled chicken."
        )

        self.recipes = [oatsRecipe, tacoRecipe, saladRecipe]

        let templateSeed: [MealTemplate] = [
            MealTemplate(id: UUID(), dayOfWeek: "Mon", mealType: "Breakfast", title: "Protein Oats", description: "Oats + berries + protein powder", isJillVariant: false, isKidVariant: false, recipeId: oatsRecipe.id),
            MealTemplate(id: UUID(), dayOfWeek: "Mon", mealType: "Lunch", title: "Mediterranean Power Salad", description: "Quinoa, greens, olives", isJillVariant: false, isKidVariant: false, recipeId: saladRecipe.id),
            MealTemplate(id: UUID(), dayOfWeek: "Mon", mealType: "Dinner", title: "Sheet-Pan Chicken Tacos", description: "Peppers, onions, salsa", isJillVariant: false, isKidVariant: false, recipeId: tacoRecipe.id),
            MealTemplate(id: UUID(), dayOfWeek: "Tue", mealType: "Breakfast", title: "Greek Yogurt Parfait", description: "Granola + berries", isJillVariant: true, isKidVariant: false, recipeId: oatsRecipe.id),
            MealTemplate(id: UUID(), dayOfWeek: "Tue", mealType: "Lunch", title: "Leftover Tacos", description: "Warm and wrap", isJillVariant: false, isKidVariant: false, recipeId: tacoRecipe.id),
            MealTemplate(id: UUID(), dayOfWeek: "Tue", mealType: "Dinner", title: "Salmon + Roasted Veg", description: "Sheet pan and chill", isJillVariant: false, isKidVariant: false, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Wed", mealType: "Breakfast", title: "Egg + Avocado Toast", description: "Jill swap: cottage cheese toast", isJillVariant: true, isKidVariant: false, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Wed", mealType: "Lunch", title: "Mediterranean Power Salad", description: "Add beans for extra fiber", isJillVariant: false, isKidVariant: false, recipeId: saladRecipe.id),
            MealTemplate(id: UUID(), dayOfWeek: "Wed", mealType: "Dinner", title: "Slow Cooker Chili", description: "Kid bowl with cheese", isJillVariant: false, isKidVariant: true, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Thu", mealType: "Breakfast", title: "Blueberry Overnight Oats", description: "Add peanut butter for Chris", isJillVariant: false, isKidVariant: false, recipeId: oatsRecipe.id),
            MealTemplate(id: UUID(), dayOfWeek: "Thu", mealType: "Lunch", title: "Chicken Wraps", description: "Spinach + hummus", isJillVariant: false, isKidVariant: false, recipeId: tacoRecipe.id),
            MealTemplate(id: UUID(), dayOfWeek: "Thu", mealType: "Dinner", title: "Pork Tenderloin", description: "Serve with green beans", isJillVariant: false, isKidVariant: true, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Fri", mealType: "Breakfast", title: "Protein Smoothie", description: "Spinach + banana", isJillVariant: false, isKidVariant: false, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Fri", mealType: "Lunch", title: "Leftover Pork Bowls", description: "Add rice + veg", isJillVariant: false, isKidVariant: false, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Fri", mealType: "Dinner", title: "Pizza Night", description: "Side salad for Jill", isJillVariant: true, isKidVariant: true, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Sat", mealType: "Breakfast", title: "Egg + Veg Scramble", description: "Salsa + avocado", isJillVariant: false, isKidVariant: false, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Sat", mealType: "Lunch", title: "BBQ Chicken Sandwiches", description: "Slaw + pickles", isJillVariant: false, isKidVariant: true, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Sat", mealType: "Dinner", title: "Date Night", description: "Eat out", isJillVariant: false, isKidVariant: false, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Sun", mealType: "Breakfast", title: "Pancakes + Fruit", description: "Protein pancakes for Chris", isJillVariant: false, isKidVariant: true, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Sun", mealType: "Lunch", title: "Snack Plates", description: "Hummus, veg, crackers", isJillVariant: false, isKidVariant: true, recipeId: nil),
            MealTemplate(id: UUID(), dayOfWeek: "Sun", mealType: "Dinner", title: "Roast Chicken", description: "Leftovers for salads", isJillVariant: false, isKidVariant: true, recipeId: nil)
        ]

        self.mealTemplates = templateSeed
    }

    func dayEntry(for user: UserProfile, on date: Date) -> DayEntry {
        let normalized = calendar.startOfDay(for: date)
        if let existing = entries[normalized]?[user.id] {
            return existing
        }

        let entry = DayEntry(
            id: UUID(),
            date: normalized,
            userId: user.id,
            weight: nil,
            didWorkout: false,
            mealsLogged: false,
            stepGoalHit: false,
            waterOunces: 0,
            notes: nil
        )

        entries[normalized, default: [:]][user.id] = entry
        return entry
    }

    func updateDayEntry(for user: UserProfile, on date: Date, update: (inout DayEntry) -> Void) {
        let normalized = calendar.startOfDay(for: date)
        var entry = dayEntry(for: user, on: date)
        update(&entry)
        entries[normalized, default: [:]][user.id] = entry
    }

    func entriesForLastWeek(for user: UserProfile, endingOn date: Date) -> [DayEntry] {
        let normalized = calendar.startOfDay(for: date)
        let days = (0..<7).compactMap { offset -> Date? in
            calendar.date(byAdding: .day, value: -offset, to: normalized)
        }

        return days.map { dayEntry(for: user, on: $0) }.sorted { $0.date < $1.date }
    }

    func recipe(for id: UUID?) -> Recipe? {
        guard let id else { return nil }
        return recipes.first { $0.id == id }
    }
}

struct ContentView: View {
    @StateObject private var store = DataStore()
    @State private var selectedDate = Date()
    @State private var selectedUserIndex = 0

    private var selectedUser: UserProfile {
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
    @EnvironmentObject var store: DataStore
    @Binding var selectedDate: Date
    @Binding var selectedUserIndex: Int

    var selectedUser: UserProfile { store.profiles[selectedUserIndex] }

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
                    store.updateDayEntry(for: selectedUser, on: selectedDate) { entry in
                        entry.weight = newWeight
                    }
                }

                ComplianceToggles(entry: entry) { keyPath, value in
                    store.updateDayEntry(for: selectedUser, on: selectedDate) { entry in
                        entry[keyPath: keyPath] = value
                    }
                }

                HydrationTracker(entry: entry, target: selectedUser.targetWaterOz) { servings in
                    store.updateDayEntry(for: selectedUser, on: selectedDate) { entry in
                        entry.waterOunces = Double(servings) * 12
                    }
                }

                TodayMealsCard(dayOfWeek: selectedDate.shortWeekday, showKidVariants: store.showKidVariants, templates: store.mealTemplates) { template in
                    store.recipe(for: template.recipeId)
                }
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
    var entry: DayEntry
    var user: UserProfile
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
                Text("Change from start: \(symbol)\(delta, specifier: "%.1f") lb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
    var entry: DayEntry
    var onToggle: (WritableKeyPath<DayEntry, Bool>, Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habits")
                .font(.headline)

            Toggle(isOn: Binding(
                get: { entry.didWorkout },
                set: { onToggle(\.didWorkout, $0) }
            )) {
                Label("Workout", systemImage: entry.didWorkout ? "dumbbell.fill" : "dumbbell")
            }

            Toggle(isOn: Binding(
                get: { entry.mealsLogged },
                set: { onToggle(\.mealsLogged, $0) }
            )) {
                Label("Meals logged", systemImage: entry.mealsLogged ? "checkmark.seal.fill" : "checkmark.seal")
            }

            Toggle(isOn: Binding(
                get: { entry.stepGoalHit },
                set: { onToggle(\.stepGoalHit, $0) }
            )) {
                Label("Steps goal", systemImage: entry.stepGoalHit ? "figure.walk.circle.fill" : "figure.walk.circle")
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HydrationTracker: View {
    var entry: DayEntry
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
    var showKidVariants: Bool
    var templates: [MealTemplate]
    var recipeProvider: (MealTemplate) -> Recipe?
    @State private var selectedTemplate: MealTemplate?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's planned meals")
                .font(.headline)

            ForEach(filteredTemplates) { template in
                Button {
                    selectedTemplate = template
                } label: {
                    HStack(alignment: .top, spacing: 8) {
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

    private var filteredTemplates: [MealTemplate] {
        templates.filter { $0.dayOfWeek == dayOfWeek && (showKidVariants || !$0.isKidVariant) }
    }
}

struct WeekView: View {
    @EnvironmentObject var store: DataStore
    @Binding var selectedUserIndex: Int

    var selectedUser: UserProfile { store.profiles[selectedUserIndex] }

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

    init(entries: [DayEntry], targetWater: Int) {
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
        return "\(symbol)\(change, specifier: "%.1f") lb"
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
    @EnvironmentObject var store: DataStore
    @Binding var selectedUserIndex: Int
    @State private var selectedTemplate: MealTemplate?

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

            ForEach(sortedDays, id: \ .self) { day in
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
    var template: MealTemplate

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
    var template: MealTemplate
    var recipe: Recipe?

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
    @EnvironmentObject var store: DataStore
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

                ProfileEditor(profile: $store.profiles[selectedUserIndex])
            }

            Section("Options") {
                Toggle("Show kid variants", isOn: $store.showKidVariants)
            }
        }
        .navigationTitle("Settings")
    }
}

struct ProfileEditor: View {
    @Binding var profile: UserProfile
    @FocusState private var focusedField: Field?

    enum Field { case calories, water, targetWeight }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Target calories", value: $profile.targetCalories, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .calories)
            TextField("Target water (oz)", value: $profile.targetWaterOz, formatter: NumberFormatter())
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .water)
            TextField("Target weight", value: $profile.targetWeight, format: .number)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .targetWeight)
        }
    }
}

private extension Date {
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
}

#Preview {
    ContentView()
}
