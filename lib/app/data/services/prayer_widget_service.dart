import 'package:home_widget/home_widget.dart';

import '../models/prayer_schedule_model.dart';

class PrayerWidgetService {
  Future<void> updateWidgets({
    required String city,
    required String province,
    required String todayLabel,
    required String timezone,
    required String nextPrayerName,
    required String nextPrayerTime,
    required PrayerDayScheduleModel? day,
  }) async {
    await HomeWidget.saveWidgetData<String>('widget_city', city);
    await HomeWidget.saveWidgetData<String>('widget_province', province);
    await HomeWidget.saveWidgetData<String>('widget_today_label', todayLabel);
    await HomeWidget.saveWidgetData<String>('widget_timezone', timezone);
    await HomeWidget.saveWidgetData<String>('widget_next_name', nextPrayerName);
    await HomeWidget.saveWidgetData<String>('widget_next_time', nextPrayerTime);
    await HomeWidget.saveWidgetData<String>('widget_imsak', day?.imsak ?? '-');
    await HomeWidget.saveWidgetData<String>('widget_subuh', day?.subuh ?? '-');
    await HomeWidget.saveWidgetData<String>('widget_dzuhur', day?.dzuhur ?? '-');
    await HomeWidget.saveWidgetData<String>('widget_ashar', day?.ashar ?? '-');
    await HomeWidget.saveWidgetData<String>('widget_maghrib', day?.maghrib ?? '-');
    await HomeWidget.saveWidgetData<String>('widget_isya', day?.isya ?? '-');
    await HomeWidget.saveWidgetData<String>(
      'widget_updated_at',
      DateTime.now().toIso8601String(),
    );

    await HomeWidget.updateWidget(androidName: 'PrayerWidgetCompactProvider');
    await HomeWidget.updateWidget(androidName: 'PrayerWidgetDetailedProvider');
  }
}
