import 'package:get/get.dart';

import '../../../data/services/prayer_alert_service.dart';
import '../../../data/services/prayer_widget_service.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrayerAlertService>(PrayerAlertService.new);
    Get.lazyPut<PrayerWidgetService>(PrayerWidgetService.new);
    Get.lazyPut<HomeController>(HomeController.new);
  }
}
