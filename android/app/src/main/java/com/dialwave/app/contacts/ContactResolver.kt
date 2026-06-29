package com.dialwave.app.contacts

import android.annotation.SuppressLint
import android.content.Context
import android.provider.ContactsContract
import com.dialwave.app.protocol.ContactSyncModel
import com.dialwave.app.protocol.PhoneNumber

/**
 * Reads contacts from the Android Contacts Provider to sync to the Mac.
 */
class ContactResolver(private val context: Context) {

    @SuppressLint("Range")
    fun fetchAllContacts(): List<ContactSyncModel> {
        val contactsMap = mutableMapOf<String, ContactSyncModel>()
        
        val uri = ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
            ContactsContract.CommonDataKinds.Phone.TYPE,
            ContactsContract.CommonDataKinds.Phone.LABEL
        )
        
        val cursor = context.contentResolver.query(
            uri, projection, null, null,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC"
        )
        
        cursor?.use {
            while (it.moveToNext()) {
                val id = it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID))
                val name = it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)) ?: "Unknown"
                val number = it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)) ?: continue
                val type = it.getInt(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.TYPE))
                val customLabel = it.getString(it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.LABEL))
                
                val label = ContactsContract.CommonDataKinds.Phone.getTypeLabel(context.resources, type, customLabel).toString()
                val phoneNumber = PhoneNumber(label, number)
                
                if (contactsMap.containsKey(id)) {
                    val existing = contactsMap[id]!!
                    val updatedPhones = existing.phoneNumbers.toMutableList().apply { add(phoneNumber) }
                    contactsMap[id] = existing.copy(phoneNumbers = updatedPhones)
                } else {
                    contactsMap[id] = ContactSyncModel(
                        id = id,
                        name = name,
                        phoneNumbers = listOf(phoneNumber),
                        email = null, // Can fetch via separate query if needed
                        avatarData = null
                    )
                }
            }
        }
        
        return contactsMap.values.toList()
    }
}
