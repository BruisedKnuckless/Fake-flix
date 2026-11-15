# FakeFlix for iOS

A standalone iPhone app built with Flutter and Dart. It uses the same TMDB and streaming setup as the website (see the `website` branch).

This app is intended for personal use only and not for commercial purposes. Made by Viraj & Claude.

## What it does

- Home, TV Shows, Movies, New & Hot and category pages, with search
- Title pages with cast, seasons, episodes and similar titles
- A full-screen player with Next Episode
- Optional profiles saved on the device: My List, likes, watch history and Continue Watching. Guests can watch; nothing is saved for them.

## Run it in the iOS Simulator

```bash
flutter pub get
```

```bash
open -a Simulator
```

```bash
flutter run
```

## Run it on your own iPhone

Installing on a real phone needs your Apple ID for code signing.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target, then **Signing & Capabilities**.
3. Tick **Automatically manage signing** and pick your Apple ID under **Team**.
4. If Xcode says the bundle identifier is taken, change `com.viraj24a8.fakeflix` to something unique.
5. Plug in the iPhone, choose it as the run destination, and press Run.
6. On the phone, trust the developer profile under **Settings > General > VPN & Device Management**.

With a free Apple ID the app stops opening after 7 days and has to be installed again from Xcode.

### The app must be a release build

A debug build only opens while Xcode or `flutter run` is attached. Opened from the home screen it shows a black screen saying "debug mode Flutter apps can only be launched from Flutter tooling".

Xcode's Run button in this project is set to build **Release**, so an app installed that way opens normally. From the terminal, the same thing is:

```bash
flutter run --release
```

Because of that setting, running on a **simulator** from Xcode fails (Flutter has no release mode for simulators). Use `flutter run` for the simulator instead.

## Where things are

| Path | What is in it |
|---|---|
| `lib/config.dart` | Streaming embed address and TMDB key |
| `lib/data/` | TMDB client, data classes, the row and category tables |
| `lib/state/profile_store.dart` | Profiles and everything saved on them |
| `lib/screens/` | One file per screen |
| `lib/widgets/` | Shared pieces: posters, billboard, header, tab bar |
| `test/` | Unit tests for the profile store and episode logic |

## Checks

```bash
flutter analyze
```

```bash
flutter test
```

This product uses the TMDB API but is not endorsed or certified by TMDB.
