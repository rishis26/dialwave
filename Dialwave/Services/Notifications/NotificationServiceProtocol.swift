import Foundation
import UserNotifications

/// Manages native macOS system notifications.
@MainActor
protocol NotificationServiceProtocol: AnyObject {
    
    /// Requests permission from the user to display notifications.
    func requestAuthorization()
    
    /// Displays a rich notification for an incoming phone call.
    /// - Parameters:
    ///   - callerName: The display name or phone number of the caller.
    ///   - onAnswer: Closure executed if the user clicks "Answer".
    ///   - onDecline: Closure executed if the user clicks "Decline".
    func showIncomingCall(callerName: String, onAnswer: @escaping () -> Void, onDecline: @escaping () -> Void)
    
    /// Displays a notification for a newly received SMS message.
    /// - Parameters:
    ///   - senderName: The display name or phone number of the sender.
    ///   - body: The text content of the message.
    ///   - threadId: The thread ID to open when the notification is clicked.
    func showSMSNotification(senderName: String, body: String, threadId: String)
}
