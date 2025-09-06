import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'theme.dart';
import 'role_reveal_screen.dart';

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(gameConfigProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إعداد اللعبة'),
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            // subtle animated gradient background
            const _AnimatedBackground(),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _glassCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('عدد اللاعبين', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: cfg.playerCount.toDouble(),
                              min: 3,
                              max: 10,
                              divisions: 7,
                              label: '${cfg.playerCount}',
                              onChanged: (v) => ref
                                  .read(gameConfigProvider.notifier)
                                  .setPlayerCount(v.round()),
                            ),
                          ),
                          SizedBox(width: 56, child: Center(child: Text('${cfg.playerCount}'))),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 50.ms).moveY(begin: 12, end: 0),
                const SizedBox(height: 12),
                _glassCard(
                  context,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تشغيل دور العرّاف/ة'),
                    value: cfg.includeSeer,
                    onChanged: (v) => ref.read(gameConfigProvider.notifier).toggleSeer(v),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).moveY(begin: 12, end: 0),
                const SizedBox(height: 12),
                _glassCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('المدة', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [180, 240, 300, 360].map((sec) => _TimeChip(sec)).toList(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 150.ms).moveY(begin: 12, end: 0),
                const SizedBox(height: 12),
                _glassCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('الصعوبة', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: Difficulty.values.map((d) {
                          final selected = cfg.difficulty == d;
                          return ChoiceChip(
                            label: Text(_labelFor(d)),
                            selected: selected,
                            onSelected: (_) => ref.read(gameConfigProvider.notifier).setDifficulty(d),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms).moveY(begin: 12, end: 0),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('ابدأ'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    assignRoles(ref);
                    pickSecretWord(ref);
                    ref.read(phaseProvider.notifier).state = Phase.roleReveal;
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const RoleRevealScreen(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  },
                ).animate().scale(duration: 250.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _labelFor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'سهل';
      case Difficulty.medium:
        return 'متوسط';
      case Difficulty.hard:
        return 'صعب';
    }
  }

  Widget _glassCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: glassCard(),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _TimeChip extends ConsumerWidget {
  final int seconds;
  const _TimeChip(this.seconds, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(gameConfigProvider);
    final selected = cfg.roundSeconds == seconds;
    return ChoiceChip(
      label: Text(_fmt(seconds)),
      selected: selected,
      onSelected: (_) => ref.read(gameConfigProvider.notifier).setRoundSeconds(seconds),
    );
  }

  String _fmt(int s) {
    final m = (s / 60).floor();
    final r = s % 60;
    return r == 0 ? '${m}د' : '${m}د ${r}ث';
  }
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.2 - t * 0.4, -0.2 + t * 0.4),
              radius: 1.2,
              colors: [
                AppColors.accent.withOpacity(0.12),
                AppColors.accent2.withOpacity(0.08),
                Colors.black,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
