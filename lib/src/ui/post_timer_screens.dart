import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'theme.dart';
import 'results_screen.dart';

/// ===============================
/// Shared big, pulsing timer card
/// ===============================
class _BigPulsingTimerCard extends StatelessWidget {
  final double progress; // 0..1
  final int seconds;
  final bool running;
  final String message;
  const _BigPulsingTimerCard({
    required this.progress,
    required this.seconds,
    required this.running,
    required this.message,
  });

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Pulsation tiers
    final p60 = running && seconds <= 60;
    final p30 = running && seconds < 30;
    final p15 = running && seconds <= 15;

    double scaleEnd = 1.0, blurEnd = 0.0;
    Duration dur = 900.ms;

    if (p60) {
      scaleEnd = 1.02;
      blurEnd = 0.4;
      dur = 800.ms;
    }
    if (p30) {
      scaleEnd = 1.04;
      blurEnd = 0.8;
      dur = 650.ms;
    }
    if (p15) {
      scaleEnd = 1.08;
      blurEnd = 1.4;
      dur = 500.ms;
    }

    Widget ring = SizedBox(
      width: 160,
      height: 160,
      child: CustomPaint(
        painter: _RingPainter(progress: progress),
        child: Center(
          child: Text(
            _fmt(seconds),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ).animate(target: seconds.toDouble()).scale(duration: 300.ms),
        ),
      ),
    );

    if (p60) {
      ring = ring
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(end: Offset(scaleEnd, scaleEnd), duration: dur)
          .then()
          .blurXY(end: blurEnd, duration: dur);
    }

    return Container(
      decoration: glassCard(32),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      child: Row(
        children: [
          ring,
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(),
          ),
        ],
      ),
    ).animate().fadeIn().moveY(begin: -8, end: 0);
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final rect = Offset.zero & size;

    final bg = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..shader =
          const LinearGradient(colors: [AppColors.accent, AppColors.accent2])
              .createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - stroke;

    // background circle
    canvas.drawCircle(center, radius, bg);

    // progress arc
    final sweep = 2 * math.pi * progress;
    final start = -math.pi / 2; // top
    final rectArc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rectArc, start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

/// =======================================
/// Find Werewolf Discussion Timer Screen
/// =======================================
class FindWerewolfTimerScreen extends ConsumerStatefulWidget {
  const FindWerewolfTimerScreen({super.key});
  @override
  ConsumerState<FindWerewolfTimerScreen> createState() =>
      _FindWerewolfTimerScreenState();
}

class _FindWerewolfTimerScreenState
    extends ConsumerState<FindWerewolfTimerScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cfg = ref.read(gameConfigProvider);
        ref.read(timerProvider.notifier).startWith(cfg.postDiscussionSeconds);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tState = ref.watch(timerProvider);
    final finished = !tState.running && tState.remaining == 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('نقاش اكتشاف المستذئب'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: tState.running ? 'إيقاف مؤقت' : 'استئناف',
              onPressed: () {
                HapticFeedback.selectionClick();
                if (tState.running) {
                  ref.read(timerProvider.notifier).pause();
                } else {
                  if (!finished) ref.read(timerProvider.notifier).resume();
                }
              },
              icon: Icon(
                tState.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Opacity(
                  opacity: finished ? 0.35 : 1.0,
                  child: _BigPulsingTimerCard(
                    progress: tState.progress,
                    seconds: tState.remaining,
                    running: tState.running,
                    message: tState.running
                        ? 'ناقشوا وحددوا من هو المستذئب!'
                        : (finished ? 'انتهى الوقت' : 'مُوقّف'),
                  ),
                ),
                const SizedBox(height: 16),

                if (finished)
                  Container(
                    decoration: glassCard(18),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_off_rounded),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('انتهى الوقت! اضغطوا لعرض النتائج.'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            ref.read(phaseProvider.notifier).state =
                                Phase.results;
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const ResultsScreen(),
                                transitionsBuilder: (_, a, __, c) =>
                                    FadeTransition(opacity: a, child: c),
                              ),
                            );
                          },
                          child: const Text('عرض النتائج'),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Manual finish if they finish early
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      ref.read(phaseProvider.notifier).state = Phase.results;
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const ResultsScreen(),
                          transitionsBuilder: (_, a, __, c) =>
                              FadeTransition(opacity: a, child: c),
                        ),
                      );
                    },
                    icon: const Icon(Icons.how_to_vote_rounded, size: 28),
                    label: const Text('تمّ التصويت',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =======================================
/// Hunt Seer Timer Screen
/// =======================================
class HuntSeerTimerScreen extends ConsumerStatefulWidget {
  const HuntSeerTimerScreen({super.key});
  @override
  ConsumerState<HuntSeerTimerScreen> createState() =>
      _HuntSeerTimerScreenState();
}

class _HuntSeerTimerScreenState extends ConsumerState<HuntSeerTimerScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cfg = ref.read(gameConfigProvider);
        ref.read(timerProvider.notifier).startWith(cfg.postDiscussionSeconds);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tState = ref.watch(timerProvider);
    final finished = !tState.running && tState.remaining == 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('مطاردة العرّاف/ة'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: tState.running ? 'إيقاف مؤقت' : 'استئناف',
              onPressed: () {
                HapticFeedback.selectionClick();
                if (tState.running) {
                  ref.read(timerProvider.notifier).pause();
                } else {
                  if (!finished) ref.read(timerProvider.notifier).resume();
                }
              },
              icon: Icon(
                tState.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Opacity(
                  opacity: finished ? 0.35 : 1.0,
                  child: _BigPulsingTimerCard(
                    progress: tState.progress,
                    seconds: tState.remaining,
                    running: tState.running,
                    message: tState.running
                        ? 'المستذئب يحاول تحديد العرّاف/ة…'
                        : (finished ? 'انتهى الوقت' : 'مُوقّف'),
                  ),
                ),
                const SizedBox(height: 16),
                if (finished)
                  Container(
                    decoration: glassCard(18),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_off_rounded),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('انتهى الوقت! اضغطوا لعرض النتائج.'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            ref.read(phaseProvider.notifier).state =
                                Phase.results;
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const ResultsScreen(),
                                transitionsBuilder: (_, a, __, c) =>
                                    FadeTransition(opacity: a, child: c),
                              ),
                            );
                          },
                          child: const Text('عرض النتائج'),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      ref.read(phaseProvider.notifier).state = Phase.results;
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const ResultsScreen(),
                          transitionsBuilder: (_, a, __, c) =>
                              FadeTransition(opacity: a, child: c),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 28),
                    label: const Text('تمّ التصويت',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
