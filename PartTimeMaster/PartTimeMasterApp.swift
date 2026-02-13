import SwiftUI
import SwiftData

@main
struct PartTimeMasterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: WorkLog.self)
    }
}
