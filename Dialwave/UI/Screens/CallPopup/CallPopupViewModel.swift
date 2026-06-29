import SwiftUI
import Combine

/// Drives the incoming/active call popup UI.
@MainActor
final class CallPopupViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let callService: CallServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    
    @Published private(set) var state = CallPopupState()
    
    /// The display name to show on the UI.
    var displayName: String {
        if let name = state.callerName, !name.isEmpty {
            return name
        }
        return state.callerNumber.formatPhoneNumber()
    }
    
    /// The formatted call duration.
    var formattedDuration: String {
        let totalSeconds = Int(state.callDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Init
    
    init(callService: CallServiceProtocol) {
        self.callService = callService
        
        // Sync state from the service
        // Since CallService is an ObservableObject, we would normally pass it as an environment object,
        // but for the HUD window, we inject the protocol and cast it to get the publisher if needed,
        // or just rely on a delegate pattern. For this implementation, we assume `activeCallState`
        // is updated via a Combine publisher on the concrete class.
        if let serviceObj = callService as? CallService {
            serviceObj.$activeCallState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newState in
                    self?.state = newState
                    
                    // Auto-close the window if the call ended
                    if !newState.isVisible {
                        WindowManager.shared.closeCallPopup()
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Actions
    
    func answer() {
        callService.answerCall()
    }
    
    func decline() {
        callService.rejectCall()
    }
    
    func hangup() {
        callService.hangupCall()
    }
}
