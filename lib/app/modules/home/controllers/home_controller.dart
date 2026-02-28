import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../data/models/prayer_alert_settings_model.dart';
import '../../../data/models/prayer_schedule_model.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../data/services/prayer_alert_service.dart';
import '../../../data/services/prayer_api_service.dart';
import '../../../data/services/prayer_widget_service.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  HomeController({PrayerApiService? apiService})
      : _apiService = apiService ?? PrayerApiService();

  final PrayerApiService _apiService;
  final LocalStorageService _storage = Get.find<LocalStorageService>();
  final PrayerAlertService _alertService = Get.find<PrayerAlertService>();
  final PrayerWidgetService _widgetService = Get.find<PrayerWidgetService>();

  final provinces = <String>[].obs;
  final cities = <String>[].obs;

  final selectedProvince = RxnString();
  final selectedCity = RxnString();

  final selectedMonth = DateTime.now().month.obs;
  final selectedYear = DateTime.now().year.obs;

  final schedule = Rxn<MonthlyScheduleModel>();
  final activeDay = Rxn<PrayerDayScheduleModel>();

  final isLoadingProvince = false.obs;
  final isLoadingCity = false.obs;
  final isLoadingSchedule = false.obs;
  final isLocatingGps = false.obs;
  final isBootstrapping = true.obs;

  final errorMessage = RxnString();
  final nowClock = '--:--:--'.obs;
  final timezoneLabel = 'WIB'.obs;
  final nextPrayerName = '-'.obs;
  final nextPrayerTime = '-'.obs;
  final countdownLabel = '--:--:--'.obs;
  final heroStatus = 'Menyiapkan lokasi dan jadwal...'.obs;
  final alertSettings = PrayerAlertSettingsModel.defaults().obs;

  Timer? _ticker;

  bool get showSkeleton =>
      schedule.value == null &&
      (isBootstrapping.value ||
          isLoadingProvince.value ||
          isLoadingCity.value ||
          isLoadingSchedule.value ||
          isLocatingGps.value);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadAlertSettings();
    unawaited(_alertService.initialize());
    _tickClock();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickClock();
      _computeNextPrayer();
      _checkPrayerEntryAlert();
    });
    unawaited(loadInitialData());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _alertService.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(detectLocationFromGps(silent: true, forceRefreshSchedule: true));
    }
  }

  Future<void> loadInitialData() async {
    isBootstrapping.value = true;
    await loadProvinces();
    if (provinces.isEmpty) {
      isBootstrapping.value = false;
      return;
    }

    final restored = await _restoreLocationFromCacheAndFetch();
    if (!restored) {
      await detectLocationFromGps(silent: false);
    }

    if (schedule.value == null &&
        selectedProvince.value != null &&
        selectedCity.value != null) {
      final loaded = _restoreMonthlyScheduleFromCache();
      if (!loaded) {
        await useCurrentMonthAndFetch();
      }
    }

    isBootstrapping.value = false;
  }

  Future<void> refreshLocationFromPull() async {
    await detectLocationFromGps(silent: false, forceRefreshSchedule: true);
  }

  Future<bool> _restoreLocationFromCacheAndFetch() async {
    final cachedProvince = _storage.cachedProvince;
    final cachedCity = _storage.cachedCity;

    if (cachedProvince.isEmpty || cachedCity.isEmpty) {
      return false;
    }

    final province = _findBestMatch(provinces, <String>[cachedProvince]);
    if (province == null) {
      return false;
    }

    await changeProvince(province);

    if (cities.isEmpty) {
      return false;
    }

    final city = _findBestMatch(
      cities,
      _expandCityCandidates(<String>[cachedCity]),
      simplifyAdminWords: false,
    );

    if (city == null) {
      return false;
    }

    selectedCity.value = city;
    final loaded = _restoreMonthlyScheduleFromCache();
    if (!loaded) {
      await useCurrentMonthAndFetch();
    }
    heroStatus.value = 'Lokasi tersimpan aktif: $city';
    return true;
  }

  Future<void> loadProvinces() async {
    isLoadingProvince.value = true;
    errorMessage.value = null;
    try {
      final result = await _apiService.getProvinces();
      provinces.assignAll(result);
    } catch (_) {
      errorMessage.value = 'Gagal memuat provinsi. Coba lagi.';
    } finally {
      isLoadingProvince.value = false;
    }
  }

  Future<void> changeProvince(String province) async {
    selectedProvince.value = province;
    _updateTimezoneLabel();
    selectedCity.value = null;
    cities.clear();
    await loadCities();
  }

  Future<void> loadCities() async {
    final province = selectedProvince.value;
    if (province == null || province.isEmpty) {
      return;
    }

    isLoadingCity.value = true;
    errorMessage.value = null;
    try {
      final result = await _apiService.getCities(province);
      cities.assignAll(result);
      if (cities.isNotEmpty) {
        selectedCity.value = _findBestMatch(cities, const <String>[
              'KOTA JAKARTA PUSAT',
              'JAKARTA PUSAT',
              'JAKARTA',
            ]) ??
            cities.first;
      }
    } catch (_) {
      errorMessage.value = 'Gagal memuat kabupaten/kota.';
    } finally {
      isLoadingCity.value = false;
    }
  }

  Future<void> detectLocationFromGps({
    bool silent = false,
    bool forceRefreshSchedule = false,
  }) async {
    isLocatingGps.value = true;
    if (!silent) {
      errorMessage.value = null;
    }

    try {
      if (provinces.isEmpty) {
        await loadProvinces();
      }
      if (provinces.isEmpty) {
        throw Exception('Daftar provinsi kosong.');
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('GPS belum aktif di perangkat.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final nearestResult = _findNearestHintWithDistance(
        position.latitude,
        position.longitude,
      );
      final useNearestHint =
          nearestResult != null && nearestResult.distanceMeters <= 90000;

      GeoLocationCandidates? geo;
      try {
        geo = await _apiService.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        // Continue with coordinate fallback.
      }

      final provinceCandidates = <String>[
        if (useNearestHint) nearestResult.hint.province,
        ...?geo?.provinceCandidates,
      ];
      final cityCandidates = <String>[
        if (useNearestHint) nearestResult.hint.city,
        ...?geo?.cityCandidates,
      ];

      if (provinceCandidates.isEmpty && cityCandidates.isEmpty) {
        throw Exception('Lokasi tidak bisa dipetakan. Pastikan internet aktif.');
      }

      final matchedProvince = _findBestMatch(provinces, provinceCandidates);
      String? matchedCity;

      if (matchedProvince == null) {
        throw Exception('Lokasi tidak cocok dengan data provinsi API.');
      }

      await changeProvince(matchedProvince);
      if (cities.isEmpty) {
        throw Exception('Kota/kabupaten tidak tersedia untuk provinsi ini.');
      }

      matchedCity = _findBestMatch(
        cities,
        _expandCityCandidates(cityCandidates),
        simplifyAdminWords: false,
      );
      if (matchedCity == null && useNearestHint) {
        matchedCity = _findBestMatch(
          cities,
          _expandCityCandidates(<String>[nearestResult.hint.city]),
          simplifyAdminWords: false,
        );
      }

      if (matchedCity == null) {
        throw Exception('Kota terdekat tidak ditemukan, silakan pilih manual.');
      }

      selectedCity.value = matchedCity;
      if (forceRefreshSchedule || !_restoreMonthlyScheduleFromCache()) {
        await useCurrentMonthAndFetch();
      }
      await _storage.saveCachedLocation(
        province: matchedProvince,
        city: matchedCity,
      );
      heroStatus.value = 'Lokasi GPS aktif: ${selectedCity.value}';
    } catch (e) {
      if (!silent) {
        errorMessage.value = 'Gagal menggunakan GPS: $e';
      }
    } finally {
      isLocatingGps.value = false;
    }
  }

  void changeCity(String city) {
    selectedCity.value = city;
    final province = selectedProvince.value;
    if (province != null) {
      unawaited(_storage.saveCachedLocation(province: province, city: city));
    }
  }

  void changeMonth(int month) {
    selectedMonth.value = month;
  }

  void changeYear(int year) {
    if (year < 2020 || year > 2100) {
      return;
    }
    selectedYear.value = year;
  }

  void setNotificationEnabled(bool value) {
    final current = alertSettings.value;
    _applyAlertSettings(current.copyWith(notificationEnabled: value));
  }

  void setAdzanEnabled(bool value) {
    final current = alertSettings.value;
    _applyAlertSettings(current.copyWith(adzanEnabled: value));
  }

  void setAlarmEnabled(bool value) {
    final current = alertSettings.value;
    _applyAlertSettings(current.copyWith(alarmEnabled: value));
  }

  void setUseSystemAlarmSound(bool value) {
    final current = alertSettings.value;
    _applyAlertSettings(current.copyWith(useSystemAlarmSound: value));
  }

  void setEventAlertMode(String eventKey, PrayerAlertMode mode) {
    final current = alertSettings.value;
    final nextModes = <String, PrayerAlertMode>{...current.eventModes};
    nextModes[eventKey] = mode;
    _applyAlertSettings(current.copyWith(eventModes: nextModes));
  }

  PrayerAlertMode eventAlertMode(String eventKey) {
    return alertSettings.value.modeForEvent(eventKey);
  }

  List<PrayerAlertEventSetting> get configurableAlertEvents =>
      prayerAlertEventSettings;

  Future<void> testAdzanSound() async {
    await _alertService.playAdzan();
  }

  Future<void> testAlarmSound() async {
    await _alertService.playAlarm(
      useSystemSound: alertSettings.value.useSystemAlarmSound,
    );
  }

  Future<void> useCurrentMonthAndFetch() async {
    final now = DateTime.now();
    selectedMonth.value = now.month;
    selectedYear.value = now.year;
    await fetchSchedule();
  }

  Future<void> fetchSchedule() async {
    final province = selectedProvince.value;
    final city = selectedCity.value;

    if (province == null || city == null) {
      errorMessage.value = 'Provinsi dan kota wajib dipilih.';
      return;
    }

    isLoadingSchedule.value = true;
    errorMessage.value = null;

    try {
      final result = await _apiService.getMonthlySchedule(
        province: province,
        city: city,
        month: selectedMonth.value,
        year: selectedYear.value,
      );

      schedule.value = result;
      final nowLoc = _nowForLocation();
      activeDay.value =
          _pickRowForDate(result.jadwal, nowLoc) ??
          (result.jadwal.isNotEmpty ? result.jadwal.first : null);
      await _storage.saveCachedSchedule(
        province: province,
        city: city,
        month: selectedMonth.value,
        year: selectedYear.value,
        schedule: result,
      );
      _computeNextPrayer();
      await _syncWidgetAndNotificationData();
      _checkPrayerEntryAlert(force: true);
    } catch (_) {
      errorMessage.value = 'Gagal memuat jadwal sholat. Pastikan lokasi valid.';
    } finally {
      isLoadingSchedule.value = false;
      isBootstrapping.value = false;
    }
  }

  List<int> get yearOptions {
    final current = DateTime.now().year;
    return List<int>.generate(12, (index) => current - 2 + index);
  }

  String get resultMeta {
    final data = schedule.value;
    if (data == null) {
      return 'Pilih lokasi lalu tekan Tampilkan Jadwal.';
    }
    return 'Jadwal ${data.bulanNama} ${data.tahun} untuk ${data.kabkota}, ${data.provinsi} (${timezoneLabel.value})';
  }

  String get todayLabel {
    final data = schedule.value;
    final day = activeDay.value;
    if (data == null || day == null) {
      return '-';
    }
    return '${day.hari}, ${day.tanggal} ${data.bulanNama} ${data.tahun}';
  }

  List<PrayerTimeModel> get prayerList =>
      activeDay.value?.toPrayerList() ?? const <PrayerTimeModel>[];

  void _tickClock() {
    nowClock.value = DateFormat('HH:mm:ss').format(_nowForLocation());
  }

  DateTime _nowForLocation() {
    // Keep DateTime in local mode so comparison with schedule times
    // (constructed as local DateTime) stays consistent.
    final localNow = DateTime.now();
    final targetOffset = _timezoneOffsetForProvince(selectedProvince.value);
    final deviceOffset = localNow.timeZoneOffset;
    return localNow.add(targetOffset - deviceOffset);
  }

  Duration _timezoneOffsetForProvince(String? provinceRaw) {
    final province = _normalize(provinceRaw ?? '');
    if (province.isEmpty) {
      return const Duration(hours: 7);
    }

    if (_witaProvinceKeywords.any(province.contains)) {
      return const Duration(hours: 8);
    }

    if (_witProvinceKeywords.any(province.contains)) {
      return const Duration(hours: 9);
    }

    return const Duration(hours: 7);
  }

  void _updateTimezoneLabel() {
    final offset = _timezoneOffsetForProvince(selectedProvince.value);
    if (offset.inHours == 9) {
      timezoneLabel.value = 'WIT';
    } else if (offset.inHours == 8) {
      timezoneLabel.value = 'WITA';
    } else {
      timezoneLabel.value = 'WIB';
    }
  }

  PrayerDayScheduleModel? _pickRowForDate(
    List<PrayerDayScheduleModel> rows,
    DateTime date,
  ) {
    for (final row in rows) {
      final rowDate = _parseRowDate(row.tanggal);
      if (rowDate == null) {
        continue;
      }

      if (rowDate.year == date.year &&
          rowDate.month == date.month &&
          rowDate.day == date.day) {
        return row;
      }
    }
    return null;
  }

  DateTime? _parseRowDate(String raw) {
    final parsedIso = DateTime.tryParse(raw);
    if (parsedIso != null) {
      return parsedIso;
    }

    final parts = RegExp(r'\d+').allMatches(raw).map((e) => e.group(0)!).toList();
    if (parts.isEmpty) {
      return null;
    }

    if (parts.length >= 3) {
      if (parts[0].length == 4) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }

      if (parts[2].length == 4) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }

    final day = int.tryParse(parts.last);
    if (day == null) {
      return null;
    }
    return DateTime(selectedYear.value, selectedMonth.value, day);
  }

  int? _timeToMinute(String value) {
    final match = RegExp(r'(\d{1,2})\s*:\s*(\d{2})').firstMatch(value);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return (hour * 60) + minute;
  }

  void _computeNextPrayer() {
    final data = schedule.value;
    if (data == null) {
      nextPrayerName.value = '-';
      nextPrayerTime.value = '-';
      countdownLabel.value = '--:--:--';
      heroStatus.value = 'Pilih lokasi untuk menampilkan jadwal.';
      return;
    }

    final now = _nowForLocation();
    final todayRow = _pickRowForDate(data.jadwal, now) ?? activeDay.value;
    final tomorrowRow = _pickRowForDate(
      data.jadwal,
      now.add(const Duration(days: 1)),
    );

    if (todayRow == null) {
      heroStatus.value = 'Jadwal hari ini belum tersedia untuk filter saat ini.';
      nextPrayerName.value = '-';
      nextPrayerTime.value = '-';
      countdownLabel.value = '--:--:--';
      return;
    }

    activeDay.value = todayRow;

    final todayCandidates = _buildPrayerDateTimes(todayRow, now);
    final upcomingToday = todayCandidates.where((item) => item.$2.isAfter(now));
    if (upcomingToday.isNotEmpty) {
      final next = upcomingToday.first;
      nextPrayerName.value = next.$1;
      nextPrayerTime.value = DateFormat('HH:mm').format(next.$2);
      countdownLabel.value = _formatDuration(next.$2.difference(now));
      heroStatus.value = 'Sholat berikutnya: ${next.$1}';
      return;
    }

    if (tomorrowRow != null) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowCandidates = _buildPrayerDateTimes(tomorrowRow, tomorrow);
      if (tomorrowCandidates.isNotEmpty) {
        final next = tomorrowCandidates.first;
        nextPrayerName.value = '${next.$1} (Besok)';
        nextPrayerTime.value = DateFormat('HH:mm').format(next.$2);
        countdownLabel.value = _formatDuration(next.$2.difference(now));
        heroStatus.value = 'Semua jadwal hari ini lewat. Berikutnya ${next.$1} besok.';
        return;
      }
    }

    nextPrayerName.value = 'Selesai';
    nextPrayerTime.value = '-';
    countdownLabel.value = '00:00:00';
    heroStatus.value = 'Semua jadwal hari ini sudah lewat.';
  }

  String _formatDuration(Duration diff) {
    if (diff.isNegative) {
      return '00:00:00';
    }
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  DateTime? _dateTimeForPrayer(DateTime date, String hhmm) {
    final match = RegExp(r'(\d{1,2})\s*:\s*(\d{2})').firstMatch(hhmm);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  List<(String, DateTime)> _buildPrayerDateTimes(
    PrayerDayScheduleModel row,
    DateTime date,
  ) {
    final ordered = <PrayerTimeModel>[
      PrayerTimeModel(name: 'Subuh', time: row.subuh),
      PrayerTimeModel(name: 'Dzuhur', time: row.dzuhur),
      PrayerTimeModel(name: 'Ashar', time: row.ashar),
      PrayerTimeModel(name: 'Maghrib', time: row.maghrib),
      PrayerTimeModel(name: 'Isya', time: row.isya),
    ];

    final result = <(String, DateTime)>[];
    for (final prayer in ordered) {
      final dt = _dateTimeForPrayer(date, prayer.time);
      if (dt != null) {
        result.add((prayer.name, dt));
      }
    }
    return result;
  }

  Future<void> _checkPrayerEntryAlert({bool force = false}) async {
    final day = activeDay.value;
    final city = selectedCity.value;
    if (day == null || city == null) {
      return;
    }

    final now = _nowForLocation();
    final nowMinute = (now.hour * 60) + now.minute;

    final settings = alertSettings.value;
    final events = <(String, String, String)>[
      (PrayerAlertEventKey.imsak, 'Imsak', day.imsak),
      (PrayerAlertEventKey.subuh, 'Subuh', day.subuh),
      (PrayerAlertEventKey.terbit, 'Terbit', day.terbit),
      (PrayerAlertEventKey.dzuhur, 'Dzuhur', day.dzuhur),
      (PrayerAlertEventKey.ashar, 'Ashar', day.ashar),
      (PrayerAlertEventKey.maghrib, 'Maghrib', day.maghrib),
      (PrayerAlertEventKey.isya, 'Isya', day.isya),
    ];

    for (final event in events) {
      final mode = settings.modeForEvent(event.$1);
      if (mode == PrayerAlertMode.off) {
        continue;
      }

      final targetMinute = _timeToMinute(event.$3);
      if (targetMinute == null) {
        continue;
      }

      final sameMinute = nowMinute == targetMinute;

      if (!sameMinute) {
        continue;
      }

      final province = selectedProvince.value ?? '-';
      final key =
          '${DateFormat('yyyy-MM-dd').format(now)}|$province|$city|${event.$2}|${event.$3}|${mode.storageValue}';

      if (!force && _storage.lastPrayerAlertKey == key) {
        return;
      }

      await _storage.setLastPrayerAlertKey(key);

      if (settings.notificationEnabled) {
        await _alertService.showPrayerNotification(
          'Waktu ${event.$2} telah masuk',
          '$city, $province (${timezoneLabel.value}) pukul ${event.$3}',
        );
      }

      if (mode == PrayerAlertMode.adzan && settings.adzanEnabled) {
        await _alertService.playAdzan();
      } else if (mode == PrayerAlertMode.alarm && settings.alarmEnabled) {
        await _alertService.playAlarm(
          useSystemSound: settings.useSystemAlarmSound,
        );
      }
      return;
    }
  }

  bool _restoreMonthlyScheduleFromCache() {
    final province = selectedProvince.value;
    final city = selectedCity.value;
    if (province == null || city == null) {
      return false;
    }

    final now = _nowForLocation();
    final cached = _storage.cachedSchedule;
    if (cached == null) {
      return false;
    }

    if (_normalize(_storage.cachedScheduleProvince) != _normalize(province) ||
        _normalize(_storage.cachedScheduleCity) != _normalize(city) ||
        _storage.cachedScheduleMonth != now.month ||
        _storage.cachedScheduleYear != now.year) {
      return false;
    }

    schedule.value = cached;
    activeDay.value =
        _pickRowForDate(cached.jadwal, now) ??
        (cached.jadwal.isNotEmpty ? cached.jadwal.first : null);
    _computeNextPrayer();
    unawaited(_syncWidgetAndNotificationData());
    return true;
  }

  Future<void> _syncWidgetAndNotificationData() async {
    final data = schedule.value;
    final city = selectedCity.value;
    final province = selectedProvince.value;
    if (data == null || city == null || province == null) {
      return;
    }

    await _widgetService.updateWidgets(
      city: city,
      province: province,
      todayLabel: todayLabel,
      timezone: timezoneLabel.value,
      nextPrayerName: nextPrayerName.value,
      nextPrayerTime: nextPrayerTime.value,
      day: activeDay.value,
    );

    await _alertService.scheduleMonthlyPrayerNotifications(
      schedule: data,
      province: province,
      city: city,
      timezoneName: _timezoneIanaName(),
      settings: alertSettings.value,
    );
  }

  void _loadAlertSettings() {
    alertSettings.value = _storage.prayerAlertSettings;
  }

  void _applyAlertSettings(PrayerAlertSettingsModel settings) {
    alertSettings.value = settings;
    unawaited(_storage.setPrayerAlertSettings(settings));
    unawaited(_syncWidgetAndNotificationData());
  }

  String _timezoneIanaName() {
    final offset = _timezoneOffsetForProvince(selectedProvince.value);
    if (offset.inHours == 9) {
      return 'Asia/Jayapura';
    }
    if (offset.inHours == 8) {
      return 'Asia/Makassar';
    }
    return 'Asia/Jakarta';
  }

  _NearestHintResult? _findNearestHintWithDistance(double lat, double lon) {
    _LocationHint? nearest;
    double nearestDistance = double.infinity;

    for (final hint in _locationHints) {
      final distance = Geolocator.distanceBetween(lat, lon, hint.lat, hint.lon);
      if (distance < nearestDistance) {
        nearest = hint;
        nearestDistance = distance;
      }
    }

    if (nearest == null) {
      return null;
    }

    return _NearestHintResult(hint: nearest, distanceMeters: nearestDistance);
  }

  String? _findBestMatch(
    List<String> values,
    List<String> candidates, {
    bool simplifyAdminWords = true,
  }) {
    if (values.isEmpty || candidates.isEmpty) {
      return null;
    }

    final normalizedValues = values
        .map(
          (value) => _NormalizedRegion(
            raw: value,
            normalized: _normalize(value),
            simplified: simplifyAdminWords
                ? _simplify(value)
                : _normalize(value),
          ),
        )
        .toList();

    final normalizedCandidates = candidates
        .where((item) => item.trim().isNotEmpty)
        .map(
          (value) => _NormalizedRegion(
            raw: value,
            normalized: _normalize(value),
            simplified: simplifyAdminWords
                ? _simplify(value)
                : _normalize(value),
          ),
        )
        .toList();

    for (final candidate in normalizedCandidates) {
      for (final value in normalizedValues) {
        if (value.normalized == candidate.normalized) {
          return value.raw;
        }
      }
    }

    for (final candidate in normalizedCandidates) {
      for (final value in normalizedValues) {
        if (value.normalized.contains(candidate.normalized) ||
            candidate.normalized.contains(value.normalized)) {
          return value.raw;
        }
      }
    }

    for (final candidate in normalizedCandidates) {
      for (final value in normalizedValues) {
        if (value.simplified == candidate.simplified ||
            value.simplified.contains(candidate.simplified) ||
            candidate.simplified.contains(value.simplified)) {
          return value.raw;
        }
      }
    }

    return null;
  }

  String _normalize(String text) {
    return text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _simplify(String text) {
    return _normalize(text)
        .replaceAll('PROVINSI', ' ')
        .replaceAll('DAERAH KHUSUS IBUKOTA', ' ')
        .replaceAll('KABUPATEN', ' ')
        .replaceAll('KOTA', ' ')
        .replaceAll('ADM', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _expandCityCandidates(List<String> candidates) {
    final expanded = <String>[];
    final seen = <String>{};
    for (final raw in candidates) {
      final clean = raw.trim();
      if (clean.isEmpty) {
        continue;
      }

      final base = clean;
      final kota = clean.toUpperCase().startsWith('KOTA ')
          ? clean
          : 'KOTA $clean';
      final kab = clean.toUpperCase().startsWith('KABUPATEN ')
          ? clean
          : 'KABUPATEN $clean';

      for (final value in <String>[base, kota, kab]) {
        final key = _normalize(value);
        if (seen.add(key)) {
          expanded.add(value);
        }
      }
    }
    return expanded;
  }
}

class _NormalizedRegion {
  _NormalizedRegion({
    required this.raw,
    required this.normalized,
    required this.simplified,
  });

  final String raw;
  final String normalized;
  final String simplified;
}

class _LocationHint {
  const _LocationHint({
    required this.lat,
    required this.lon,
    required this.province,
    required this.city,
  });

  final double lat;
  final double lon;
  final String province;
  final String city;
}

class _NearestHintResult {
  const _NearestHintResult({required this.hint, required this.distanceMeters});

  final _LocationHint hint;
  final double distanceMeters;
}

const List<String> _witaProvinceKeywords = <String>[
  'BALI',
  'NUSA TENGGARA BARAT',
  'NUSA TENGGARA TIMUR',
  'KALIMANTAN SELATAN',
  'KALIMANTAN TIMUR',
  'KALIMANTAN UTARA',
  'SULAWESI',
  'GORONTALO',
];

const List<String> _witProvinceKeywords = <String>['MALUKU', 'PAPUA'];

const List<_LocationHint> _locationHints = <_LocationHint>[
  _LocationHint(lat: 5.55, lon: 95.32, province: 'ACEH', city: 'BANDA ACEH'),
  _LocationHint(lat: 3.59, lon: 98.67, province: 'SUMATERA UTARA', city: 'MEDAN'),
  _LocationHint(lat: -0.95, lon: 100.35, province: 'SUMATERA BARAT', city: 'PADANG'),
  _LocationHint(lat: 0.53, lon: 101.45, province: 'RIAU', city: 'PEKANBARU'),
  _LocationHint(lat: 0.92, lon: 104.45, province: 'KEPULAUAN RIAU', city: 'TANJUNGPINANG'),
  _LocationHint(lat: -1.59, lon: 103.61, province: 'JAMBI', city: 'JAMBI'),
  _LocationHint(lat: -2.99, lon: 104.76, province: 'SUMATERA SELATAN', city: 'PALEMBANG'),
  _LocationHint(lat: -3.8, lon: 102.26, province: 'BENGKULU', city: 'BENGKULU'),
  _LocationHint(lat: -5.43, lon: 105.26, province: 'LAMPUNG', city: 'BANDAR LAMPUNG'),
  _LocationHint(lat: -2.13, lon: 106.11, province: 'KEPULAUAN BANGKA BELITUNG', city: 'PANGKALPINANG'),
  _LocationHint(lat: -6.2, lon: 106.85, province: 'DKI JAKARTA', city: 'JAKARTA PUSAT'),
  _LocationHint(lat: -6.18, lon: 106.63, province: 'BANTEN', city: 'TANGERANG'),
  _LocationHint(lat: -6.31, lon: 106.67, province: 'BANTEN', city: 'TANGERANG SELATAN'),
  _LocationHint(lat: -6.21, lon: 106.99, province: 'JAWA BARAT', city: 'KOTA BEKASI'),
  _LocationHint(lat: -6.26, lon: 107.14, province: 'JAWA BARAT', city: 'KABUPATEN BEKASI'),
  _LocationHint(lat: -6.91, lon: 107.61, province: 'JAWA BARAT', city: 'BANDUNG'),
  _LocationHint(lat: -6.97, lon: 110.42, province: 'JAWA TENGAH', city: 'SEMARANG'),
  _LocationHint(lat: -7.8, lon: 110.36, province: 'DI YOGYAKARTA', city: 'YOGYAKARTA'),
  _LocationHint(lat: -7.26, lon: 112.75, province: 'JAWA TIMUR', city: 'SURABAYA'),
  _LocationHint(lat: -8.65, lon: 115.22, province: 'BALI', city: 'DENPASAR'),
  _LocationHint(lat: -8.58, lon: 116.11, province: 'NUSA TENGGARA BARAT', city: 'MATARAM'),
  _LocationHint(lat: -10.18, lon: 123.61, province: 'NUSA TENGGARA TIMUR', city: 'KUPANG'),
  _LocationHint(lat: -0.02, lon: 109.34, province: 'KALIMANTAN BARAT', city: 'PONTIANAK'),
  _LocationHint(lat: -2.21, lon: 113.92, province: 'KALIMANTAN TENGAH', city: 'PALANGKARAYA'),
  _LocationHint(lat: -3.32, lon: 114.59, province: 'KALIMANTAN SELATAN', city: 'BANJARMASIN'),
  _LocationHint(lat: -0.5, lon: 117.15, province: 'KALIMANTAN TIMUR', city: 'SAMARINDA'),
  _LocationHint(lat: 1.49, lon: 124.84, province: 'SULAWESI UTARA', city: 'MANADO'),
  _LocationHint(lat: 0.54, lon: 123.06, province: 'GORONTALO', city: 'GORONTALO'),
  _LocationHint(lat: -0.89, lon: 119.87, province: 'SULAWESI TENGAH', city: 'PALU'),
  _LocationHint(lat: -2.68, lon: 118.89, province: 'SULAWESI BARAT', city: 'MAMUJU'),
  _LocationHint(lat: -5.14, lon: 119.41, province: 'SULAWESI SELATAN', city: 'MAKASSAR'),
  _LocationHint(lat: -3.99, lon: 122.52, province: 'SULAWESI TENGGARA', city: 'KENDARI'),
  _LocationHint(lat: -3.69, lon: 128.18, province: 'MALUKU', city: 'AMBON'),
  _LocationHint(lat: 0.78, lon: 127.37, province: 'MALUKU UTARA', city: 'TERNATE'),
  _LocationHint(lat: -0.86, lon: 134.08, province: 'PAPUA BARAT', city: 'MANOKWARI'),
  _LocationHint(lat: -2.53, lon: 140.71, province: 'PAPUA', city: 'JAYAPURA'),
];
