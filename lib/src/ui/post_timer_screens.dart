import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';
import 'results_screen.dart';

class DiscussionTimerScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final int seconds;
  final VoidCallback? onDone;

  const DiscussionTimerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.seconds = 60,
    this.onDone,
  });

  @override
  State<DiscussionTimerScreen> createState() => _DiscussionTimerScreenState();
}

class _DiscussionTimerScreenState extends State<DiscussionTimerScreen> {
  late int remaining;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    remaining = widget.seconds;
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remaining <= 1) {
        _t?.cancel();
        setState(() => remaining = 0);
        widget.onDone?.call();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const ResultsScreen(),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            ),
          );
        }
      } else {
        setState(() => remaining -= 1);
      }
    });
  }

  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.transparent),
        body: Stack(
          children: [
            const _GradBG(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: glassCard(24),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text(widget.subtitle, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        _BigRing(seconds: remaining),
                      ],
                    ),
                  ).animate().fadeIn().moveY(begin: -8, end: 0),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      _t?.cancel();
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const ResultsScreen(),
                          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('تم — انتقل للنتائج'),
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

class _GradBG extends StatefulWidget { const _GradBG(); @override State<_GradBG> createState() => _GradBGState(); }
class _GradBGState extends State<_GradBG> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.2 - 0.4 * t, -0.2 + 0.3 * t),
              radius: 1.2,
              colors: [
                AppColors.accent.withOpacity(0.12),
                AppColors.accent2.withOpacity(0.08),
                Colors.black,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BigRing extends StatelessWidget {
  final int seconds;
  const _BigRing({required this.seconds});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(160, 160),
      painter: _RingPainter(seconds / 60.0), // simple 60s max visual; purely aesthetic
      child: Center(
        child: Text(
          _fmt(seconds),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1 (just for look)
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - stroke;

    final bg = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final fg = Paint()
      ..shader = const LinearGradient(colors: [AppColors.accent, AppColors.accent2]).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi/2, progress * 2 * math.pi, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

// Convenience subclasses

class FindWerewolfTimerScreen extends DiscussionTimerScreen {
  const FindWerewolfTimerScreen({super.key})
      : super(
          title: 'نقاش: من هو المستذئب؟',
          subtitle: 'انتهى الوقت ولم تُكتشف الكلمة. لديكم دقيقة لتحديد المستذئب.',
          seconds: 60,
        );
}

class HuntSeerTimerScreen extends DiscussionTimerScreen {
  const HuntSeerTimerScreen({super.key})
      : super(
          title: 'دور المستذئب: اكتشف العرّاف/ة',
          subtitle: 'أحسنتم! عثرتم على الكلمة. الآن أمام المستذئب 30 ثانية ليخمن العرّاف/ة.',
          seconds: 30,
        );
}
