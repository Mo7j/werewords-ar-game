import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import 'setup_screen.dart';
import 'theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // After first frame: prewarm the words, but DO NOT wait for them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger loading (if it fails or is slow, we still navigate).
      // Don't listen / await; RoleReveal will handle the word if needed.
      ref.read(wordRepoProvider);

      // Always navigate after a short delay.
      Future.delayed(const Duration(milliseconds: 900), _goNextSafely);
    });
  }

  void _goNextSafely() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SetupScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) {
            final t = _bgCtrl.value;
            return Stack(
              children: [
                // Subtle animated radial gradient background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.35 - 0.7 * t, -0.1 + 0.3 * t),
                        radius: 1.2,
                        colors: [
                          AppColors.accent.withOpacity(0.12),
                          AppColors.accent2.withOpacity(0.08),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Centerpiece
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withOpacity(.24),
                              AppColors.accent2.withOpacity(.18),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(.20),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, size: 54),
                      ).animate().fadeIn(duration: 500.ms).scale(
                          begin: const Offset(.9, .9),
                          end: const Offset(1, 1),
                          duration: 500.ms),
                      const SizedBox(height: 18),
                      const Text(
                        'جارٍ التحضير…',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700),
                      ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(.10),
                            color: AppColors.accent,
                          ),
                        ),
                      ).animate().fadeIn(delay: 220.ms, duration: 400.ms),
                    ],
                  ),
                ),

                // Small signature "7j"
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.55,
                    child: Text(
                      '7j',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(.8),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
