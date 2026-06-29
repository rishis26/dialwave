import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, NotificationServiceProtocol {
    
    // MARK: - Properties
    
    private let center = UNUserNotificationCenter.current()
    
    /// Stored closures for call actions.
    private var pendingCallAnswerAction: (() -> Void)?
    private var pendingCallDeclineAction: (() -> Void)?
    
    // MARK: - Init
    
    override init() {
        super.init()
        center.delegate = self
        requestAuthorization()
    }
    
    // MARK: - API
    
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                AppLogger.error("Failed to request notification auth: \(error.localizedDescription)", category: .general)
            } else {
                AppLogger.info("Notification auth granted: \(granted)", category: .general)
            }
        }
        
        // Register custom interactive categories
        let answerAction = UNNotificationAction(identifier: "ANSWER_ACTION", title: "Answer", options: [.foreground])
        let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION", title: "Decline", options: [.destructive])
        
        let callCategory = UNNotificationCategory(
            identifier: "INCOMING_CALL",
            actions: [answerAction, declineAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        center.setNotificationCategories([callCategory])
    }
    
    func showIncomingCall(callerName: String, onAnswer: @escaping () -> Void, onDecline: @escaping () -> Void) {
        pendingCallAnswerAction = onAnswer
        pendingCallDeclineAction = onDecline
        
        let content = UNMutableNotificationContent()
        content.title = "Incoming Call"
        content.subtitle = callerName
        content.body = "DialWave"
        content.categoryIdentifier = "INCOMING_CALL"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "ringtone.aiff")) // Requires custom sound file
        
        let request = UNNotificationRequest(identifier: "CALL_\(UUID().uuidString)", content: content, trigger: nil)
        
        center.add(request) { error in
            if let error {
                AppLogger.error("Failed to show call notification: \(error.localizedDescription)", category: .general)
            }
        }
    }
    
    func showSMSNotification(senderName: String, body: String, threadId: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Message: \(senderName)"
        content.body = body
        content.sound = .default
        content.userInfo = ["threadId": threadId]
        
        let request = UNNotificationRequest(identifier: "SMS_\(UUID().uuidString)", content: content, trigger: nil)
        
        center.add(request) { error in
            if let error {
                AppLogger.error("Failed to show SMS notification: \(error.localizedDescription)", category: .general)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    // Ensures notifications show even when app is active
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handles button clicks on notifications
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        
        Task { @MainActor in
            let category = response.notification.request.content.categoryIdentifier
            
            if category == "INCOMING_CALL" {
                switch response.actionIdentifier {
                case "ANSWER_ACTION":
                    pendingCallAnswerAction?()
                case "DECLINE_ACTION", UNNotificationDismissActionIdentifier:
                    pendingCallDeclineAction?()
                default:
                    break
                }
                
                // Clear pending actions
                pendingCallAnswerAction = nil
                pendingCallDeclineAction = nil
            } else {
                // Handle SMS click (e.g., open specific thread UI via NotificationCenter broadcast)
                if let threadId = response.notification.request.content.userInfo["threadId"] as? String {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSMSThread"), object: threadId)
                }
            }
            
            completionHandler()
        }
    }
}
