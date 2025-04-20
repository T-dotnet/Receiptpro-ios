import SwiftUI
import Supabase
// Stubbed feature flags
let isInsightsEnabled: Bool = true
let isActionsEnabled: Bool = true

struct ContentView: View {
    @StateObject private var supabase = SupabaseManager.shared

    var body: some View {
        if !supabase.isAuthenticated {
            LoginView()
        } else {
            TabView {
                UploadView()
                    .tabItem {
                        Image(systemName: "square.and.arrow.up")
                        Text("Upload")
                    }
                ViewView()
                    .tabItem {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("View")
                    }
                if isInsightsEnabled {
                    InsightsView()
                        .tabItem {
                            Image(systemName: "chart.bar.xaxis")
                            Text("Insights")
                        }
                }
                if isActionsEnabled {
                    ActionsView()
                        .tabItem {
                            Image(systemName: "bolt.circle")
                            Text("Actions")
                        }
                }
            }
            .accentColor(.blue)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}