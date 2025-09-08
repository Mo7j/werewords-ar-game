import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'dart:async';

final wordFoundProvider = StateProvider<bool>((ref) => false);

class GameConfigNotifier extends StateNotifier<GameConfig> {
  GameConfigNotifier() : super(GameConfig.defaultConfig);

  void setPlayerCount(int v) => state = state.copyWith(playerCount: v);
  void setRoundSeconds(int v) => state = state.copyWith(roundSeconds: v);
  void setDifficulty(Difficulty d) => state = state.copyWith(difficulty: d);
  void setPostDiscussionSeconds(int v) =>
      state = state.copyWith(postDiscussionSeconds: v);
}

final gameConfigProvider =
    StateNotifierProvider<GameConfigNotifier, GameConfig>((ref) {
  return GameConfigNotifier();
});

class WordRepository {
  final Map<String, List<String>> _words;
  WordRepository(this._words);
  List<String> byDifficulty(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return _words['easy'] ?? const [];
      case Difficulty.medium:
        return _words['medium'] ?? const [];
      case Difficulty.hard:
        return _words['hard'] ?? const [];
    }
  }
}

final wordRepoProvider = FutureProvider<WordRepository>((ref) async {
  final raw = await rootBundle.loadString('assets/words/ar_words.json');
  final data = json.decode(raw) as Map<String, dynamic>;
  return WordRepository(
    data.map((k, v) => MapEntry(k, (v as List).cast<String>())),
  );
});

final phaseProvider = StateProvider<Phase>((ref) => Phase.setup);
final secretWordProvider = StateProvider<String?>((ref) => null);
final assignedRolesProvider = StateProvider<List<Role>>((ref) => const []);

final _rng = Random();

void pickSecretWord(WidgetRef ref) {
  final repo = ref.read(wordRepoProvider).maybeWhen(
        data: (w) => w,
        orElse: () => null,
      );
  final diff = ref.read(gameConfigProvider).difficulty;
  if (repo == null) return;
  final list = repo.byDifficulty(diff);
  if (list.isEmpty) return;
  ref.read(secretWordProvider.notifier).state = list[_rng.nextInt(list.length)];
}

void assignRoles(WidgetRef ref) {
  final cfg = ref.read(gameConfigProvider);
  final roles = RolePool.forConfig(cfg)..shuffle(_rng);
  ref.read(assignedRolesProvider.notifier).state = roles;
}

// ===== Q&A log =====
class QaLogNotifier extends StateNotifier<List<QaEntry>> {
  QaLogNotifier() : super(const []);
  void add(Answer a, {String? note}) {
    state = [
      ...state,
      QaEntry(
        answer: a,
        note: note?.trim().isEmpty == true ? null : note,
        at: DateTime.now(),
      ),
    ];
  }

  void clear() => state = const [];
}

final qaLogProvider =
    StateNotifierProvider<QaLogNotifier, List<QaEntry>>((ref) {
  return QaLogNotifier();
});

// ===== Timer =====
class TimerState {
  final int totalSeconds;
  final int remaining;
  final bool running;
  const TimerState({
    required this.totalSeconds,
    required this.remaining,
    required this.running,
  });

  double get progress => totalSeconds == 0 ? 0 : remaining / totalSeconds;

  TimerState copyWith({int? totalSeconds, int? remaining, bool? running}) =>
      TimerState(
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remaining: remaining ?? this.remaining,
        running: running ?? this.running,
      );
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _ticker;
  TimerNotifier(int initial)
      : super(TimerState(
            totalSeconds: initial, remaining: initial, running: false));

  void _tickStart() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remaining <= 1) {
        _ticker?.cancel();
        state = state.copyWith(remaining: 0, running: false);
      } else {
        state = state.copyWith(remaining: state.remaining - 1);
      }
    });
  }

  void start() {
    _ticker?.cancel();
    state = state.copyWith(remaining: state.totalSeconds, running: true);
    _tickStart();
  }

  void pause() {
    _ticker?.cancel();
    state = state.copyWith(running: false);
  }

  void resume() {
    if (state.running || state.remaining <= 0) return;
    state = state.copyWith(running: true);
    _tickStart();
  }

  void resetTo(int seconds) {
    _ticker?.cancel();
    state =
        TimerState(totalSeconds: seconds, remaining: seconds, running: false);
  }

  void startWith(int seconds) {
    _ticker?.cancel();
    state =
        TimerState(totalSeconds: seconds, remaining: seconds, running: true);
    _tickStart();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  final seconds = ref.read(gameConfigProvider).roundSeconds;
  return TimerNotifier(seconds);
});

void initRound(WidgetRef ref) {
  ref.read(qaLogProvider.notifier).clear();
  ref.read(wordFoundProvider.notifier).state = false;
  final secs = ref.read(gameConfigProvider).roundSeconds;
  ref.read(timerProvider.notifier).resetTo(secs);
}
