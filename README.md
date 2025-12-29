# Werewords AR

Small Arabic helper app for playing Werewords. Pick a word, share roles, run the timer, and track answers in one place.

## What this app does
- Arabic-first UI with right-to-left layout
- Role reveal flow for Mayor, Seer, Werewolf, Villagers
- Word picker by difficulty (easy / medium / hard)
- Round timer with quick yes/no/maybe logging
- Post-round timers for Find Werewolf / Hunt Seer
- Simple dark theme with glassy cards

## Tech
- Flutter 3.x + Dart 3.x
- Riverpod for state
- google_fonts and flutter_animate for polish
- Assets: `assets/words/ar_words.json`

## Run it
1) Install Flutter (3.5+ recommended).
2) Get packages: `flutter pub get`
3) Run on a device/emulator: `flutter run`

## Build
- Android: `flutter build apk`
- iOS (on macOS): `flutter build ios`
- Web: `flutter build web`

## Tests
- Unit/widget tests: `flutter test`

## Project layout
- `lib/main.dart` bootstraps the app and theme
- `lib/src/models.dart` data models and enums
- `lib/src/providers.dart` state and helpers (words, timers, roles)
- `lib/src/ui/` screens (splash, setup, role reveal, timers, results) and theme
- `assets/words/` Arabic word lists by difficulty
- `pubspec.yaml` dependencies and assets setup
