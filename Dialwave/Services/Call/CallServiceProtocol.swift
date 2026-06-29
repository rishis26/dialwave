import Foundation

/// Defines operations for managing phone calls and the call history.
@MainActor
protocol CallServiceProtocol: AnyObject {
    
    /// Publisher for the current state of the incoming call popup.
    var activeCallState: CallPopupState { get }
    
    /// Handle an incoming protocol message related to calls.
    func handleMessage(_ message: Message)
    
    /// Initiates an outgoing call to the specified number.
    func dial(number: String, contactName: String?)
    
    /// Answers the currently ringing incoming call.
    func answerCall()
    
    /// Rejects the currently ringing incoming call.
    func rejectCall()
    
    /// Hangs up the active call.
    func hangupCall()
    
    /// Fetches the recent call history.
    func fetchCallHistory() -> [CallRecord]
    
    /// Fetches all missed calls that haven't been reviewed.
    func fetchUnreadMissedCalls() -> [CallRecord]
    
    /// Marks all missed calls as read.
    func markAllMissedCallsAsRead()
}
