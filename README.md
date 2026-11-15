# FakeFlix for Android

A standalone Android app built with Flutter and Dart. Same UI, features and code as the iPhone app (see the `ios` branch), and the same TMDB and streaming setup as the website (see the `website` branch).

This app is intended for personal use only and not for commercial purposes. Made by Viraj & Claude.

## What it does

- Home, TV Shows, Movies, New & Hot and category pages, with search
- Title pages with cast, seasons, episodes and similar titles
- A full-screen landscape player with Next Episode, with the provider's ads and pop-ups blocked
- Optional profiles saved on the device: My List, likes, watch history and Continue Watching. Guests can watch; nothing is saved for them.

## Put it on a phone

Build the installable file:

```bash
flutter build apk --release
```

It is written to `build/app/outputs/flutter-apk/app-release.apk`. Copy that file to the phone and open it; Android will ask you to allow installing from that source the first time.

With the phone plugged in by USB (USB debugging on), this builds and installs in one step:

```bash
flutter install --release
```

The APK is signed with the default debug key. That is fine for your own phones, but the Play Store would need a real signing key.

## Run it on the emulator

```bash
flutter emulators --launch Medium_Phone_API_37.0
```

```bash
flutter run
```

## Where things are

| Path | What is in it |
|---|---|
| `lib/config.dart` | Streaming embed address and TMDB key |
| `lib/data/` | TMDB client, data classes, the row and category tables |
| `lib/state/profile_store.dart` | Profiles and everything saved on them |
| `lib/screens/` | One file per screen; `player_screen.dart` also holds the ad blocking |
| `lib/widgets/` | Shared pieces: posters, billboard, header, tab bar |
| `android/` | The Android project: app name, icon, permissions |
| `test/` | Unit tests for the profile store, episode logic and the ad filter |

## Notes

- `android/gradle.properties` turns off one Android Gradle Plugin 9 check (`android.r8.proguardAndroidTxt.disallowed`) because the `flutter_inappwebview` plugin still uses the older setting. Remove it once the plugin is updated.
- `lib/` is the same code as the iPhone app plus the Android request filter in `player_screen.dart`, so it runs on both.

## Checks

```bash
flutter analyze
```

```bash
flutter test
```

This product uses the TMDB API but is not endorsed or certified by TMDB.
