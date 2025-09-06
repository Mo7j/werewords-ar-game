import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'theme.dart';
import 'results_screen.dart';
import 'post_timer_screens.dart';


class QuestionTimerScreen extends ConsumerStatefulWidget {
  const QuestionTimerScreen({super.key});

  @override
  ConsumerState<QuestionTimerScreen> createState() => _QuestionTimerScreenState();
}

class _QuestionTimerScreenState extends ConsumerState<QuestionTimerScreen> {
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initRound(ref);
      ref.read(timerProvider.notifier).start();
    });
  }
  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tState = ref.watch(timerProvider);
    final log = ref.watch(qaLogProvider);

    // Navigate to results when time hits zero (one-time)
    if (!tState.running && tState.remaining == 0) {
      Future.microtask(() {
        if (mounted) {
          // Time’s up → Find the Werewolf discussion timer
          ref.read(phaseProvider.notifier).state = Phase.findWerewolf;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const FindWerewolfTimerScreen(),
              transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
            ),
          );
        }
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الجولة'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: tState.running ? 'إيقاف مؤقت' : 'استئناف',
              onPressed: () {
                HapticFeedback.selectionClick();
                if (tState.running) {
                  ref.read(timerProvider.notifier).pause();
                } else {
                  ref.read(timerProvider.notifier).resume();
                }
              },
              icon: Icon(tState.running ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            const _AnimatedTimerBackground(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TimerRing(
                    progress: tState.progress,
                    seconds: tState.remaining,
                    running: tState.running,
                  ),
                  const SizedBox(height: 16),
                  _NoteInput(ctrl: _noteCtrl),
                  const SizedBox(height: 12),
                  _AnswerPad(onTap: (Answer a) {
                    final note = _noteCtrl.text;
                    ref.read(qaLogProvider.notifier).add(a, note: note);
                    _noteCtrl.clear();
                    HapticFeedback.mediumImpact();
                  }),
                  const SizedBox(height: 12),
                  _LastAnswerBadge(),   // <-- NEW pretty badge
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            // Mark as found and go to Werewolf hunts Seer
                            ref.read(wordFoundProvider.notifier).state = true;
                            ref.read(phaseProvider.notifier).state = Phase.huntSeer;
                            Navigator.of(context).pushReplacement(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const HuntSeerTimerScreen(),
                                transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('تم العثور على الكلمة'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(timerProvider.notifier).start(); // restart and clear
                            ref.read(qaLogProvider.notifier).clear();
                          },
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('إعادة المؤقّت'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final double progress; // 0..1
  final int seconds;
  final bool running;
  const _TimerRing({required this.progress, required this.seconds, required this.running});

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
    }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassCard(28),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _RingPainter(progress: progress),
              child: Center(
                child: Text(
                  _fmt(seconds),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ).animate(target: seconds.toDouble()).scale(duration: 300.ms),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              running ? 'اسألوا بسرعة قبل انتهاء الوقت!' : 'مُوقّف',
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
    final stroke = 8.0;
    final rect = Offset.zero & size;

    final bg = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final fg = Paint()
      ..shader = const LinearGradient(colors: [AppColors.accent, AppColors.accent2])
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

class _NoteInput extends StatelessWidget {
  final TextEditingController ctrl;
  const _NoteInput({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: glassCard(18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'ملاحظة قصيرة (اختياري)…',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          IconButton(
            tooltip: 'مسح',
            onPressed: () => ctrl.clear(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _AnswerPad extends StatelessWidget {
  final void Function(Answer) onTap;
  const _AnswerPad({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Answer.yes, 'نعم', Icons.check_circle_rounded),
      (Answer.no, 'لا', Icons.cancel_rounded),
      (Answer.maybe, 'ربما', Icons.help_rounded),
      (Answer.unknown, 'لا أعرف', Icons.question_mark_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisExtent: 64, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (_, i) {
        final (ans, label, icon) = items[i];
        return _AnswerButton(ans: ans, label: label, icon: icon, onTap: onTap);
      },
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final Answer ans;
  final String label;
  final IconData icon;
  final void Function(Answer) onTap;
  const _AnswerButton({required this.ans, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(ans),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: glassCard(14),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ).animate().scale(duration: 120.ms),
        ),
      ),
    );
  }
}

class _LogList extends StatelessWidget {
  final List<QaEntry> entries;
  const _LogList({required this.entries});

  String _ansText(Answer a) {
    switch (a) {
      case Answer.yes: return 'نعم';
      case Answer.no: return 'لا';
      case Answer.maybe: return 'ربما';
      case Answer.unknown: return 'لا أعرف';
    }
  }

  IconData _ansIcon(Answer a) {
    switch (a) {
      case Answer.yes: return Icons.check_circle_rounded;
      case Answer.no: return Icons.cancel_rounded;
      case Answer.maybe: return Icons.help_rounded;
      case Answer.unknown: return Icons.question_mark_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('لا يوجد سجّل بعد — استخدم الأزرار أعلاه لتسجيل الإجابات.'),
      );
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = entries[i];
        return Container(
          decoration: glassCard(14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(_ansIcon(e.answer)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(e.note ?? _ansText(e.answer),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.at.hour.toString().padLeft(2, '0')}:${e.at.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms).moveY(begin: 8, end: 0);
      },
    );
  }
}
class _LastAnswerBadge extends ConsumerWidget {
  const _LastAnswerBadge({super.key});

  String _ansText(Answer a) {
    switch (a) {
      case Answer.yes: return 'نعم';
      case Answer.no: return 'لا';
      case Answer.maybe: return 'ربما';
      case Answer.unknown: return 'لا أعرف';
    }
  }

  IconData _ansIcon(Answer a) {
    switch (a) {
      case Answer.yes: return Icons.check_circle_rounded;
      case Answer.no: return Icons.cancel_rounded;
      case Answer.maybe: return Icons.help_rounded;
      case Answer.unknown: return Icons.question_mark_rounded;
    }
  }

  Color _glow(Answer a) {
    switch (a) {
      case Answer.yes: return Colors.greenAccent;
      case Answer.no: return Colors.redAccent;
      case Answer.maybe: return Colors.amberAccent;
      case Answer.unknown: return Colors.cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(qaLogProvider);
    final last = entries.isEmpty ? null : entries.last;

    if (last == null) {
      return Container(
        decoration: glassCard(18),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: const Center(
          child: Text('آخر إجابة ستظهر هنا…'),
        ),
      ).animate().fadeIn(duration: 200.ms).moveY(begin: 8, end: 0);
    }

    final glow = _glow(last.answer);

    return Container(
      decoration: glassCard(22),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon with neon pulse ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: glow.withOpacity(0.45), blurRadius: 24, spreadRadius: 2),
                    BoxShadow(color: glow.withOpacity(0.20), blurRadius: 36, spreadRadius: 8),
                  ],
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              Icon(_ansIcon(last.answer), size: 36),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_ansText(last.answer),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (last.note != null && last.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(last.note!, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).moveY(begin: 8, end: 0);
  }
}
class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmText;
  final VoidCallback onConfirm;
  const _ConfirmDialog({required this.title, required this.message, required this.confirmText, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('رجوع')),
        FilledButton(onPressed: onConfirm, child: Text(confirmText)),
      ],
    );
  }
}

class _AnimatedTimerBackground extends StatefulWidget {
  const _AnimatedTimerBackground();
  @override
  State<_AnimatedTimerBackground> createState() => _AnimatedTimerBackgroundState();
}

class _AnimatedTimerBackgroundState extends State<_AnimatedTimerBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
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
              center: Alignment(0.4 - 0.8 * t, 0.2 - 0.4 * t),
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
