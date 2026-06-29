package com.dialwave.app.protocol

import kotlinx.serialization.Serializable

/**
 * Identifies the type of payload contained in a Message.
 * Matches exactly with the Swift MessageType enum.
 */
@Serializable
enum class MessageType {
    // Connection
    PING,
    PONG,
    
    // Calls
    CALL_INCOMING,
    CALL_ANSWER,
    CALL_REJECT,
    CALL_HANGUP,
    CALL_DIAL,
    CALL_STATE_CHANGED,
    
    // Sync
    CALL_LOG_SYNC,
    CONTACT_SYNC,
    
    // SMS
    SMS_RECEIVED,
    SMS_SEND,
    
    // Error
    ERROR
}

/**
 * Base envelope for all JSON communication over the TCP socket.
 */
@Serializable
data class Message(
    val type: MessageType,
    // Using String to hold nested JSON to avoid complex polymorphic serialization
    // across different Kotlin/Swift libraries. Base64 is used for raw bytes in Swift, 
    // but here we just store the nested stringified JSON.
    val payload: String? = null
)
