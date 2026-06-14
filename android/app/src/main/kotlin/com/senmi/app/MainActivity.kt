package com.senmi.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "custom_notification"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "showNotification") {

                val title =
                    call.argument<String>("title") ?: ""

                val body =
                    call.argument<String>("body") ?: ""

                CustomNotification.show(
                    this,
                    title,
                    body
                )

                result.success(true)

            } else {
                result.notImplemented()
            }
        }
    }
}