import SwiftUI

struct TweetRowView: View {
    let tweet: Tweet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tweet text with highlighting
            Text(highlightedText)
                .font(.body)
                .lineLimit(nil)
            
            // Metadata
            HStack {
                if let createdAt = tweet.created_at {
                    Label(formatDate(createdAt), systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Show if it's in Japanese
                if tweet.text.contains("ゴールデン") || tweet.text.contains("街") {
                    Text("🇯🇵")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var highlightedText: AttributedString {
        var text = AttributedString(tweet.text)
        
        // Highlight Golden Gai mentions
        let searchTerms = ["golden gai", "goldengai", "ゴールデン街", "ゴールデン"]
        
        for term in searchTerms {
            if let range = text.range(of: term, options: [.caseInsensitive]) {
                text[range].backgroundColor = .yellow.opacity(0.3)
                text[range].font = .body.bold()
            }
        }
        
        return text
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = RelativeDateTimeFormatter()
            displayFormatter.unitsStyle = .abbreviated
            return displayFormatter.localizedString(for: date, relativeTo: Date())
        }
        return dateString
    }
}
