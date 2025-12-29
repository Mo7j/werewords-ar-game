# Werewords AR
Small Arabic App for playing Werewords. Pick a word, share roles, run the timer, and track answers in one place.

<video width="600" controls>
  <source src="assets/video/Demo.mp4" type="video/mp4">
</video>

Try it out:
- Web: [https://werewords-ar.netlify.app/](https://werewords-ar.netlify.app/)
- IOS: Download the apk!
  
## What this app does
- Arabic-first UI with right-to-left layout
- Role reveal flow for Mayor, Seer, Werewolf, Villagers
- Word picker by difficulty (easy / medium / hard)
- Round timer with quick yes/no/maybe logging
- Post-round timers for Find Werewolf / Hunt Seer
- Simple dark theme with glassy cards

## How the game works
1) Setup: pick number of players and word difficulty; the app assigns Mayor, Seer, Werewolf, and Villagers.
2) Role reveal: each player privately views their role in turn.
3) Secret word: the Mayor draws a word; the Seer can peek; the Werewolf stays in the dark.
4) Guessing round: start the main timer; Mayor answers with yes / no / maybe while the app logs answers.
5) After the timer: run the quick Find Werewolf timer; if the Werewolf is caught, run the Hunt Seer timer.
6) Reset and start a new round with fresh roles/word.

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
