import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("대시보드", systemImage: "house") {
                DashboardView()
            }

            Tab("근무기록", systemImage: "list.clipboard") {
                WorkLogListView()
            }

            Tab("설정", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WorkLog.self, inMemory: true)
}
