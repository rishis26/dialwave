package com.dialwave.app.bluetooth

enum class ConnectionState {
    DISCONNECTED,
    ADVERTISING,
    WAITING_FOR_WIFI,
    CONNECTED_WIFI,
    ERROR
}
