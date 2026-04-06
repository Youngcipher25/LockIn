import SwiftUI

struct MainTabView: View {

    var body: some View {

        TabView {

            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            NavigationStack {
                PrivacyDashboardView()
            }
            .tabItem {
                Label("Privacy", systemImage: "lock.shield")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
