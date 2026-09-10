package com.senmi.app

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "custom_notification"

    private var methodChannel: MethodChannel? = null

    private var pendingNotificationData: Map<String, String>? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->

            when (call.method) {

                "showNotification" -> {

                    val title =
                        call.argument<String>("title") ?: ""

                    val body =
                        call.argument<String>("body") ?: ""

                    val packageId =
                        call.argument<String>("package_id")

                    CustomNotification.show(
                        this,
                        title,
                        body,
                        packageId
                    )

                    result.success(true)
                }

                "getNotificationData" -> {

                    Log.d(
                        "SENMI_NOTIFICATION",
                        "Flutter requested notification data: $pendingNotificationData"
                    )

                    val data = pendingNotificationData

                    pendingNotificationData = null

                    result.success(data)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        Log.d(
            "SENMI_NOTIFICATION",
            "configureFlutterEngine - checking launch intent"
        )

        handleNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        Log.d(
            "SENMI_NOTIFICATION",
            "onNewIntent called"
        )

        setIntent(intent)

        handleNotificationIntent(intent)
    }

    override fun onResume() {
        super.onResume()

        Log.d(
            "SENMI_NOTIFICATION",
            "onResume - checking intent"
        )

        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(
        intent: Intent?
    ) {

        if (intent == null) {
            Log.d(
                "SENMI_NOTIFICATION",
                "Intent is null"
            )
            return
        }

        val notificationType =
            intent.getStringExtra(
                "notification_type"
            )

        val packageId =
            intent.getStringExtra(
                "package_id"
            )

        Log.d(
            "SENMI_NOTIFICATION",
            "notification_type = $notificationType"
        )

        Log.d(
            "SENMI_NOTIFICATION",
            "package_id = $packageId"
        )

        if (
            notificationType == "package" &&
            !packageId.isNullOrEmpty()
        ) {

            Log.d(
                "SENMI_NOTIFICATION",
                "PACKAGE NOTIFICATION FOUND"
            )

            Log.d(
                "SENMI_NOTIFICATION",
                "PACKAGE ID = $packageId"
            )

            val data =
                mapOf(
                    "type" to "package",
                    "package_id" to packageId
                )

            pendingNotificationData = data

            methodChannel?.invokeMethod(
                "notificationTapped",
                data
            )

            /*
             * Remove the notification extras from the Intent
             * so onResume() does not process the same notification
             * repeatedly.
             */
            intent.removeExtra("notification_type")
            intent.removeExtra("package_id")
        }
    }
}