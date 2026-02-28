class PrayerTimeModel {
  const PrayerTimeModel({required this.name, required this.time});

  final String name;
  final String time;
}

class PrayerDayScheduleModel {
  const PrayerDayScheduleModel({
    required this.tanggal,
    required this.hari,
    required this.imsak,
    required this.subuh,
    required this.terbit,
    required this.dhuha,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  final String tanggal;
  final String hari;
  final String imsak;
  final String subuh;
  final String terbit;
  final String dhuha;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  factory PrayerDayScheduleModel.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] ?? '-').toString();
    return PrayerDayScheduleModel(
      tanggal: read('tanggal'),
      hari: read('hari'),
      imsak: read('imsak'),
      subuh: read('subuh'),
      terbit: read('terbit'),
      dhuha: read('dhuha'),
      dzuhur: read('dzuhur'),
      ashar: read('ashar'),
      maghrib: read('maghrib'),
      isya: read('isya'),
    );
  }

  List<PrayerTimeModel> toPrayerList() {
    return <PrayerTimeModel>[
      PrayerTimeModel(name: 'Imsak', time: imsak),
      PrayerTimeModel(name: 'Subuh', time: subuh),
      PrayerTimeModel(name: 'Terbit', time: terbit),
      PrayerTimeModel(name: 'Dhuha', time: dhuha),
      PrayerTimeModel(name: 'Dzuhur', time: dzuhur),
      PrayerTimeModel(name: 'Ashar', time: ashar),
      PrayerTimeModel(name: 'Maghrib', time: maghrib),
      PrayerTimeModel(name: 'Isya', time: isya),
    ];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'tanggal': tanggal,
      'hari': hari,
      'imsak': imsak,
      'subuh': subuh,
      'terbit': terbit,
      'dhuha': dhuha,
      'dzuhur': dzuhur,
      'ashar': ashar,
      'maghrib': maghrib,
      'isya': isya,
    };
  }
}

class MonthlyScheduleModel {
  const MonthlyScheduleModel({
    required this.provinsi,
    required this.kabkota,
    required this.bulanNama,
    required this.tahun,
    required this.jadwal,
  });

  final String provinsi;
  final String kabkota;
  final String bulanNama;
  final int tahun;
  final List<PrayerDayScheduleModel> jadwal;

  factory MonthlyScheduleModel.fromApi(Map<String, dynamic> payload) {
    final data =
        (payload['data'] as Map<String, dynamic>? ?? const <String, dynamic>{});
    final rows = (data['jadwal'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PrayerDayScheduleModel.fromJson)
        .toList();

    return MonthlyScheduleModel(
      provinsi: (data['provinsi'] ?? '').toString(),
      kabkota: (data['kabkota'] ?? '').toString(),
      bulanNama: (data['bulan_nama'] ?? '').toString(),
      tahun:
          int.tryParse((data['tahun'] ?? '').toString()) ?? DateTime.now().year,
      jadwal: rows,
    );
  }

  factory MonthlyScheduleModel.fromJson(Map<String, dynamic> json) {
    final rows = (json['jadwal'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PrayerDayScheduleModel.fromJson)
        .toList();
    return MonthlyScheduleModel(
      provinsi: (json['provinsi'] ?? '').toString(),
      kabkota: (json['kabkota'] ?? '').toString(),
      bulanNama: (json['bulan_nama'] ?? '').toString(),
      tahun:
          int.tryParse((json['tahun'] ?? '').toString()) ?? DateTime.now().year,
      jadwal: rows,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'provinsi': provinsi,
      'kabkota': kabkota,
      'bulan_nama': bulanNama,
      'tahun': tahun,
      'jadwal': jadwal.map((e) => e.toJson()).toList(),
    };
  }
}
