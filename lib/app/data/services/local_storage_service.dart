import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/prayer_alert_settings_model.dart';
import '../models/prayer_schedule_model.dart';

abstract final class AppStorageKeys {
  static const hasSeenOnboarding = 'has_seen_onboarding';
  static const lastPrayerAlertKey = 'last_prayer_alert_key';
  static const cachedProvince = 'cached_province';
  static const cachedCity = 'cached_city';
  static const cachedLocationAt = 'cached_location_at';
  static const cachedSchedule = 'cached_schedule_json';
  static const cachedScheduleProvince = 'cached_schedule_province';
  static const cachedScheduleCity = 'cached_schedule_city';
  static const cachedScheduleMonth = 'cached_schedule_month';
  static const cachedScheduleYear = 'cached_schedule_year';
  static const prayerAlertSettings = 'prayer_alert_settings_json';
}

class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  bool get hasSeenOnboarding =>
      _prefs.getBool(AppStorageKeys.hasSeenOnboarding) ?? false;

  Future<bool> setHasSeenOnboarding(bool value) {
    return _prefs.setBool(AppStorageKeys.hasSeenOnboarding, value);
  }

  String get lastPrayerAlertKey =>
      _prefs.getString(AppStorageKeys.lastPrayerAlertKey) ?? '';

  Future<bool> setLastPrayerAlertKey(String value) {
    return _prefs.setString(AppStorageKeys.lastPrayerAlertKey, value);
  }

  String get cachedProvince => _prefs.getString(AppStorageKeys.cachedProvince) ?? '';

  String get cachedCity => _prefs.getString(AppStorageKeys.cachedCity) ?? '';

  DateTime? get cachedLocationAt {
    final value = _prefs.getString(AppStorageKeys.cachedLocationAt);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> saveCachedLocation({
    required String province,
    required String city,
  }) async {
    await _prefs.setString(AppStorageKeys.cachedProvince, province);
    await _prefs.setString(AppStorageKeys.cachedCity, city);
    await _prefs.setString(
      AppStorageKeys.cachedLocationAt,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> clearCachedLocation() async {
    await _prefs.remove(AppStorageKeys.cachedProvince);
    await _prefs.remove(AppStorageKeys.cachedCity);
    await _prefs.remove(AppStorageKeys.cachedLocationAt);
  }

  MonthlyScheduleModel? get cachedSchedule {
    final raw = _prefs.getString(AppStorageKeys.cachedSchedule);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return MonthlyScheduleModel.fromJson(json);
      }
      if (json is Map) {
        return MonthlyScheduleModel.fromJson(json.cast<String, dynamic>());
      }
    } catch (_) {}
    return null;
  }

  String get cachedScheduleProvince =>
      _prefs.getString(AppStorageKeys.cachedScheduleProvince) ?? '';

  String get cachedScheduleCity =>
      _prefs.getString(AppStorageKeys.cachedScheduleCity) ?? '';

  int get cachedScheduleMonth => _prefs.getInt(AppStorageKeys.cachedScheduleMonth) ?? 0;

  int get cachedScheduleYear => _prefs.getInt(AppStorageKeys.cachedScheduleYear) ?? 0;

  Future<void> saveCachedSchedule({
    required String province,
    required String city,
    required int month,
    required int year,
    required MonthlyScheduleModel schedule,
  }) async {
    await _prefs.setString(AppStorageKeys.cachedSchedule, jsonEncode(schedule.toJson()));
    await _prefs.setString(AppStorageKeys.cachedScheduleProvince, province);
    await _prefs.setString(AppStorageKeys.cachedScheduleCity, city);
    await _prefs.setInt(AppStorageKeys.cachedScheduleMonth, month);
    await _prefs.setInt(AppStorageKeys.cachedScheduleYear, year);
  }

  PrayerAlertSettingsModel get prayerAlertSettings {
    final raw = _prefs.getString(AppStorageKeys.prayerAlertSettings);
    if (raw == null || raw.isEmpty) {
      return PrayerAlertSettingsModel.defaults();
    }

    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        return PrayerAlertSettingsModel.fromJson(json);
      }
      if (json is Map) {
        return PrayerAlertSettingsModel.fromJson(json.cast<String, dynamic>());
      }
    } catch (_) {}

    return PrayerAlertSettingsModel.defaults();
  }

  Future<bool> setPrayerAlertSettings(PrayerAlertSettingsModel value) {
    return _prefs.setString(
      AppStorageKeys.prayerAlertSettings,
      jsonEncode(value.toJson()),
    );
  }
}
