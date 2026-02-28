import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/prayer_alert_settings_model.dart';
import '../../../theme/app_colors.dart';
import '../controllers/home_controller.dart';

class HomeSettingsView extends GetView<HomeController> {
  const HomeSettingsView({super.key});

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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              _NeoHeader(
                title: 'Settings Pengingat',
                subtitle: 'Notifikasi, adzan, alarm, dan mode per waktu.',
                onBack: Get.back,
              ),
              const SizedBox(height: 10),
              _BrutalCard(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Global Toggle',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aktifkan Notifikasi'),
                        value: controller.alertSettings.value.notificationEnabled,
                        onChanged: controller.setNotificationEnabled,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aktifkan Adzan'),
                        value: controller.alertSettings.value.adzanEnabled,
                        onChanged: controller.setAdzanEnabled,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aktifkan Alarm'),
                        value: controller.alertSettings.value.alarmEnabled,
                        onChanged: controller.setAlarmEnabled,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gunakan suara alarm bawaan perangkat'),
                        subtitle: const Text(
                          'Saat aktif, alarm mengikuti nada alarm default smartphone.',
                        ),
                        value: controller.alertSettings.value.useSystemAlarmSound,
                        onChanged: controller.setUseSystemAlarmSound,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _ActionButton(
                              label: 'TEST ADZAN',
                              icon: Icons.music_note_rounded,
                              onTap: controller.testAdzanSound,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActionButton(
                              label: 'TEST ALARM',
                              icon: Icons.alarm_rounded,
                              onTap: controller.testAlarmSound,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _BrutalCard(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Mode Per Waktu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pilih mode untuk tiap waktu sholat, imsak, dan terbit.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final event in controller.configurableAlertEvents) ...<
                        Widget
                      >[
                        const Divider(height: 12),
                        const SizedBox(height: 6),
                        Text(
                          event.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<PrayerAlertMode>(
                          initialValue: controller.eventAlertMode(event.key),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.black,
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.accentDark,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: PrayerAlertMode.values
                              .map(
                                (mode) => DropdownMenuItem<PrayerAlertMode>(
                                  value: mode,
                                  child: Text(mode.label),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.setEventAlertMode(event.key, value);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoHeader extends StatelessWidget {
  const _NeoHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _BrutalCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.black),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
