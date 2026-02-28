package com.example.flutter_jadwal_sholat

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

class PrayerWidgetDetailedProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            PrayerWidgetRenderer.render(context, appWidgetManager, appWidgetId, compact = false)
        }
    }
}
