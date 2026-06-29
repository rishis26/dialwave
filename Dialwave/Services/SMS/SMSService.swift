import Foundation
import Combine

@MainActor
final class SMSService: SMSServiceProtocol, ObservableObject {
    
    // MARK: - Dependencies
    
    private let connectionManager: ConnectionManager
    private let smsRepository: SMSRepository
    private let notificationService: NotificationServiceProtocol
    
    // MARK: - Init
    
    init(connectionManager: ConnectionManager,
         smsRepository: SMSRepository,
         notificationService: NotificationServiceProtocol) {
        self.connectionManager = connectionManager
        self.smsRepository = smsRepository
        self.notificationService = notificationService
    }
    
    // MARK: - Message Handling
    
    func handleMessage(_ message: Message) {
        guard message.type == .smsReceived else { return }
        
        if let event = message.decode(as: SMSReceivedEvent.self) {
            handleSMSReceived(event)
        }
    }
    
    private func handleSMSReceived(_ event: SMSReceivedEvent) {
        AppLogger.info("Received SMS from: \(event.message.phoneNumber)", category: .sms)
        
        // Save to local database
        smsRepository.upsert(event.message)
        
        // Show system notification
        let senderName = event.message.contactName ?? event.message.phoneNumber.formatPhoneNumber()
        notificationService.showSMSNotification(
            senderName: senderName,
            body: event.message.body,
            threadId: event.message.threadId
        )
    }
    
    // MARK: - Commands
    
    func sendSMS(to number: String, body: String, threadId: String?) {
        AppLogger.info("Sending SMS to \(number)", category: .sms)
        
        let command = SMSCommand(recipientNumber: number, body: body, threadId: threadId)
        let message = Message(type: .smsSend, payload: command.toData())
        
        connectionManager.sendMessage(message)
        
        // Optimistically insert into local DB
        let sentMessage = SMSMessage(
            id: UUID().uuidString,
            threadId: threadId ?? UUID().uuidString,
            contactName: nil, // Will be resolved by UI layer later
            phoneNumber: number,
            body: body,
            timestamp: Date(),
            isIncoming: false,
            isRead: true
        )
        smsRepository.upsert(sentMessage)
    }
    
    // MARK: - Queries
    
    func fetchThreads() -> [SMSThread] {
        smsRepository.fetchThreads()
    }
    
    func fetchMessages(forThread threadId: String) -> [SMSMessage] {
        smsRepository.fetchMessages(forThread: threadId)
    }
    
    func markThreadAsRead(_ threadId: String) {
        smsRepository.markThreadAsRead(threadId)
    }
}
