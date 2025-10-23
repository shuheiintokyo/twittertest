import Foundation

struct Tweet: Codable, Identifiable {
    let id: String
    let text: String
    let created_at: String?
    let author_id: String?
    let public_metrics: Metrics?
    let lang: String?
    
    struct Metrics: Codable {
        let retweet_count: Int?
        let reply_count: Int?
        let like_count: Int?
        let quote_count: Int?
    }
}

struct TwitterResponse: Codable {
    let data: [Tweet]?
    let includes: Includes?
    let meta: Meta?
    
    struct Meta: Codable {
        let result_count: Int
        let next_token: String?
    }
    
    struct Includes: Codable {
        let users: [User]?
    }
    
    struct User: Codable {
        let id: String
        let name: String
        let username: String
        let verified: Bool?
    }
}
