package com.example.caregap_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "caregap_updates", "돌봄 소식", NotificationManager.IMPORTANCE_HIGH
            ).apply { description = "상담 일정과 돌봄 서비스 소식" }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
