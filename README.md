# Jadwal Sholat App

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-1f2937)](#)
[![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-111827)](LICENSE)

A modern Flutter app to check Indonesian prayer schedules (jadwal sholat and imsakiyah), track the next prayer countdown, and manage reminders with adzan/alarm options.

![Jadwal Sholat App Logo](assets/images/logo-app.png)

## Why This App

- Fast access to daily and monthly prayer schedules
- Smart location-based experience for Indonesian regions
- Practical reminder controls for each prayer time
- Home screen widgets for quick glance information

## Main Features

- Daily prayer times: Imsak, Subuh, Terbit, Dhuha, Dzuhur, Ashar, Maghrib, Isya
- Province and city filtering across Indonesia
- GPS-based auto-location on app start
- Next prayer card with real-time countdown
- Reminder settings per event (off, notification, adzan, alarm)
- Monthly notification scheduling with timezone support
- Android home widgets (compact and detailed)
- Onboarding flow for first-time users

## Tech Stack

- Flutter + Dart 3
- GetX (state management, dependency injection, routing)
- HTTP (API integration)
- SharedPreferences (local storage)
- flutter_local_notifications + timezone (scheduled alerts)
- audioplayers + flutter_ringtone_player (audio playback)
- home_widget (Android widget integration)

## Project Structure

```text
lib/
  app/
    data/
      models/
      services/
    modules/
      home/
      onboarding/
    routes/
    theme/
  main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK 3.11.0+
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code with Flutter extension
- Android SDK (for Android build/deploy)

### Installation

```bash
flutter pub get
```

### Run

```bash
flutter run
```

### Build Release

```bash
flutter build apk --release
```

## Usage Flow

1. Open the app and complete onboarding (first launch only).
2. Allow location access for automatic province/city selection.
3. Review daily schedule and next prayer countdown.
4. Open reminder settings to configure per-prayer alert mode.
5. Add Android widget for quick home screen access.

## Notes

- This project is intended for personal portfolio showcase.
- Code usage is restricted by the custom license.

## License

Copyright (c) 2026 bayu5aputra. All Rights Reserved.

This project was created for personal portfolio purposes.

You may not copy, modify, distribute, or use any part of the source code or documentation without the owner's prior written permission.

Contact: https://github.com/bayu5aputra • bayusaputra.005.003@gmail.com

See full terms in [LICENSE](LICENSE).
