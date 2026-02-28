import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/onboarding_item_model.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';

class OnboardingController extends GetxController {
  final currentPage = 0.obs;

  late final PageController pageController;

  final items = const <OnboardingItemModel>[
    OnboardingItemModel(
      title: 'Quality Jadwal',
      description:
          'Jadwal imsak dan sholat harian yang rapi, cepat, dan nyaman dibaca seperti versi web Anda.',
      icon: Icons.restaurant_menu_rounded,
      blobColor: AppColors.softBlue,
      circleColor: Color(0xFF7AB6F9),
    ),
    OnboardingItemModel(
      title: 'Fast Reminder',
      description:
          'Tampilkan waktu berikutnya dan sisa hitung mundur agar Anda tidak terlambat menunaikan sholat.',
      icon: Icons.delivery_dining_rounded,
      blobColor: AppColors.softCream,
      circleColor: Color(0xFFD9B485),
    ),
    OnboardingItemModel(
      title: 'Reward Focus',
      description:
          'Pilih lokasi favorit, pantau jadwal bulanan, lalu mulai ibadah harian dengan alur yang sederhana.',
      icon: Icons.redeem_rounded,
      blobColor: Color(0xFFDCEBFF),
      circleColor: Color(0xFF9FC5FA),
    ),
  ];

  bool get isLastPage => currentPage.value == items.length - 1;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int value) {
    currentPage.value = value;
  }

  Future<void> nextOrFinish() async {
    if (isLastPage) {
      await _finishOnboarding();
      return;
    }

    await pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> skip() => _finishOnboarding();

  Future<void> _finishOnboarding() async {
    final storage = Get.find<LocalStorageService>();
    await storage.setHasSeenOnboarding(true);
    Get.offAllNamed(Routes.home);
  }
}
