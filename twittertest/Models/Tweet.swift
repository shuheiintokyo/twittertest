import Foundation

struct Tweet: Codable, Identifiable {
    let id: String
    let text: String
    let created_at: String?
    
    struct Includes: Codable {
        let users: [User]?
    }
    
    struct User: Codable {
        let id: String
        let name: String
        let username: String
    }
}

struct TwitterResponse: Codable {
    let data: [Tweet]?
    let includes: Tweet.Includes?
    let meta: Meta?
    
    struct Meta: Codable {
        let result_count: Int
    }
}
