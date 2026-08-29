package com.follow.clash.common

import android.content.ComponentName

object Components {
    const val PACKAGE_NAME = "com.kirillo4ka.eavevpn"

    val mainActivity =
        ComponentName(GlobalState.packageName, "com.follow.clash.MainActivity")

    val quickActionActivity =
        ComponentName(GlobalState.packageName, "com.follow.clash.QuickActionActivity")

    val serviceBroadcastReceiver =
        ComponentName(GlobalState.packageName, "com.follow.clash.ServiceBroadcastReceiver")
}
