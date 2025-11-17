import Foundation

struct TrackerUserProfile: Identifiable, Hashable {
    let id: UUID
    var name: String
    var targetCalories: Int
    var targetWaterOz: Int
    var targetWeight: Double
    var startingWeight: Double
    var isPrimary: Bool
}

struct TrackerDayEntry: Identifiable {
    let id: UUID
    var date: Date
    var userId: UUID
    var weight: Double?
    var didWorkout: Bool
    var mealsLogged: Bool
    var steps: Int
    var stepGoal: Int
    var completedMealIds: Set<UUID>
    var waterOunces: Double
    var notes: String?

    var stepGoalHit: Bool { steps >= stepGoal }
}

struct TrackerMealTemplate: Identifiable {
    let id: UUID
    var dayOfWeek: String
    var mealType: String
    var title: String
    var description: String
    var isJillVariant: Bool
    var isKidVariant: Bool
    var recipeId: UUID?
}

struct TrackerRecipe: Identifiable {
    let id: UUID
    var title: String
    var category: String
    var ingredients: String
    var instructions: String
    var notes: String
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

struct WeekRollup {
    var workouts: Int
    var mealsLogged: Int
    var averageWater: Double
    var weightChange: Double?

    init(entries: [TrackerDayEntry], targetWater: Int) {
        workouts = entries.filter(\.didWorkout).count
        mealsLogged = entries.filter(\.mealsLogged).count
        averageWater = entries.map(\.waterOunces).reduce(0, +) / Double(entries.count)

        let weights = entries.compactMap(\.weight)
        if let first = weights.first, let last = weights.last {
            weightChange = last - first
        }
    }
}

extension Date {
    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }
}
