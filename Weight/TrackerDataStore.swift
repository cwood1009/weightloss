import Foundation
import Combine

final class TrackerDataStore: ObservableObject {
    @Published var profiles: [TrackerUserProfile]
    @Published var entries: [Date: [UUID: TrackerDayEntry]]
    @Published var showKidVariants: Bool
    @Published var syncStepsFromHealth: Bool
    @Published var pushWeightToHealth: Bool
    @Published var cloudSyncEnabled: Bool
    @Published var sharedRollupsEnabled: Bool
    @Published var healthAuthorizationState: HealthAuthorizationState

    let mealTemplates: [TrackerMealTemplate]
    let recipes: [TrackerRecipe]

    private let healthManager = HealthKitManager()
    private let calendar = Calendar.current

    init() {
        let chris = TrackerUserProfile(id: UUID(), name: "Chris", targetCalories: 2100, targetWaterOz: Self.suggestedWater(for: 198), targetWeight: 185, startingWeight: 198, isPrimary: true)
        let jill = TrackerUserProfile(id: UUID(), name: "Jill", targetCalories: 1700, targetWaterOz: Self.suggestedWater(for: 155), targetWeight: 145, startingWeight: 155, isPrimary: false)

        self.profiles = [chris, jill]
        self.entries = [:]
        self.showKidVariants = false
        self.syncStepsFromHealth = true
        self.pushWeightToHealth = true
        self.cloudSyncEnabled = false
        self.sharedRollupsEnabled = true
        self.healthAuthorizationState = .unknown

        let oatsRecipe = TrackerRecipe(
            id: UUID(),
            title: "Blueberry Overnight Oats",
            category: "Breakfast",
            ingredients: "Rolled oats, almond milk, chia seeds, maple syrup, blueberries",
            instructions: "Combine ingredients in a jar, chill overnight, top with berries and nuts.",
            notes: "Prep 2 jars at once for Jill's early mornings."
        )

        let tacoRecipe = TrackerRecipe(
            id: UUID(),
            title: "Sheet-Pan Chicken Tacos",
            category: "Dinner",
            ingredients: "Chicken thighs, peppers, onions, taco seasoning, tortillas, salsa",
            instructions: "Season chicken and veggies, roast at 425°F for 20 minutes, serve with warm tortillas.",
            notes: "Kids version uses mild seasoning and shredded cheese."
        )

        let saladRecipe = TrackerRecipe(
            id: UUID(),
            title: "Mediterranean Power Salad",
            category: "Lunch",
            ingredients: "Mixed greens, quinoa, cucumbers, tomatoes, olives, feta, lemon vinaigrette",
            instructions: "Layer greens and grains, add veggies, toss with vinaigrette before serving.",
            notes: "Great with leftover grilled chicken."
        )

        self.recipes = [oatsRecipe, tacoRecipe, saladRecipe]

        let templateSeed: [TrackerMealTemplate] = [
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Mon", mealType: "Breakfast", title: "Protein Oats", description: "Oats + berries + protein powder", isJillVariant: false, isKidVariant: false, recipeId: oatsRecipe.id),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Mon", mealType: "Lunch", title: "Mediterranean Power Salad", description: "Quinoa, greens, olives", isJillVariant: false, isKidVariant: false, recipeId: saladRecipe.id),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Mon", mealType: "Dinner", title: "Sheet-Pan Chicken Tacos", description: "Peppers, onions, salsa", isJillVariant: false, isKidVariant: false, recipeId: tacoRecipe.id),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Tue", mealType: "Breakfast", title: "Greek Yogurt Parfait", description: "Granola + berries", isJillVariant: true, isKidVariant: false, recipeId: oatsRecipe.id),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Tue", mealType: "Lunch", title: "Leftover Tacos", description: "Warm and wrap", isJillVariant: false, isKidVariant: false, recipeId: tacoRecipe.id),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Tue", mealType: "Dinner", title: "Salmon + Roasted Veg", description: "Sheet pan and chill", isJillVariant: false, isKidVariant: false, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Wed", mealType: "Breakfast", title: "Egg + Avocado Toast", description: "Jill swap: cottage cheese toast", isJillVariant: true, isKidVariant: false, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Wed", mealType: "Lunch", title: "Mediterranean Power Salad", description: "Add beans for extra fiber", isJillVariant: false, isKidVariant: false, recipeId: saladRecipe.id),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Wed", mealType: "Dinner", title: "Slow Cooker Chili", description: "Kid bowl with cheese", isJillVariant: false, isKidVariant: true, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Thu", mealType: "Breakfast", title: "Blueberry Overnight Oats", description: "Add peanut butter for Chris", isJillVariant: false, isKidVariant: false, recipeId: oatsRecipe.id),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Thu", mealType: "Lunch", title: "Chicken Wraps", description: "Spinach + hummus", isJillVariant: false, isKidVariant: false, recipeId: tacoRecipe.id),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Thu", mealType: "Dinner", title: "Pork Tenderloin", description: "Serve with green beans", isJillVariant: false, isKidVariant: true, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Fri", mealType: "Breakfast", title: "Protein Smoothie", description: "Spinach + banana", isJillVariant: false, isKidVariant: false, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Fri", mealType: "Lunch", title: "Leftover Pork Bowls", description: "Add rice + veg", isJillVariant: false, isKidVariant: false, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Fri", mealType: "Dinner", title: "Pizza Night", description: "Side salad for Jill", isJillVariant: true, isKidVariant: true, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Sat", mealType: "Breakfast", title: "Egg + Veg Scramble", description: "Salsa + avocado", isJillVariant: false, isKidVariant: false, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Sat", mealType: "Lunch", title: "BBQ Chicken Sandwiches", description: "Slaw + pickles", isJillVariant: false, isKidVariant: true, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Sat", mealType: "Dinner", title: "Date Night", description: "Eat out", isJillVariant: false, isKidVariant: false, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Sun", mealType: "Breakfast", title: "Pancakes + Fruit", description: "Protein pancakes for Chris", isJillVariant: false, isKidVariant: true, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Sun", mealType: "Lunch", title: "Snack Plates", description: "Hummus, veg, crackers", isJillVariant: false, isKidVariant: true, recipeId: nil),
            TrackerMealTemplate(id: UUID(), dayOfWeek: "Sun", mealType: "Dinner", title: "Roast Chicken", description: "Leftovers for salads", isJillVariant: false, isKidVariant: true, recipeId: nil)
        ]

        self.mealTemplates = templateSeed

        healthManager.currentAuthorizationStatus { [weak self] status in
            DispatchQueue.main.async {
                self?.healthAuthorizationState = status
            }
        }
    }

    private static func suggestedWater(for weight: Double) -> Int {
        Int((weight * 0.5).rounded())
    }

    func requestHealthAuthorization(onAuthorized: (() -> Void)? = nil) {
        healthManager.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.healthAuthorizationState = status
                if status == .authorized {
                    onAuthorized?()
                }
            }
        }
    }

    func syncHealthSteps(for user: TrackerUserProfile, on date: Date) {
        guard syncStepsFromHealth, healthAuthorizationState == .authorized else { return }

        healthManager.fetchSteps(for: date) { [weak self] steps in
            guard let self, let steps else { return }

            DispatchQueue.main.async {
                self.updateDayEntry(for: user, on: date) { entry in
                    entry.steps = steps
                }
            }
        }
    }

    func setWeight(_ weight: Double, for user: TrackerUserProfile, on date: Date) {
        updateDayEntry(for: user, on: date) { entry in
            entry.weight = weight
        }

        guard pushWeightToHealth, healthAuthorizationState == .authorized else { return }

        healthManager.saveWeight(weight, on: date) { _ in }
    }

    func setPrimaryProfile(id: UUID) {
        profiles = profiles.map { profile in
            var updated = profile
            updated.isPrimary = profile.id == id
            return updated
        }
    }

    func dayEntry(for user: TrackerUserProfile, on date: Date) -> TrackerDayEntry {
        let normalized = calendar.startOfDay(for: date)
        if let existing = entries[normalized]?[user.id] {
            return existing
        }

        let entry = TrackerDayEntry(
            id: UUID(),
            date: normalized,
            userId: user.id,
            weight: nil,
            didWorkout: false,
            mealsLogged: false,
            steps: 0,
            stepGoal: 9000,
            completedMealIds: [],
            waterOunces: 0,
            notes: nil
        )

        entries[normalized, default: [:]][user.id] = entry
        return entry
    }

    func updateDayEntry(for user: TrackerUserProfile, on date: Date, update: (inout TrackerDayEntry) -> Void) {
        let normalized = calendar.startOfDay(for: date)
        var entry = dayEntry(for: user, on: date)
        update(&entry)
        entries[normalized, default: [:]][user.id] = entry
    }

    func entriesForLastWeek(for user: TrackerUserProfile, endingOn date: Date) -> [TrackerDayEntry] {
        let normalized = calendar.startOfDay(for: date)
        let days = (0..<7).compactMap { offset -> Date? in
            calendar.date(byAdding: .day, value: -offset, to: normalized)
        }

        return days.map { dayEntry(for: user, on: $0) }.sorted { $0.date < $1.date }
    }

    func recipe(for id: UUID?) -> TrackerRecipe? {
        guard let id else { return nil }
        return recipes.first { $0.id == id }
    }
}
