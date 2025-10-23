import SwiftUI

struct ContentView: View {
    @StateObject private var apiManager = XAPIManager()
    @State private var autoRefresh = false
    @State private var refreshInterval = 30 // minutes
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status Bar
                StatusBarView(
                    lastUpdate: apiManager.lastUpdateTime,
                    remainingRequests: apiManager.remainingRequests,
                    autoRefresh: $autoRefresh,
                    onToggleAuto: toggleAutoRefresh
                )
                
                // Main Content
                if apiManager.isLoading {
                    Spacer()
                    ProgressView("Searching for Golden Gai tweets...")
                        .padding()
                    Spacer()
                } else if let error = apiManager.errorMessage {
                    ErrorView(message: error) {
                        apiManager.searchGoldenGai()
                    }
                } else if apiManager.tweets.isEmpty {
                    EmptyStateView {
                        apiManager.searchGoldenGai()
                    }
                } else {
                    TweetListView(tweets: apiManager.tweets)
                }
            }
            .navigationTitle("🏮 Golden Gai Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        apiManager.searchGoldenGai()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(apiManager.isLoading)
                }
            }
        }
        .onAppear {
            // Automatically search when app opens
            apiManager.searchGoldenGai()
        }
    }
    
    private func toggleAutoRefresh() {
        autoRefresh.toggle()
        if autoRefresh {
            apiManager.startAutoMonitoring(intervalMinutes: refreshInterval)
        } else {
            apiManager.stopAutoMonitoring()
        }
    }
}

// Status bar component
struct StatusBarView: View {
    let lastUpdate: Date
    let remainingRequests: Int
    @Binding var autoRefresh: Bool
    let onToggleAuto: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Updated: \(timeAgoString(from: lastUpdate))", systemImage: "clock")
                    .font(.caption)
                Spacer()
                Label("\(remainingRequests)/100", systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundColor(remainingRequests < 20 ? .red : .secondary)
            }
            
            Toggle("Auto-refresh every 30 min", isOn: $autoRefresh)
                .font(.caption)
                .onChange(of: autoRefresh) { _ in
                    onToggleAuto()
                }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            return "\(Int(interval/60))m ago"
        } else {
            return "\(Int(interval/3600))h ago"
        }
    }
}

// Tweet list component
struct TweetListView: View {
    let tweets: [Tweet]
    
    var body: some View {
        List {
            Section(header: Text("Latest Golden Gai Mentions (\(tweets.count))")) {
                ForEach(tweets) { tweet in
                    TweetRowView(tweet: tweet)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// Empty state
struct EmptyStateView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No Golden Gai tweets found")
                .font(.headline)
            Text("We'll search for:\n• \"golden gai\"\n• goldengai\n• ゴールデン街\n• #goldengai")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Search Now") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        Spacer()
    }
}

// Error view
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        Spacer()
    }
}

#Preview {
    ContentView()
}
}
