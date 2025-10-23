import SwiftUI

struct ContentView: View {
    @StateObject private var apiManager = XAPIManager()
    @State private var searchText = ""
    @State private var searchType = SearchType.keyword
    
    enum SearchType: String, CaseIterable {
        case keyword = "Keywords"
        case username = "User"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Rate Limit Display
                HStack {
                    Spacer()
                    Text("Requests left: \(RateLimitTracker().remainingRequests)/1500")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Search Bar
                HStack {
                    TextField(searchType == .keyword ? "Search tweets..." : "Enter username...",
                             text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Search") {
                        performSearch()
                    }
                    .disabled(searchText.isEmpty)
                }
                .padding()
                
                // Search Type Picker
                Picker("Search Type", selection: $searchType) {
                    ForEach(SearchType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Results List
                if apiManager.isLoading {
                    ProgressView("Loading...")
                        .padding()
                    Spacer()
                } else if let error = apiManager.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    Spacer()
                } else if apiManager.tweets.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Search for tweets or users")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    Spacer()
                } else {
                    List(apiManager.tweets) { tweet in
                        TweetRowView(tweet: tweet)
                    }
                }
            }
            .navigationTitle("X Monitor")
        }
    }
    
    private func performSearch() {
        switch searchType {
        case .keyword:
            apiManager.searchTweets(query: searchText)
        case .username:
            // For username search, we'll add this functionality later
            apiManager.errorMessage = "Username search coming soon"
        }
    }
}

#Preview {
    ContentView()
}
