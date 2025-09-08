import 'package:flutter/foundation.dart';

enum Difficulty { easy, medium, hard }

enum Role { mayor, werewolf, seer, villager }

enum Answer { yes, no, maybe, unknown }

class QaEntry {
  final String? note;
  final Answer answer;
  final DateTime at;
  const QaEntry({required this.answer, this.note, required this.at});
}

@immutable
class GameConfig {
  final int playerCount;
  final int roundSeconds;
  final Difficulty difficulty;

  /// Unified post-round discussion timer (used for both Find Werewolf & Hunt Seer)
  final int postDiscussionSeconds;

  const GameConfig({
    required this.playerCount,
    required this.roundSeconds,
    required this.difficulty,
    this.postDiscussionSeconds = 30,
  });

  GameConfig copyWith({
    int? playerCount,
    int? roundSeconds,
    Difficulty? difficulty,
    int? postDiscussionSeconds,
  }) {
    return GameConfig(
      playerCount: playerCount ?? this.playerCount,
      roundSeconds: roundSeconds ?? this.roundSeconds,
      difficulty: difficulty ?? this.difficulty,
      postDiscussionSeconds:
          postDiscussionSeconds ?? this.postDiscussionSeconds,
    );
  }

  static const defaultConfig = GameConfig(
    playerCount: 5,
    roundSeconds: 300,
    difficulty: Difficulty.easy,
    postDiscussionSeconds: 30,
  );
}

enum Phase {
  setup,
  roleReveal,
  questionTimer,
  finalGuess,
  results,
  findWerewolf,
  huntSeer
}

class RolePool {
  /// Distribution:
  /// 4–6:  1 Mayor, 1 Seer, 1 Werewolf, rest Villagers
  /// 7–11: 1 Mayor, 1 Seer, 2 Werewolves, rest Villagers
  /// 12+:  1 Mayor, 1 Seer, 3 Werewolves, rest Villagers
  /// (For 3 players, we naturally get Mayor+Seer+Werewolf.)
  static List<Role> forConfig(GameConfig cfg) {
    final n = cfg.playerCount;
    final roles = <Role>[
      Role.mayor,
      Role.seer,
    ];

    final werewolves = n >= 12 ? 3 : (n >= 7 ? 2 : 1);
    roles.addAll(List<Role>.filled(werewolves, Role.werewolf));

    while (roles.length < n) {
      roles.add(Role.villager);
    }
    return roles;
  }
}
