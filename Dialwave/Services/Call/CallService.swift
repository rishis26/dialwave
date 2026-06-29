import Foundation
import Combine
import AVFoundation

@MainActor
final class CallService: CallServiceProtocol, ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var activeCallState = CallPopupState()
    
    // MARK: - Dependencies
    
    private let connectionManager: ConnectionManager
    private let callLogRepository: CallLogRepository
    private let notificationService: NotificationServiceProtocol
    
    // MARK: - Internal State
    
    private var activeCallId: String?
    private var callDurationTimer: Timer?
    
    // MARK: - Init
    
    init(connectionManager: ConnectionManager,
         callLogRepository: CallLogRepository,
         notificationService: NotificationServiceProtocol) {
        self.connectionManager = connectionManager
        self.callLogRepository = callLogRepository
        self.notificationService = notificationService
    }
    
    // MARK: - Message Handling
    
    func handleMessage(_ message: Message) {
        switch message.type {
        case .callIncoming:
            if let event = message.decode(as: IncomingCallEvent.self) {
                handleIncomingCall(event)
            }
        case .callHangup:
            handleHangup()
        case .callLogSync:
            // TODO: Implement call log sync payload decoding and batch insert
            break
        default:
            break
        }
    }
    
    private func handleIncomingCall(_ event: IncomingCallEvent) {
        AppLogger.info("Incoming call from: \(event.callerNumber)", category: .calls)
        activeCallId = event.callId
        
        activeCallState = CallPopupState(
            isVisible: true,
            callerName: event.callerName,
            callerNumber: event.callerNumber,
            isAnswered: false,
            callDuration: 0
        )
        
        notificationService.showIncomingCall(
            callerName: event.callerName ?? event.callerNumber.formatPhoneNumber(),
            onAnswer: { [weak self] in self?.answerCall() },
            onDecline: { [weak self] in self?.rejectCall() }
        )
    }
    
    private func handleHangup() {
        AppLogger.info("Call hung up", category: .calls)
        endActiveCallUI()
        connectionManager.stopAudioStream()
    }
    
    // MARK: - Call Control
    
    func dial(number: String, contactName: String?) {
        AppLogger.info("Dialing number: \(number)", category: .calls)
        
        let command = DialCommand(phoneNumber: number, contactName: contactName)
        let message = Message(type: .callDial, payload: command.toData())
        connectionManager.sendMessage(message)
        
        // Show outgoing call UI
        activeCallId = UUID().uuidString
        activeCallState = CallPopupState(
            isVisible: true,
            callerName: contactName,
            callerNumber: number,
            isAnswered: true, // Optimistically show as answered/in-progress
            callDuration: 0
        )
        
        startDurationTimer()
        connectionManager.startAudioStream()
    }
    
    func answerCall() {
        guard let callId = activeCallId else { return }
        AppLogger.info("Answering call", category: .calls)
        
        let command = CallControlCommand(callId: callId, action: .answer)
        let message = Message(type: .callAnswer, payload: command.toData())
        connectionManager.sendMessage(message)
        
        activeCallState.isAnswered = true
        startDurationTimer()
        connectionManager.startAudioStream()
    }
    
    func rejectCall() {
        guard let callId = activeCallId else { return }
        AppLogger.info("Rejecting call", category: .calls)
        
        let command = CallControlCommand(callId: callId, action: .reject)
        let message = Message(type: .callReject, payload: command.toData())
        connectionManager.sendMessage(message)
        
        endActiveCallUI()
    }
    
    func hangupCall() {
        guard let callId = activeCallId else { return }
        AppLogger.info("Hanging up call", category: .calls)
        
        let command = CallControlCommand(callId: callId, action: .hangup)
        let message = Message(type: .callHangup, payload: command.toData())
        connectionManager.sendMessage(message)
        
        endActiveCallUI()
        connectionManager.stopAudioStream()
    }
    
    // MARK: - Private Helpers
    
    private func startDurationTimer() {
        callDurationTimer?.invalidate()
        activeCallState.callDuration = 0
        
        callDurationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.activeCallState.callDuration += 1
            }
        }
    }
    
    private func endActiveCallUI() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
        activeCallId = nil
        activeCallState.isVisible = false
    }
    
    // MARK: - History
    
    func fetchCallHistory() -> [CallRecord] {
        callLogRepository.fetchAll()
    }
    
    func fetchUnreadMissedCalls() -> [CallRecord] {
        callLogRepository.fetchUnread()
    }
    
    func markAllMissedCallsAsRead() {
        callLogRepository.markAllAsRead()
    }
}
