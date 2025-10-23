import Foundation
import SwiftUI
import Combine

class XAPIManager: ObservableObject {
    @Published var tweets: [Tweet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime = Date()
    @Published var remainingRequests: Int = 100
    
    private let bearerToken: String
    private let baseURL = "https://api.twitter.com/2"
    private let rateLimitTracker = RateLimitTracker()
    private var timer: AnyCancellable?
    
    // Golden Gai search variations
    private let searchVariations = [
        "\"golden gai\"",      // Exact phrase
        "goldengai",           // One word
        "ゴールデン街",         // Japanese katakana
        "新宿 ゴールデン",      // Shinjuku Golden
        "#goldengai",          // Hashtag
        "\"ゴールデン街\""      // Japanese exact phrase
    ]
    
    init() {
        self.bearerToken = Config.bearerToken
        self.remainingRequests = rateLimitTracker.remainingRequests
    }
    
    // Combine all variations into one search query
    func searchGoldenGai(maxResults: Int = 20) {
        // Combine variations with OR operator
        let query = searchVariations.joined(separator: " OR ")
        searchTweets(query: query, maxResults: maxResults)
    }
    
    // Start automatic monitoring
    func startAutoMonitoring(intervalMinutes: Int = 30) {
        // Initial search
        searchGoldenGai()
        
        // Set up timer for periodic updates
        timer = Timer.publish(every: TimeInterval(intervalMinutes * 60), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.searchGoldenGai()
            }
    }
    
    // Stop monitoring
    func stopAutoMonitoring() {
        timer?.cancel()
        timer = nil
    }
    
    private func searchTweets(query: String, maxResults: Int = 20) {
        // Check rate limit
        guard rateLimitTracker.canMakeRequest() else {
            self.errorMessage = "Monthly limit reached (\(rateLimitTracker.monthlyLimit) requests)"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            self.errorMessage = "Invalid query"
            self.isLoading = false
            return
        }
        
        // Request more fields for better information
        let urlString = "\(baseURL)/tweets/search/recent?query=\(encodedQuery)&max_results=\(maxResults)&tweet.fields=created_at,author_id,public_metrics,lang&expansions=author_id&user.fields=name,username,verified"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.lastUpdateTime = Date()
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Status Code: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 401 {
                        self?.errorMessage = "Authentication failed"
                        return
                    } else if httpResponse.statusCode == 429 {
                        self?.errorMessage = "Rate limit exceeded"
                        return
                    } else if httpResponse.statusCode != 200 {
                        self?.errorMessage = "Error: HTTP \(httpResponse.statusCode)"
                        return
                    }
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(TwitterResponse.self, from: data)
                    self?.tweets = response.data ?? []
                    self?.rateLimitTracker.incrementCount()
                    self?.remainingRequests = self?.rateLimitTracker.remainingRequests ?? 0
                    
                    // Sort by creation date (newest first)
                    self?.tweets.sort { tweet1, tweet2 in
                        guard let date1 = tweet1.created_at,
                              let date2 = tweet2.created_at else { return false }
                        return date1 > date2
                    }
                    
                    print("Found \(self?.tweets.count ?? 0) tweets about Golden Gai")
                    
                } catch {
                    self?.errorMessage = "Decoding error: \(error)"
                }
            }
        }.resume()
    }
}
