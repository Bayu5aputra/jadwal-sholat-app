import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/data/services/local_storage_service.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);
  Get.put<LocalStorageService>(storage, permanent: true);

  final initialRoute = storage.hasSeenOnboarding
      ? Routes.home
      : Routes.onboarding;

  runApp(JadwalSholatApp(initialRoute: initialRoute));
}
