package com.senmi.app

import android.app.NotificationManager
import android.content.Context
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

object CustomNotification {

    fun show(
        context: Context,
        title: String,
        body: String
    ) {

        val remoteViews =
            RemoteViews(
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

        val notification =
            NotificationCompat.Builder(
                context,
                "senmi_channel"
            )
                .setSmallIcon(R.drawable.notification_icon)
                .setCustomContentView(remoteViews)
                .setStyle(
                    NotificationCompat.DecoratedCustomViewStyle()
                )
                .setPriority(
                    NotificationCompat.PRIORITY_HIGH
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