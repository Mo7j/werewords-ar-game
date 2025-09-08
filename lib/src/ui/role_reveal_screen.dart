import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'question_timer_screen.dart';
import 'theme.dart';

class RoleRevealScreen extends ConsumerStatefulWidget {
  const RoleRevealScreen({super.key});
  @override
  ConsumerState<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends ConsumerState<RoleRevealScreen> {
  int index = 0; // which player is revealing now
  bool revealed = false;
  List<bool>? _locked; // lock per player after "تم"

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(assignedRolesProvider);
    final cfg = ref.watch(gameConfigProvider);

    // Initialize locks once with the number of roles
    _locked ??= List<bool>.filled(roles.length, false);
    final isLocked = _locked![index];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg, // static dark background
        appBar: AppBar(
          title: const Text('توزيع الأدوار'),
          backgroundColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _stepHeader(context, cfg, isLocked: isLocked),
              const SizedBox(height: 16),
              Expanded(child: _roleCard(context, roles, isLocked: isLocked)),
              const SizedBox(height: 16),
              _controls(context, roles),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(BuildContext context, GameConfig cfg,
      {required bool isLocked}) {
    final statusText = isLocked ? 'مقفول' : (revealed ? 'مكشوف' : 'مخفى');
    return Container(
      decoration: glassCard(20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Text('اللاعب ${index + 1} / ${cfg.playerCount}',
              style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          const Icon(Icons.remove_red_eye_rounded),
          const SizedBox(width: 8),
          Text(statusText),
        ],
      ),
    ).animate().fadeIn().moveY(begin: -8, end: 0);
  }

  /// Role-tinted colors for the static background gradient
  List<Color> _glowFor(Role role) {
    switch (role) {
      case Role.werewolf:
        // bloody reds
        return [
          Colors.red.shade800.withOpacity(.18), // edge color (stronger)
          Colors.red.shade400.withOpacity(.12), // inner tint (softer)
        ];
      case Role.seer:
        // mystical purples
        return [
          Colors.deepPurpleAccent.withOpacity(.18),
          Colors.purpleAccent.withOpacity(.12),
        ];
      case Role.mayor:
        // golden yellows
        return [
          Colors.amber.shade400.withOpacity(.18),
          Colors.orange.shade200.withOpacity(.12),
        ];
      case Role.villager:
        // natural greens
        return [
          Colors.green.shade700.withOpacity(.18),
          Colors.lightGreenAccent.withOpacity(.12),
        ];
    }
  }

  Widget _roleCard(BuildContext context, List<Role> roles,
      {required bool isLocked}) {
    final role = roles[index];
    final radius = BorderRadius.circular(28);

    // Which roles can see the secret word?
    final canSeeWord =
        role == Role.mayor || role == Role.werewolf || role == Role.seer;

    // Ensure a secret word exists when showing the card revealed for peek roles
    String? secret;
    if (revealed && !isLocked && canSeeWord) {
      secret = ref.read(secretWordProvider);
      if (secret == null) {
        pickSecretWord(ref);
        secret = ref.read(secretWordProvider);
      }
    }

    return GestureDetector(
      onTap: isLocked ? null : () => setState(() => revealed = !revealed),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOut,
        decoration: glassCard(28),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Static smooth gradient: colored corners fading into the middle.
              // (Center is transparent, edges slightly tinted by role colors.)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: (revealed && !isLocked) ? 1.0 : 0.0,
                  duration: 300.ms,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.transparent, // center
                          _glowFor(role)[0], // edges/corners color
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: 250.ms,
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: (revealed && !isLocked)
                        ? _roleContent(role, secret: canSeeWord ? secret : null)
                        : Column(
                            key: const ValueKey('hidden'),
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.touch_app_rounded, size: 56),
                              SizedBox(height: 12),
                              Text('اضغط لعرض دورك'),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleContent(Role role, {String? secret}) {
    final title = switch (role) {
      Role.mayor => 'العمدة',
      Role.werewolf => 'المستذئب',
      Role.seer => 'العرّاف/ة',
      Role.villager => 'قروي',
    };
    final emoji = switch (role) {
      Role.mayor => '👑',
      Role.werewolf => '🐺',
      Role.seer => '🔮',
      Role.villager => '🏡',
    };

    return Column(
      key: const ValueKey('revealed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        neonDivider(),
        const SizedBox(height: 12),

        // Inline secret word (no extra card) for roles that can see it
        if (secret != null) ...[
          const SizedBox(height: 6),
          const Text(
            'الكلمة السرّية:',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            secret,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          neonDivider(),
          const SizedBox(height: 10),
        ],

        Text(
          _roleHint(role),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.3),
        ),
      ],
    );
  }

  String _roleHint(Role r) {
    switch (r) {
      case Role.mayor:
        return 'ستنظر إلى الكلمة السرّية وتُجيب بنعم/لا/ربما/لا أعرف.';
      case Role.werewolf:
        return 'أنت تعرف الكلمة. حاول تضليل الآخرين دون أن تُكشف!';
      case Role.seer:
        return 'أنت تعرف الكلمة. ساعد الفريق لكن تجنّب كشف نفسك.';
      case Role.villager:
        return 'لا تعرف الكلمة. اسأل أسئلة ذكية للوصول إليها.';
    }
  }

  Widget _controls(BuildContext context, List<Role> roles) {
    final isLast = index == roles.length - 1;
    final isLocked = _locked?[index] == true;

    // If this is the last player and he already pressed "تم" → show only Start button
    if (isLast && isLocked) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 22),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          onPressed: () {
            ref.read(phaseProvider.notifier).state = Phase.questionTimer;
            if (mounted) {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const QuestionTimerScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
              );
            }
          },
          child: const Text('ابدأ الجولة'),
        ),
      ).animate().fadeIn().moveY(begin: 8, end: 0);
    }

    // Otherwise show the two equal-sized buttons
    return Row(
      children: [
        // إخفاء — same fixed height as the next button
        Expanded(
          child: SizedBox(
            height: 60,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: (revealed && !isLocked)
                  ? () => setState(() => revealed = false)
                  : null,
              child: const Text('إخفاء'),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // اللاعب التالي / تم — same fixed height, accent color
        Expanded(
          child: SizedBox(
            height: 60,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              onPressed: (revealed && !isLocked)
                  ? () async {
                      if (isLast) {
                        // LAST PLAYER: lock & hide permanently
                        setState(() {
                          _locked![index] = true;
                          revealed = false;
                        });
                        // After this, UI changes to the single Start button above
                      } else {
                        // NOT LAST: go to next player
                        if (mounted) {
                          setState(() {
                            index += 1;
                            revealed = false;
                          });
                        }
                      }
                    }
                  : null,
              child: Text(isLast ? 'تم' : 'اللاعب التالي'),
            ),
          ),
        ),
      ],
    ).animate().fadeIn().moveY(begin: 8, end: 0);
  }
}
