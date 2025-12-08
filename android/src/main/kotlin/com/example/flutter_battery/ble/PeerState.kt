package com.example.flutter_battery.ble

data class PeerState(
    val role: String,
    val localBattery: Int,
    val remoteBattery: Int?,
    val connected: Boolean
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "role" to role,
            "localBattery" to localBattery,
            "remoteBattery" to remoteBattery,
            "connected" to connected
        )
    }
}

interface PeerStateListener {
    fun onPeerState(state: PeerState)
}
