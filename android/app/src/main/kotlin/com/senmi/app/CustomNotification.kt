package com.senmi.app

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat

object CustomNotification {

    fun show(
        context: Context,
        title: String,
        body: String,
        packageId: String?
    ) {

        // =========================
        // 📲 OPEN SENMI WHEN TAPPED
        // =========================

        val intent = Intent(
            context,
            MainActivity::class.java
        ).apply {

            flags =
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP

            // =========================
            // 📦 PACKAGE DATA
            // =========================

            if (!packageId.isNullOrEmpty()) {
                putExtra(
                    "notification_type",
                    "package"
                )

                putExtra(
                    "package_id",
                    packageId
                )
            }
        }

        val requestCode =
            System.currentTimeMillis().toInt()

        val pendingIntent =
            PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )

        // =========================
        // 🔔 NOTIFICATION
        // =========================

        val notification =
            NotificationCompat.Builder(
                context,
                "senmi_channel"
            )
                .setSmallIcon(
                    R.drawable.notification_icon
                )
                .setContentTitle(title)
                .setContentText(body)
                .setLargeIcon(
                    android.graphics.BitmapFactory
                        .decodeResource(
                            context.resources,
                            R.drawable.notification_icon
                        )
                )
                .setPriority(
                    NotificationCompat.PRIORITY_HIGH
                )
                .setContentIntent(
                    pendingIntent
                )
                .setAutoCancel(true)
                .setStyle(
                    NotificationCompat.BigTextStyle()
                        .bigText(body)
                )
                .build()

        val manager =
            context.getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as NotificationManager

        manager.notify(
            System.currentTimeMillis().toInt(),
            notification
        )
    }
}