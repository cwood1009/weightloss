import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

enum HealthAuthorizationState {
    case unknown
    case unavailable
    case notDetermined
    case authorized
    case denied
}

final class HealthKitManager {
#if canImport(HealthKit)
    private let healthStore = HKHealthStore()

    func currentAuthorizationStatus(completion: @escaping (HealthAuthorizationState) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.unavailable)
            return
        }

        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(.unavailable)
            return
        }

        completion(status(for: stepType))
    }

    func requestAuthorization(completion: @escaping (HealthAuthorizationState) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.unavailable)
            return
        }

        guard
            let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
            let weightType = HKObjectType.quantityType(forIdentifier: .bodyMass)
        else {
            completion(.unavailable)
            return
        }

        let read: Set = [stepType, weightType]
        let write: Set = [weightType]

        healthStore.requestAuthorization(toShare: write, read: read) { [weak self] success, _ in
            guard let self else {
                DispatchQueue.main.async { completion(.denied) }
                return
            }

            DispatchQueue.main.async {
                completion(success ? self.status(for: stepType) : .denied)
            }
        }
    }

    func fetchSteps(for date: Date, completion: @escaping (Int?) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil)
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            completion(nil)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            DispatchQueue.main.async {
                completion(Int(steps))
            }
        }

        healthStore.execute(query)
    }

    func saveWeight(_ pounds: Double, on date: Date, completion: @escaping (Bool) -> Void) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(false)
            return
        }

        let quantity = HKQuantity(unit: HKUnit.pound(), doubleValue: pounds)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)

        healthStore.save(sample) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    private func status(for type: HKObjectType) -> HealthAuthorizationState {
        switch healthStore.authorizationStatus(for: type) {
        case .notDetermined:
            return .notDetermined
        case .sharingAuthorized:
            return .authorized
        case .sharingDenied:
            return .denied
        @unknown default:
            return .unknown
        }
    }
#else
    func currentAuthorizationStatus(completion: @escaping (HealthAuthorizationState) -> Void) {
        completion(.unavailable)
    }

    func requestAuthorization(completion: @escaping (HealthAuthorizationState) -> Void) {
        completion(.unavailable)
    }

    func fetchSteps(for date: Date, completion: @escaping (Int?) -> Void) {
        completion(nil)
    }

    func saveWeight(_ pounds: Double, on date: Date, completion: @escaping (Bool) -> Void) {
        completion(false)
    }
#endif
}
