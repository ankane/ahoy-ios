import Foundation

@propertyWrapper
struct ExpiringPersisted<T: Codable> {
    let key: String
    let newValue: () -> T
    private(set) var expiryPeriod: TimeInterval? = nil
    private(set) var defaults: UserDefaults = Current.defaults
    let jsonEncoder: JSONEncoder
    let jsonDecoder: JSONDecoder

    var wrappedValue: T {
        guard
            let data = defaults.value(forKey: key) as? Data,
            let container = try? jsonDecoder.decode(DatedStorageContainer<T>.self, from: data),
            case let now = Current.date(),
            (expiryPeriod.map(container.storageDate.advanced(by:)) ?? now) > now
        else {
            let container: DatedStorageContainer = .init(
                storageDate: Current.date(),
                value: newValue()
            )
            defaults.set(try! jsonEncoder.encode(container), forKey: key)

            return container.value
        }
        return container.value
    }

    private struct DatedStorageContainer<T: Codable>: Codable {
        let storageDate: Date
        let value: T
    }
}
