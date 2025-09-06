import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'question_timer_screen.dart';
import 'word_peek_sheet.dart';
import 'theme.dart';

class RoleRevealScreen extends ConsumerStatefulWidget {
  const RoleRevealScreen({super.key});
  @override
  ConsumerState<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends ConsumerState<RoleRevealScreen> {
  int index = 0; // which player is revealing now
  bool revealed = false;

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(assignedRolesProvider);
    final cfg = ref.watch(gameConfigProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('توزيع الأدوار'),
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            const _AnimatedRevealBackground(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _stepHeader(context, cfg),
                  const SizedBox(height: 16),
                  Expanded(child: _roleCard(context, roles)),
                  const SizedBox(height: 16),
                  _controls(context, roles),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepHeader(BuildContext context, GameConfig cfg) {
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
          Text(revealed ? 'مكشوف' : 'مخفى'),
        ],
      ),
    ).animate().fadeIn().moveY(begin: -8, end: 0);
  }

  Widget _roleCard(BuildContext context, List<Role> roles) {
    final role = roles[index];

    return GestureDetector(
      onTap: () => setState(() => revealed = !revealed),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOut,
        decoration: glassCard(28).copyWith(
          gradient: LinearGradient(
            colors: revealed
                ? [
                    AppColors.accent.withOpacity(0.18),
                    AppColors.accent2.withOpacity(0.18)
                  ]
                : [
                    Colors.white.withOpacity(0.02),
                    Colors.white.withOpacity(0.02)
                  ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: AnimatedSwitcher(
            duration: 250.ms,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: revealed
                ? _roleContent(role)
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
    );
  }

  Widget _roleContent(Role role) {
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
        Text(title,
            style:
                const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        neonDivider(),
        const SizedBox(height: 12),
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

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: revealed ? () => setState(() => revealed = false) : null,
            child: const Text('إخفاء'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: revealed
            ? () async {
                final role = roles[index];
                final isPeekRole =
                    role == Role.mayor || role == Role.werewolf || role == Role.seer;

                // Ensure a secret word exists
                var word = ref.read(secretWordProvider);
                if (word == null) {
                  pickSecretWord(ref);
                  word = ref.read(secretWordProvider);
                }

                // Show the secret word if this role should see it
                if (isPeekRole && word != null) {
                  final roleLabel = switch (role) {
                    Role.mayor => 'العمدة',
                    Role.werewolf => 'المستذئب',
                    Role.seer => 'العرّاف/ة',
                    Role.villager => 'قروي',
                  };
                  await showWordPeekSheet(context,
                      roleLabel: roleLabel, secret: word);
                }

                final isLast = index == roles.length - 1;
                if (isLast) {
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
                } else {
                  if (mounted) {
                    setState(() {
                      index += 1;
                      revealed = false;
                    });
                  }
                }
              }
            : null,
            child: Text(isLast ? 'ابدأ الجولة' : 'اللاعب التالي'),
          ),
        ),
      ],
    ).animate().fadeIn().moveY(begin: 8, end: 0);
  }
}

class _AnimatedRevealBackground extends StatefulWidget {
  const _AnimatedRevealBackground();
  @override
  State<_AnimatedRevealBackground> createState() =>
      _AnimatedRevealBackgroundState();
}

class _AnimatedRevealBackgroundState extends State<_AnimatedRevealBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t, -1),
              end: Alignment(1 - t, 1),
              colors: [
                AppColors.accent.withOpacity(0.10),
                Colors.transparent,
                AppColors.accent2.withOpacity(0.10),
              ],
            ),
          ),
        );
      },
    );
  }
}
