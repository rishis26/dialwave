import Foundation

/// Defines operations for sending SMS messages and fetching conversations.
@MainActor
protocol SMSServiceProtocol: AnyObject {
    
    /// Handle an incoming protocol message related to SMS.
    func handleMessage(_ message: Message)
    
    /// Sends an SMS message to a recipient.
    func sendSMS(to number: String, body: String, threadId: String?)
    
    /// Fetches all message threads (conversations).
    func fetchThreads() -> [SMSThread]
    
    /// Fetches all messages within a specific thread.
    func fetchMessages(forThread threadId: String) -> [SMSMessage]
    
    /// Marks an entire thread as read.
    func markThreadAsRead(_ threadId: String)
}
