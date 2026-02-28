import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_settings_view.dart';
import '../modules/home/views/home_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: Routes.onboarding,
      page: OnboardingView.new,
      binding: OnboardingBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.home,
      page: HomeView.new,
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: Routes.settings,
      page: HomeSettingsView.new,
    ),
  ];
}
