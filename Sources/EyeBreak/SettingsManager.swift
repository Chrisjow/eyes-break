import Foundation
import Combine

final class SettingsManager: ObservableObject {

    // Break interval in minutes (how often breaks occur)
    @Published var breakInterval: Double {
        didSet { UserDefaults.standard.set(breakInterval, forKey: Keys.breakInterval) }
    }

    // Break duration in seconds
    @Published var breakDuration: Double {
        didSet { UserDefaults.standard.set(breakDuration, forKey: Keys.breakDuration) }
    }

    private enum Keys {
        static let breakInterval = "eyebreak.breakInterval"
        static let breakDuration = "eyebreak.breakDuration"
    }

    init() {
        let savedInterval = UserDefaults.standard.double(forKey: Keys.breakInterval)
        let savedDuration = UserDefaults.standard.double(forKey: Keys.breakDuration)
        self.breakInterval = savedInterval > 0 ? savedInterval : 20.0
        self.breakDuration = savedDuration > 0 ? savedDuration : 20.0
    }
}
