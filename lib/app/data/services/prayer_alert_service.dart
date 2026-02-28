import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_alert_settings_model.dart';
import '../models/prayer_schedule_model.dart';

class PrayerAlertService {
  PrayerAlertService() : _notifications = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  AudioPlayer? _adzanPlayer;
  AudioPlayer? _alarmPlayer;
  bool _initialized = false;
  final AudioContext _loudAudioContext = AudioContextConfig(
    route: AudioContextConfigRoute.speaker,
    focus: AudioContextConfigFocus.gain,
    respectSilence: false,
    stayAwake: false,
  ).build();

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(settings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    const channel = AndroidNotificationChannel(
      'prayer_time_channel',
      'Prayer Time Alerts',
      description: 'Notifikasi masuk waktu sholat dan imsak',
      importance: Importance.max,
      playSound: true,
    );
    await androidPlugin?.createNotificationChannel(channel);
    _initialized = true;
  }

  Future<void> playAdzan() async {
    try {
      _adzanPlayer = await _playAssetFresh(
        currentPlayer: _adzanPlayer,
        assetPath: 'audio/adzan.mp3',
      );
    } catch (error) {
      debugPrint('Failed to play adzan: $error');
    }
  }

  Future<void> playAlarm({bool useSystemSound = false}) async {
    try {
      if (useSystemSound) {
        try {
          await FlutterRingtonePlayer().playAlarm(
            looping: false,
            asAlarm: true,
            volume: 1,
          );
          return;
        } on MissingPluginException {
          debugPrint('System alarm plugin unavailable, fallback to asset alarm.');
        }
      }

      _alarmPlayer = await _playAssetFresh(
        currentPlayer: _alarmPlayer,
        assetPath: 'audio/alarm.mp3',
      );
    } catch (error) {
      debugPrint('Failed to play alarm: $error');
    }
  }

  Future<AudioPlayer> _playAssetFresh({
    required AudioPlayer? currentPlayer,
    required String assetPath,
  }) async {
    if (currentPlayer != null) {
      try {
        await currentPlayer.stop().timeout(const Duration(seconds: 2));
      } catch (_) {}
      try {
        await currentPlayer.dispose().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }

    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop).timeout(const Duration(seconds: 2));
    await player.setVolume(1.0).timeout(const Duration(seconds: 2));
    await player.play(
      AssetSource(assetPath),
      volume: 1.0,
      mode: PlayerMode.mediaPlayer,
      ctx: _loudAudioContext,
    ).timeout(const Duration(seconds: 5));
    return player;
  }

  Future<void> showPrayerNotification(String title, String message) async {
    await initialize();
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_time_channel',
          'Prayer Time Alerts',
          channelDescription: 'Notifikasi masuk waktu sholat dan imsak',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleMonthlyPrayerNotifications({
    required MonthlyScheduleModel schedule,
    required String province,
    required String city,
    required String timezoneName,
    required PrayerAlertSettingsModel settings,
  }) async {
    await initialize();
    await _notifications.cancelAll();
    if (!settings.notificationEnabled) {
      return;
    }

    final location = tz.getLocation(timezoneName);
    tz.setLocalLocation(location);

    for (final day in schedule.jadwal) {
      final date = _parseRowDate(day.tanggal);
      if (date == null) {
        continue;
      }

      final entries = <(String, String, String)>[
        (PrayerAlertEventKey.imsak, 'Imsak', day.imsak),
        (PrayerAlertEventKey.subuh, 'Subuh', day.subuh),
        (PrayerAlertEventKey.terbit, 'Terbit', day.terbit),
        (PrayerAlertEventKey.dzuhur, 'Dzuhur', day.dzuhur),
        (PrayerAlertEventKey.ashar, 'Ashar', day.ashar),
        (PrayerAlertEventKey.maghrib, 'Maghrib', day.maghrib),
        (PrayerAlertEventKey.isya, 'Isya', day.isya),
      ];

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        if (settings.modeForEvent(entry.$1) == PrayerAlertMode.off) {
          continue;
        }

        final eventTime = _zonedFromDateAndTime(date, entry.$3, location);
        if (eventTime == null || eventTime.isBefore(tz.TZDateTime.now(location))) {
          continue;
        }

        final id = _notificationId(date, i);
        await _notifications.zonedSchedule(
          id,
          'Waktu ${entry.$2} telah masuk',
          '$city, $province (${_timezoneLabelFromIana(timezoneName)}) ${entry.$3}',
          eventTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_time_channel',
              'Prayer Time Alerts',
              channelDescription: 'Notifikasi masuk waktu sholat dan imsak',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  int _notificationId(DateTime date, int index) {
    final daySeed = (date.year * 10000) + (date.month * 100) + date.day;
    return (daySeed * 10) + index;
  }

  DateTime? _parseRowDate(String raw) {
    final parsedIso = DateTime.tryParse(raw);
    if (parsedIso != null) {
      return parsedIso;
    }

    final parts =
        RegExp(r'\d+').allMatches(raw).map((e) => e.group(0)!).toList();
    if (parts.length < 3) {
      return null;
    }

    if (parts[0].length == 4) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
      return null;
    }

    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
    return null;
  }

  tz.TZDateTime? _zonedFromDateAndTime(
    DateTime date,
    String hhmm,
    tz.Location location,
  ) {
    final parts = hhmm.split(':');
    if (parts.length < 2) {
      return null;
    }
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) {
      return null;
    }
    return tz.TZDateTime(location, date.year, date.month, date.day, hour, minute);
  }

  String _timezoneLabelFromIana(String value) {
    if (value.contains('Jayapura')) {
      return 'WIT';
    }
    if (value.contains('Makassar')) {
      return 'WITA';
    }
    return 'WIB';
  }

  Future<void> dispose() async {
    try {
      await FlutterRingtonePlayer().stop();
    } on MissingPluginException {
      // Ignore on platforms/builds where plugin is not registered.
    }
    final adzan = _adzanPlayer;
    final alarm = _alarmPlayer;
    _adzanPlayer = null;
    _alarmPlayer = null;
    if (adzan != null) {
      try {
        await adzan.dispose().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    if (alarm != null) {
      try {
        await alarm.dispose().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }
}
