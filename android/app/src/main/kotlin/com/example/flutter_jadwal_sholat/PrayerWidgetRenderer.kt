package com.example.flutter_jadwal_sholat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews

object PrayerWidgetRenderer {
    private fun read(context: Context, key: String, fallback: String = "-"): String {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        return prefs.getString(key, fallback) ?: fallback
    }

    fun render(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, compact: Boolean) {
        val views = if (compact) {
            RemoteViews(context.packageName, R.layout.prayer_widget_compact)
        } else {
            RemoteViews(context.packageName, R.layout.prayer_widget_detailed)
        }

        val city = read(context, "widget_city", "Lokasi belum tersedia")
        val timezone = read(context, "widget_timezone", "WIB")
        val nextName = read(context, "widget_next_name", "-")
        val nextTime = read(context, "widget_next_time", "-")
        val imsak = read(context, "widget_imsak")
        val subuh = read(context, "widget_subuh")
        val dzuhur = read(context, "widget_dzuhur")
        val ashar = read(context, "widget_ashar")
        val maghrib = read(context, "widget_maghrib")
        val isya = read(context, "widget_isya")

        views.setTextViewText(R.id.widget_city, "$city • $timezone")
        views.setTextViewText(R.id.widget_next, "Berikutnya: $nextName $nextTime")
        views.setTextViewText(R.id.widget_imsak, imsak)
        views.setTextViewText(R.id.widget_subuh, subuh)
        views.setTextViewText(R.id.widget_dzuhur, dzuhur)
        views.setTextViewText(R.id.widget_maghrib, maghrib)
        if (!compact) {
            views.setTextViewText(R.id.widget_ashar, ashar)
            views.setTextViewText(R.id.widget_isya, isya)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
