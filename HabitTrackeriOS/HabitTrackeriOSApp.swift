import SwiftUI

@main
struct HabitTrackeriOSApp: App {
    @StateObject private var store = HabitStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
