import Foundation
import Combine

/// Controls registration of the app as a user login item by writing a LaunchAgent.
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled: Bool

    private let identifier: String
    private let agentURL: URL
    private let fileManager = FileManager.default

    init() {
        let bundleID = Bundle.main.bundleIdentifier ?? "app.miniww.widgetwall"
        self.identifier = bundleID + ".launchagent"
        self.agentURL = LaunchAtLoginManager.launchAgentURL(for: identifier)
        self.isEnabled = fileManager.fileExists(atPath: agentURL.path)
    }

    func setEnabled(_ newValue: Bool) {
        guard newValue != isEnabled else { return }

        do {
            if newValue {
                try installAgentIfNeeded()
            } else {
                try removeAgentIfNeeded()
            }
            isEnabled = newValue
        } catch {
            NSLog("Failed to update launch agent: \(error.localizedDescription)")
        }
    }

    // MARK: - Launch Agent handling

    private func installAgentIfNeeded() throws {
        guard let executablePath = Bundle.main.executableURL?.path else {
            throw LaunchAgentError.missingExecutable
        }

        try ensureLaunchAgentsDirectoryExists()

        let plist: [String: Any] = [
            "Label": identifier,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist,
                                                      format: .xml,
                                                      options: 0)
        try data.write(to: agentURL, options: .atomic)
        loadAgent()
    }

    private func removeAgentIfNeeded() throws {
        guard fileManager.fileExists(atPath: agentURL.path) else { return }
        unloadAgent()
        try fileManager.removeItem(at: agentURL)
    }

    private func ensureLaunchAgentsDirectoryExists() throws {
        let directory = agentURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
    }

    private func loadAgent() {
        runLaunchctl(arguments: ["bootstrap", "gui/\(getuid())", agentURL.path])
    }

    private func unloadAgent() {
        runLaunchctl(arguments: ["bootout", "gui/\(getuid())", agentURL.path])
    }

    private func runLaunchctl(arguments: [String]) {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = arguments
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            NSLog("launchctl %@ failed: %@", arguments.joined(separator: " "), error.localizedDescription)
        }
    }

    private static func launchAgentURL(for identifier: String) -> URL {
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return libraryURL
            .appendingPathComponent("LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(identifier).plist")
    }

    enum LaunchAgentError: Error {
        case missingExecutable
    }
}
