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
  final bool includeSeer;
  final int roundSeconds;
  final Difficulty difficulty;

  const GameConfig({
    required this.playerCount,
    required this.includeSeer,
    required this.roundSeconds,
    required this.difficulty,
  });

  GameConfig copyWith({
    int? playerCount,
    bool? includeSeer,
    int? roundSeconds,
    Difficulty? difficulty,
  }) {
    return GameConfig(
      playerCount: playerCount ?? this.playerCount,
      includeSeer: includeSeer ?? this.includeSeer,
      roundSeconds: roundSeconds ?? this.roundSeconds,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  static const defaultConfig = GameConfig(
    playerCount: 5,
    includeSeer: true,
    roundSeconds: 300,
    difficulty: Difficulty.easy,
  );
}

enum Phase { setup, roleReveal, questionTimer, finalGuess, results, findWerewolf, huntSeer }

class RolePool {
  static List<Role> forConfig(GameConfig cfg) {
    final roles = <Role>[Role.mayor, Role.werewolf];
    if (cfg.includeSeer) roles.add(Role.seer);
    while (roles.length < cfg.playerCount) {
      roles.add(Role.villager);
    }
    return roles;
  }
}
