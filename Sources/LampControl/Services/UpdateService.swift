import Foundation
import Sparkle

@MainActor
final class UpdateService: NSObject, ObservableObject {
    @Published private(set) var lastCheckedAt: Date?
    @Published var automaticChecksEnabled: Bool {
        didSet {
            updaterController.updater.automaticallyChecksForUpdates = automaticChecksEnabled
        }
    }
    @Published var automaticDownloadsEnabled: Bool {
        didSet {
            updaterController.updater.automaticallyDownloadsUpdates = automaticDownloadsEnabled
        }
    }

    private let updaterController: SPUStandardUpdaterController

    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    var feedURL: String {
        Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String ?? ""
    }

    override init() {
        let controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = controller
        self.automaticChecksEnabled = controller.updater.automaticallyChecksForUpdates
        self.automaticDownloadsEnabled = controller.updater.automaticallyDownloadsUpdates
        super.init()
    }

    func start() {
        updaterController.startUpdater()
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
        lastCheckedAt = Date()
    }

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }
}
