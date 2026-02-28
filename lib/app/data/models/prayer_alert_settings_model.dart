enum PrayerAlertMode {
  off,
  notificationOnly,
  adzan,
  alarm,
}

extension PrayerAlertModeX on PrayerAlertMode {
  String get storageValue => switch (this) {
    PrayerAlertMode.off => 'off',
    PrayerAlertMode.notificationOnly => 'notification_only',
    PrayerAlertMode.adzan => 'adzan',
    PrayerAlertMode.alarm => 'alarm',
  };

  String get label => switch (this) {
    PrayerAlertMode.off => 'Nonaktif',
    PrayerAlertMode.notificationOnly => 'Notifikasi saja',
    PrayerAlertMode.adzan => 'Notifikasi + Adzan',
    PrayerAlertMode.alarm => 'Notifikasi + Alarm',
  };
}

PrayerAlertMode prayerAlertModeFromStorage(String raw) {
  for (final value in PrayerAlertMode.values) {
    if (value.storageValue == raw) {
      return value;
    }
  }
  return PrayerAlertMode.notificationOnly;
}

abstract final class PrayerAlertEventKey {
  static const imsak = 'imsak';
  static const subuh = 'subuh';
  static const terbit = 'terbit';
  static const dzuhur = 'dzuhur';
  static const ashar = 'ashar';
  static const maghrib = 'maghrib';
  static const isya = 'isya';
}

class PrayerAlertEventSetting {
  const PrayerAlertEventSetting({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

const List<PrayerAlertEventSetting> prayerAlertEventSettings =
    <PrayerAlertEventSetting>[
      PrayerAlertEventSetting(key: PrayerAlertEventKey.imsak, label: 'Imsak'),
      PrayerAlertEventSetting(
        key: PrayerAlertEventKey.subuh,
        label: 'Subuh / Fajar',
      ),
      PrayerAlertEventSetting(
        key: PrayerAlertEventKey.terbit,
        label: 'Terbit',
      ),
      PrayerAlertEventSetting(
        key: PrayerAlertEventKey.dzuhur,
        label: 'Dzuhur',
      ),
      PrayerAlertEventSetting(key: PrayerAlertEventKey.ashar, label: 'Ashar'),
      PrayerAlertEventSetting(
        key: PrayerAlertEventKey.maghrib,
        label: 'Maghrib',
      ),
      PrayerAlertEventSetting(key: PrayerAlertEventKey.isya, label: 'Isya'),
    ];

class PrayerAlertSettingsModel {
  const PrayerAlertSettingsModel({
    required this.notificationEnabled,
    required this.adzanEnabled,
    required this.alarmEnabled,
    required this.useSystemAlarmSound,
    required this.eventModes,
  });

  final bool notificationEnabled;
  final bool adzanEnabled;
  final bool alarmEnabled;
  final bool useSystemAlarmSound;
  final Map<String, PrayerAlertMode> eventModes;

  factory PrayerAlertSettingsModel.defaults() {
    return PrayerAlertSettingsModel(
      notificationEnabled: true,
      adzanEnabled: true,
      alarmEnabled: true,
      useSystemAlarmSound: false,
      eventModes: <String, PrayerAlertMode>{
        for (final event in prayerAlertEventSettings)
          event.key: event.key == PrayerAlertEventKey.imsak
              ? PrayerAlertMode.alarm
              : PrayerAlertMode.adzan,
      },
    );
  }

  factory PrayerAlertSettingsModel.fromJson(Map<String, dynamic> json) {
    final defaults = PrayerAlertSettingsModel.defaults();
    final rawModes = json['event_modes'];
    final parsedModes = <String, PrayerAlertMode>{};
    if (rawModes is Map) {
      for (final event in prayerAlertEventSettings) {
        final rawValue = rawModes[event.key]?.toString() ?? '';
        parsedModes[event.key] = prayerAlertModeFromStorage(rawValue);
      }
    }

    return PrayerAlertSettingsModel(
      notificationEnabled:
          json['notification_enabled'] is bool
              ? json['notification_enabled'] as bool
              : defaults.notificationEnabled,
      adzanEnabled:
          json['adzan_enabled'] is bool
              ? json['adzan_enabled'] as bool
              : defaults.adzanEnabled,
      alarmEnabled:
          json['alarm_enabled'] is bool
              ? json['alarm_enabled'] as bool
              : defaults.alarmEnabled,
      useSystemAlarmSound:
          json['use_system_alarm_sound'] is bool
              ? json['use_system_alarm_sound'] as bool
              : defaults.useSystemAlarmSound,
      eventModes: <String, PrayerAlertMode>{
        for (final event in prayerAlertEventSettings)
          event.key: parsedModes[event.key] ?? defaults.modeForEvent(event.key),
      },
    );
  }

  PrayerAlertMode modeForEvent(String eventKey) {
    return eventModes[eventKey] ?? PrayerAlertMode.notificationOnly;
  }

  PrayerAlertSettingsModel copyWith({
    bool? notificationEnabled,
    bool? adzanEnabled,
    bool? alarmEnabled,
    bool? useSystemAlarmSound,
    Map<String, PrayerAlertMode>? eventModes,
  }) {
    return PrayerAlertSettingsModel(
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      adzanEnabled: adzanEnabled ?? this.adzanEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      useSystemAlarmSound: useSystemAlarmSound ?? this.useSystemAlarmSound,
      eventModes: eventModes ?? this.eventModes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'notification_enabled': notificationEnabled,
      'adzan_enabled': adzanEnabled,
      'alarm_enabled': alarmEnabled,
      'use_system_alarm_sound': useSystemAlarmSound,
      'event_modes': <String, String>{
        for (final entry in eventModes.entries)
          entry.key: entry.value.storageValue,
      },
    };
  }
}
