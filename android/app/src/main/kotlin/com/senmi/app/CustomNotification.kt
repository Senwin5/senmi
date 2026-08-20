package com.senmi.app

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

object CustomNotification {

    fun show(
        context: Context,
        title: String,
        body: String
    ) {

        val remoteViews = RemoteViews(
            context.packageName,
            R.layout.custom_notification
        )

        remoteViews.setTextViewText(
            R.id.title,
            title
        )

        remoteViews.setTextViewText(
            R.id.body,
            body
        )

        remoteViews.setTextColor(
            R.id.title,
            Color.WHITE
        )

        remoteViews.setTextColor(
            R.id.body,
            Color.WHITE
        )

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
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )

        val notification =
            NotificationCompat.Builder(
                context,
                "senmi_channel"
            )
                .setSmallIcon(R.drawable.notification_icon)

                .setCustomContentView(remoteViews)

                .setCustomBigContentView(remoteViews)

                .setStyle(
                    NotificationCompat.DecoratedCustomViewStyle()
                )

                .setPriority(
                    NotificationCompat.PRIORITY_HIGH
                )

                // 🔥 THIS MAKES THE NOTIFICATION CLICKABLE
                .setContentIntent(pendingIntent)

                .setAutoCancel(true)

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