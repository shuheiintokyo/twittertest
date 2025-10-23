import Foundation
import SwiftUI

class XAPIManager: ObservableObject {
    @Published var tweets: [Tweet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let bearerToken = Config.bearerToken
    private let baseURL = "https://api.twitter.com/2"
    private let rateLimitTracker = RateLimitTracker()
    
    init() {
        // Load bearer token from Config
        self.bearerToken = Config.bearerToken
    }
    
    func searchTweets(query: String) {
        // Check rate limit first
        guard rateLimitTracker.canMakeRequest() else {
            self.errorMessage = "Rate limit reached. Remaining this month: 0"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            self.errorMessage = "Invalid query"
            self.isLoading = false
            return
        }
        
        let urlString = "\(baseURL)/tweets/search/recent?query=\(encodedQuery)&max_results=10&tweet.fields=created_at"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(TwitterResponse.self, from: data)
                    self?.tweets = response.data ?? []
                    self?.rateLimitTracker.incrementCount()
                } catch {
                    self?.errorMessage = "Decoding error: \(error.localizedDescription)"
                    print("JSON Decoding error: \(error)")
                }
            }
        }.resume()
    }
}
