# Jadwal Sholat App

A Flutter application for daily Indonesian prayer schedules (jadwal sholat and imsakiyah) with location-based data, reminders, and Android home widgets.

## Features

- Daily prayer and imsak schedule display
- Province and city filtering for Indonesia
- Auto location detection from device GPS
- Next prayer highlight with live countdown
- Monthly schedule fetch and refresh
- Reminder settings per prayer time
- Notification, adzan, and alarm modes
- Android home widgets (compact and detailed)
- Onboarding flow for first-time users

## Tech Stack

- Flutter (Dart 3)
- GetX for state management and routing
- HTTP for API requests
- SharedPreferences for local persistence
- flutter_local_notifications + timezone for scheduling
- audioplayers + flutter_ringtone_player for sound playback
- home_widget for Android widget integration

## Getting Started

### Requirements

- Flutter SDK 3.11.0 or later
- Dart SDK (included with Flutter)
- Android Studio or VS Code with Flutter extension
- Android SDK for Android builds

### Install and Run

```bash
flutter pub get
flutter run
```

## Project Structure

```text
lib/
  app/
    data/         # models and services
    modules/      # onboarding and home modules
    routes/       # app routes/pages
    theme/        # app colors and theme
```

## Important Note

This repository is provided for portfolio purposes only. Usage rights are restricted by the custom license in [LICENSE](LICENSE).

## License

Copyright (c) 2026 bayu5aputra. All rights reserved.

See the [LICENSE](LICENSE) file for full terms.