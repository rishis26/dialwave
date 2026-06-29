import Foundation

/// Classifies every message exchanged between the Mac and Android companion app.
///
/// Raw string values match the Android-side `MessageType` constants exactly,
/// ensuring cross-platform JSON compatibility.
enum MessageType: String, Codable, CaseIterable, Sendable {
    // Connection lifecycle
    case ping = "PING"
    case pong = "PONG"
    case connectionAck = "CONNECTION_ACK"
    case deviceInfo = "DEVICE_INFO"
    case error = "ERROR"

    // Call control
    case callIncoming = "CALL_INCOMING"
    case callAnswer = "CALL_ANSWER"
    case callReject = "CALL_REJECT"
    case callHangup = "CALL_HANGUP"
    case callDial = "CALL_DIAL"

    // Data sync
    case callLogSync = "CALL_LOG_SYNC"
    case contactSync = "CONTACT_SYNC"

    // SMS
    case smsReceived = "SMS_RECEIVED"
    case smsSend = "SMS_SEND"

    // Audio streaming
    case audioData = "AUDIO_DATA"
}
