import SwiftUI

class RateLimitTracker {
    @AppStorage("tweetReadCount") private var readCount = 0
    @AppStorage("lastResetDate") private var lastResetDateString = ""
    
    let monthlyLimit = 1500
    
    private var lastResetDate: Date {
        get {
            if let date = ISO8601DateFormatter().date(from: lastResetDateString) {
                return date
            }
            return Date()
        }
        set {
            lastResetDateString = ISO8601DateFormatter().string(from: newValue)
        }
    }
    
    func canMakeRequest() -> Bool {
        checkMonthReset()
        return readCount < monthlyLimit
    }
    
    func incrementCount() {
        readCount += 1
    }
    
    private func checkMonthReset() {
        let calendar = Calendar.current
        if !calendar.isDate(Date(), equalTo: lastResetDate, toGranularity: .month) {
            readCount = 0
            lastResetDate = Date()
        }
    }
    
    var remainingRequests: Int {
        checkMonthReset()
        return max(0, monthlyLimit - readCount)
    }
}
