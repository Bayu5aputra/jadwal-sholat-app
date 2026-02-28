import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prayer_schedule_model.dart';

class PrayerApiService {
  PrayerApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _base = 'https://equran.id/api/v2/shalat';
  static const _openMeteo = 'https://geocoding-api.open-meteo.com/v1/reverse';

  Future<List<String>> getProvinces() async {
    final uri = Uri.parse('$_base/provinsi');
    final response = await _client.get(uri);

    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (payload['data'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    return data;
  }

  Future<List<String>> getCities(String province) async {
    final uri = Uri.parse('$_base/kabkota');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'provinsi': province}),
    );

    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (payload['data'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    return data;
  }

  Future<MonthlyScheduleModel> getMonthlySchedule({
    required String province,
    required String city,
    required int month,
    required int year,
  }) async {
    final uri = Uri.parse(_base);
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'provinsi': province,
        'kabkota': city,
        'bulan': month,
        'tahun': year,
      }),
    );

    _ensureSuccess(response);

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return MonthlyScheduleModel.fromApi(payload);
  }

  Future<GeoLocationCandidates> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final openMeteoUri = Uri.parse(
      '$_openMeteo?latitude=$latitude&longitude=$longitude&language=id&count=1',
    );

    try {
      final response = await _client.get(openMeteoUri);
      _ensureSuccess(response);
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (payload['results'] as List<dynamic>? ?? const []);
      final first = results.isNotEmpty ? results.first : null;
      if (first is Map<String, dynamic>) {
        return GeoLocationCandidates(
          provinceCandidates: [
            (first['admin1'] ?? '').toString(),
            (first['country'] ?? '').toString(),
          ],
          cityCandidates: [
            (first['admin2'] ?? '').toString(),
            (first['name'] ?? '').toString(),
          ],
        );
      }
    } catch (_) {}

    final bdcUris = [
      Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=id',
      ),
      Uri.parse(
        'https://api-bdc.io/data/reverse-geocode-client?latitude=$latitude&longitude=$longitude&localityLanguage=id',
      ),
    ];

    for (final uri in bdcUris) {
      try {
        final response = await _client.get(uri);
        _ensureSuccess(response);
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        return GeoLocationCandidates(
          provinceCandidates: [
            (payload['principalSubdivision'] ?? '').toString(),
            (payload['localityInfo']?['administrative']?[1]?['name'] ?? '')
                .toString(),
          ],
          cityCandidates: [
            (payload['city'] ?? '').toString(),
            (payload['locality'] ?? '').toString(),
          ],
        );
      } catch (_) {}
    }

    throw PrayerApiException('Reverse geocode gagal.');
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw PrayerApiException('API error ${response.statusCode}');
  }
}

class PrayerApiException implements Exception {
  PrayerApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeoLocationCandidates {
  GeoLocationCandidates({
    required List<String> provinceCandidates,
    required List<String> cityCandidates,
  }) : provinceCandidates = provinceCandidates
           .where((e) => e.trim().isNotEmpty)
           .toList(),
       cityCandidates = cityCandidates
           .where((e) => e.trim().isNotEmpty)
           .toList();

  final List<String> provinceCandidates;
  final List<String> cityCandidates;
}
