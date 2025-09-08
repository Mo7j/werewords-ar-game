import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models.dart';
import '../providers.dart';
import 'theme.dart';
import 'post_timer_screens.dart';

class QuestionTimerScreen extends ConsumerStatefulWidget {
  const QuestionTimerScreen({super.key});

  @override
  ConsumerState<QuestionTimerScreen> createState() =>
      _QuestionTimerScreenState();
}

class _QuestionTimerScreenState extends ConsumerState<QuestionTimerScreen> {
  final _noteCtrl = TextEditingController();

  // Limits
  static const _sharedYesNoLimit = 30; // shared for yes+no
  static const _maybeLimit = 15; // "غير معروف"
  static const _closeLimit = 1; // "قريب جدًا"

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

    final counts = {
      for (final a in Answer.values) a: log.where((e) => e.answer == a).length,
    };
    final yesNoTotal =
        (counts[Answer.yes] ?? 0) + (counts[Answer.no] ?? 0); // shared

    // When main round ends → branch based on found/not found
    if (!tState.running && tState.remaining == 0) {
      Future.microtask(() {
        if (!mounted) return;
        final found = ref.read(wordFoundProvider);
        if (found) {
          ref.read(phaseProvider.notifier).state = Phase.huntSeer;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HuntSeerTimerScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        } else {
          ref.read(phaseProvider.notifier).state = Phase.findWerewolf;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const FindWerewolfTimerScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ),
          );
        }
      });
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
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
                _TimerRing(
                  progress: tState.progress,
                  seconds: tState.remaining,
                  running: tState.running,
                ),
                const SizedBox(height: 16),

                _AnswerPad(
                  counts: counts,
                  yesNoTotal: yesNoTotal,
                  yesNoMax: _sharedYesNoLimit,
                  maybeMax: _maybeLimit,
                  closeMax: _closeLimit,
                  onTap: (Answer a) {
                    // Enforce limits
                    if (a == Answer.yes || a == Answer.no) {
                      if (yesNoTotal >= _sharedYesNoLimit) {
                        HapticFeedback.heavyImpact();
                        _toast(context, 'بلغت حد نعم/لا (٣٠ معًا)');
                        return;
                      }
                    } else if (a == Answer.maybe) {
                      if ((counts[a] ?? 0) >= _maybeLimit) {
                        HapticFeedback.heavyImpact();
                        _toast(context, 'بلغت حد غير معروف: $_maybeLimit');
                        return;
                      }
                    } else if (a == Answer.unknown) {
                      if ((counts[a] ?? 0) >= _closeLimit) {
                        HapticFeedback.heavyImpact();
                        _toast(
                            context, 'يمكن اختيار "قريب جدًا" مرة واحدة فقط');
                        return;
                      }
                    }

                    final note = _noteCtrl.text;
                    ref.read(qaLogProvider.notifier).add(a, note: note);
                    _noteCtrl.clear();
                    HapticFeedback.mediumImpact();
                  },
                ),
                const SizedBox(height: 12),

                const _LastAnswerBadge(),

                const Spacer(),

                // Only "found the word" button (big)
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
                      ref.read(wordFoundProvider.notifier).state = true;
                      ref.read(phaseProvider.notifier).state = Phase.huntSeer;
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const HuntSeerTimerScreen(),
                          transitionsBuilder: (_, a, __, c) =>
                              FadeTransition(opacity: a, child: c),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 28),
                    label: const Text('تم العثور على الكلمة',
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

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        content: Text(msg),
        duration: const Duration(milliseconds: 1100),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final double progress; // 0..1
  final int seconds;
  final bool running;
  const _TimerRing(
      {required this.progress, required this.seconds, required this.running});

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
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

    canvas.drawCircle(center, radius, bg);
    final sweep = 2 * math.pi * progress;
    final start = -math.pi / 2;
    final rectArc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rectArc, start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _AnswerPad extends StatelessWidget {
  final void Function(Answer) onTap;
  final Map<Answer, int> counts;
  final int yesNoTotal, yesNoMax, maybeMax, closeMax;
  const _AnswerPad({
    required this.onTap,
    required this.counts,
    required this.yesNoTotal,
    required this.yesNoMax,
    required this.maybeMax,
    required this.closeMax,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Answer.yes, 'نعم', Icons.check_rounded),
      (Answer.no, 'لا', Icons.close_rounded),
      (Answer.maybe, 'غير معروف', FontAwesomeIcons.question), // plain '?'
      (Answer.unknown, 'قريب جدًا', Icons.priority_high_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisExtent: 76,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        final (ans, label, icon) = items[i];

        int usedDisplay, maxDisplay;
        bool disabled;

        if (ans == Answer.yes || ans == Answer.no) {
          usedDisplay = yesNoTotal;
          maxDisplay = yesNoMax;
          disabled = yesNoTotal >= yesNoMax;
        } else if (ans == Answer.maybe) {
          usedDisplay = counts[ans] ?? 0;
          maxDisplay = maybeMax;
          disabled = usedDisplay >= maxDisplay;
        } else {
          usedDisplay = counts[ans] ?? 0;
          maxDisplay = closeMax;
          disabled = usedDisplay >= maxDisplay;
        }

        return _AnswerButton(
          ans: ans,
          label: label,
          icon: icon,
          used: usedDisplay,
          max: maxDisplay,
          disabled: disabled,
          onTap: onTap,
          ratioOverride: (ans == Answer.yes || ans == Answer.no)
              ? (yesNoTotal / yesNoMax).clamp(0.0, 1.0)
              : null,
        );
      },
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final Answer ans;
  final String label;
  final IconData icon;
  final int used, max;
  final bool disabled;
  final double? ratioOverride;
  final void Function(Answer) onTap;

  const _AnswerButton({
    required this.ans,
    required this.label,
    required this.icon,
    required this.used,
    required this.max,
    required this.disabled,
    required this.onTap,
    this.ratioOverride,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (ratioOverride ?? (used / max)).clamp(0.0, 1.0);

    return AnimatedOpacity(
      duration: 200.ms,
      opacity: disabled ? 0.38 : 1.0,
      child: InkWell(
        onTap: disabled ? null : () => onTap(ans),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: glassCard(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: 220.ms,
                  curve: Curves.easeOut,
                  child: FractionallySizedBox(
                    widthFactor: ratio == 0 ? 0 : ratio,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.accent.withOpacity(.18),
                            AppColors.accent2.withOpacity(.14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 28,
                      color: disabled ? Colors.white54 : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: disabled ? Colors.white54 : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$used / $max',
                      style: TextStyle(
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: disabled ? Colors.white54 : Colors.white70,
                      ),
                    ),
                  ],
                ).animate().scale(duration: 120.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastAnswerBadge extends ConsumerWidget {
  const _LastAnswerBadge({super.key});

  String _ansText(Answer a) {
    switch (a) {
      case Answer.yes:
        return 'نعم';
      case Answer.no:
        return 'لا';
      case Answer.maybe:
        return 'غير معروف';
      case Answer.unknown:
        return 'قريب جدًا';
    }
  }

  IconData _ansIcon(Answer a) {
    switch (a) {
      case Answer.yes:
        return Icons.check_rounded;
      case Answer.no:
        return Icons.close_rounded;
      case Answer.maybe:
        return FontAwesomeIcons.question;
      case Answer.unknown:
        return Icons.priority_high_rounded;
    }
  }

  Color _accent(Answer a) {
    switch (a) {
      case Answer.yes:
        return Colors.greenAccent;
      case Answer.no:
        return Colors.redAccent;
      case Answer.maybe:
        return Colors.amberAccent;
      case Answer.unknown:
        return Colors.cyanAccent;
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

    final acc = _accent(last.answer);

    return Container(
      decoration: glassCard(18),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: acc.withOpacity(.30), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: acc.withOpacity(.15),
                  blurRadius: 14,
                  spreadRadius: 1.5,
                ),
              ],
            ),
            child: Icon(_ansIcon(last.answer), size: 30),
          ).animate().scale(duration: 280.ms, curve: Curves.easeOutBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ansText(last.answer),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (last.note != null && last.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    last.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).moveY(begin: 8, end: 0);
  }
}
