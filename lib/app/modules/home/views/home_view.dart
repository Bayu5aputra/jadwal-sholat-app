import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFFFF7D6),
              Color(0xFFF8F3E8),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(
            () => RefreshIndicator(
              onRefresh: controller.refreshLocationFromPull,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: controller.showSkeleton
                    ? _buildSkeletonSlivers()
                    : _buildContentSlivers(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers(BuildContext context) {
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _BrutalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Jadwal Sholat & Imsakiyah Indonesia',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Cek waktu sholat harian, pilih provinsi dan kabupaten/kota, lalu tampilkan jadwal bulanan.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _BrutalCard(
            child: _FilterForm(controller: controller),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _SettingsShortcutCard(controller: controller),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _HeroPrayerCard(controller: controller),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _BrutalCard(
            child: Obx(() {
              final error = controller.errorMessage.value;
              final style = Theme.of(context).textTheme.bodyLarge;
              return Text(
                error == null || error.isEmpty ? controller.resultMeta : error,
                style: style?.copyWith(
                  color: error == null || error.isEmpty
                      ? AppColors.textPrimary
                      : const Color(0xFF9A241B),
                ),
              );
            }),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: Obx(() {
          final prayers = controller.prayerList;
          if (prayers.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          return SliverList.separated(
            itemCount: prayers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final prayer = prayers[index];
              return _PrayerTile(name: prayer.name, time: prayer.time);
            },
          );
        }),
      ),
    ];
  }

  List<Widget> _buildSkeletonSlivers() {
    return <Widget>[
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _SkeletonCard(height: 140),
        ),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _SkeletonCard(height: 320),
        ),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverToBoxAdapter(
          child: _SkeletonCard(height: 190),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverList.separated(
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, _) => const _SkeletonCard(height: 72),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }
}

class _FilterForm extends StatelessWidget {
  const _FilterForm({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final inputStyle = Theme.of(context).textTheme.bodyMedium;

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Pilih Lokasi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>(
              'province-${controller.selectedProvince.value}',
            ),
            initialValue: controller.selectedProvince.value,
            style: inputStyle,
            decoration: _fieldDecoration('Provinsi'),
            items: controller.provinces
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: controller.isLoadingProvince.value
                ? null
                : (value) {
                    if (value != null) {
                      controller.changeProvince(value);
                    }
                  },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>('city-${controller.selectedCity.value}'),
            initialValue: controller.selectedCity.value,
            style: inputStyle,
            decoration: _fieldDecoration('Kabupaten/Kota'),
            items: controller.cities
                .map(
                  (item) =>
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                )
                .toList(),
            onChanged: controller.isLoadingCity.value
                ? null
                : (value) {
                    if (value != null) {
                      controller.changeCity(value);
                    }
                  },
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey<String>(
                    'month-${controller.selectedMonth.value}',
                  ),
                  initialValue: controller.selectedMonth.value,
                  style: inputStyle,
                  decoration: _fieldDecoration('Bulan'),
                  items: List<int>.generate(12, (index) => index + 1)
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item,
                          child: Text('$item'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeMonth(value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey<String>(
                    'year-${controller.selectedYear.value}',
                  ),
                  initialValue: controller.selectedYear.value,
                  style: inputStyle,
                  decoration: _fieldDecoration('Tahun'),
                  items: controller.yearOptions
                      .map(
                        (item) => DropdownMenuItem<int>(
                          value: item,
                          child: Text('$item'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeYear(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Lokasi akan dipakai otomatis dari GPS saat app dibuka. Tarik layar ke bawah untuk refresh lokasi.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: _ActionButton(
                label: controller.isLoadingSchedule.value
                    ? 'MEMUAT...'
                    : 'TAMPILKAN JADWAL',
                onTap: controller.isLoadingSchedule.value
                    ? null
                    : controller.fetchSchedule,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.black, width: 2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.black, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.accentDark, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

class _SettingsShortcutCard extends StatelessWidget {
  const _SettingsShortcutCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final settings = controller.alertSettings.value;
      final countEnabled = controller.configurableAlertEvents
          .where((event) => controller.eventAlertMode(event.key).name != 'off')
          .length;

      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Get.toNamed(Routes.settings),
        child: _BrutalCard(
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.black),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.accentDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Settings Pengingat',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${settings.notificationEnabled ? 'Notif aktif' : 'Notif mati'} • $countEnabled waktu diatur',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      );
    });
  }
}

class _HeroPrayerCard extends StatelessWidget {
  const _HeroPrayerCard({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.prayerCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.black, width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              controller.selectedCity.value ?? 'Lokasi belum dipilih',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              controller.todayLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFC8D5F5)),
            ),
            const SizedBox(height: 12),
            Text(
              controller.heroStatus.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${controller.nextPrayerName.value} | ${controller.nextPrayerTime.value}',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFFF6F9FF)),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(Icons.timer_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  controller.countdownLabel.value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Jam sekarang ${controller.nowClock.value}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFD9E0F2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  const _PrayerTile({required this.name, required this.time});

  final String name;
  final String time;

  @override
  Widget build(BuildContext context) {
    return _BrutalCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.black),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: AppColors.accentDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(onPressed: onTap, child: Text(label)),
    );
  }
}

class _BrutalCard extends StatelessWidget {
  const _BrutalCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
        ],
      ),
      child: child,
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 180,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFECECEC),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
