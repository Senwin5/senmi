package com.senmi.app

import android.app.NotificationManager
import android.content.Context
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

        val notification =
            NotificationCompat.Builder(
                context,
                "senmi_channel"
            )
                .setSmallIcon(R.drawable.notification_icon)

                // Normal view
                .setCustomContentView(remoteViews)

                // Expanded view (using SAME XML)
                .setCustomBigContentView(remoteViews)

                .setStyle(
                    NotificationCompat.DecoratedCustomViewStyle()
                )

                .setPriority(
                    NotificationCompat.PRIORITY_HIGH
                )

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