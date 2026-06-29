package com.dialwave.app.protocol

import kotlinx.serialization.Serializable

// MARK: - Sub-models (matching Swift)

@Serializable
data class PhoneNumber(
    val label: String,
    val value: String
)

@Serializable
data class ContactSyncModel(
    val id: String,
    val name: String,
    val phoneNumbers: List<PhoneNumber>,
    val email: String? = null,
    val avatarData: String? = null // Base64
)

@Serializable
data class CallRecordModel(
    val id: String,
    val contactName: String?,
    val phoneNumber: String,
    val type: String, // "incoming", "outgoing", "missed"
    val duration: Double,
    val timestamp: Double,
    val isRead: Boolean
)

@Serializable
data class SMSMessageModel(
    val id: String,
    val threadId: String,
    val contactName: String?,
    val phoneNumber: String,
    val body: String,
    val timestamp: Double,
    val isIncoming: Boolean,
    val isRead: Boolean
)

// MARK: - Events (Android -> Mac)

@Serializable
data class IncomingCallEvent(
    val callId: String,
    val callerNumber: String,
    val callerName: String? = null
)

@Serializable
data class ContactSyncEvent(
    val isIncremental: Boolean,
    val contacts: List<ContactSyncModel>
)

@Serializable
data class SMSReceivedEvent(
    val message: SMSMessageModel
)
