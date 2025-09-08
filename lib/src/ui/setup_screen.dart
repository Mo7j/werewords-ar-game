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
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('إعداد اللعبة'),
          backgroundColor: Colors.transparent,
        ),

        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // عدد اللاعبين
            _glassCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('عدد اللاعبين',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.accent,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: AppColors.accent2,
                            overlayColor: AppColors.accent.withOpacity(.15),
                            trackHeight: 6,
                            valueIndicatorColor: AppColors.surface,
                            valueIndicatorTextStyle:
                                const TextStyle(color: Colors.white),
                          ),
                          child: Slider(
                            value: cfg.playerCount.toDouble(),
                            min: 4,
                            max: 18, // allow 12+ players
                            divisions: 14, // 3..20
                            label: '${cfg.playerCount}',
                            onChanged: (v) => ref
                                .read(gameConfigProvider.notifier)
                                .setPlayerCount(v.round()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Center(child: Text('${cfg.playerCount}')),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 50.ms)
                .moveY(begin: 12, end: 0),

            const SizedBox(height: 12),

            // مدة الجولة الرئيسية
            _glassCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('مدة الجولة الرئيسية',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [180, 240, 300, 360]
                        .map((sec) => _TimeChip(sec))
                        .toList(),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms)
                .moveY(begin: 12, end: 0),

            const SizedBox(height: 12),

            // مدة النقاش بعد الجولة (موحّدة للمرحلتين)
            _glassCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('مدة النقاش بعد الجولة',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [15, 30, 60]
                        .map((sec) => _DiscussionTimeChip(sec: sec))
                        .toList(),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .moveY(begin: 12, end: 0),

            const SizedBox(height: 12),

            // الصعوبة
            _glassCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('الصعوبة',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: Difficulty.values.map((d) {
                      final selected = cfg.difficulty == d;
                      return ChoiceChip(
                        label: Text(_labelFor(d)),
                        selected: selected,
                        onSelected: (_) => ref
                            .read(gameConfigProvider.notifier)
                            .setDifficulty(d),
                      );
                    }).toList(),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 250.ms)
                .moveY(begin: 12, end: 0),

            const SizedBox(height: 96), // space for bottom bar
          ],
        ),

        // Bottom: centered Start + "كيف نلعب؟" link under it
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Smaller Start button (centered, fixed width)
              Center(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 40),
                    minimumSize: const Size(220, 0), // fixed width, height auto
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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
                  child: const Text(
                    'ابدأ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ).animate().scale(duration: 200.ms),
              ),

              const SizedBox(height: 12),

              // How to play (centered under Start)
              TextButton(
                onPressed: () => _showHowToPlay(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
                child: const Text(
                  'كيف نلعب؟',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12), // breathing space at bottom
            ],
          ),
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
      onSelected: (_) =>
          ref.read(gameConfigProvider.notifier).setRoundSeconds(seconds),
    );
  }

  String _fmt(int s) {
    final m = (s / 60).floor();
    final r = s % 60;
    return r == 0 ? '${m}د' : '${m}د ${r}ث';
  }
}

// Unified discussion timer chip (used by both post phases)
class _DiscussionTimeChip extends ConsumerWidget {
  final int sec;
  const _DiscussionTimeChip({super.key, required this.sec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(gameConfigProvider);
    final selected = cfg.postDiscussionSeconds == sec;
    return ChoiceChip(
      label: Text('$sec ث'),
      selected: selected,
      onSelected: (_) =>
          ref.read(gameConfigProvider.notifier).setPostDiscussionSeconds(sec),
    );
  }
}

void _showHowToPlay(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('كيف نلعب؟'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الفكرة العامة
            Text(
              'الفكرة العامة',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              '• لكل لاعب دور سري.\n'
              '• هناك كلمة سرّية واحدة للجولة. العمدة يعرفها ويجيب عن الأسئلة، والمستذئب والعرّاف/ة يعرفانها أيضًا، بينما القرويون لا يعرفونها.\n'
              '• هدف الفريق: الوصول إلى الكلمة. هدف المستذئب: الإرباك دون أن يُكشف.',
            ),

            SizedBox(height: 12),

            // الأدوار باختصار
            Text(
              'الأدوار باختصار',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              '👑 العمدة: يعرف الكلمة ويجيب باستخدام الأزرار: نعم / لا / غير معروف / قريب جدًا.\n'
              '🐺 المستذئب: يعرف الكلمة ويحاول تضليل الآخرين دون كشف هويته.\n'
              '🔮 العرّاف/ة: يعرف الكلمة ويساعد الفريق لكن بحذر كي لا يُكشف.\n'
              '🏡 القروي: لا يعرف الكلمة؛ يطرح أسئلة ذكية للوصول إليها.',
            ),

            SizedBox(height: 12),

            // مجريات الجولة
            Text(
              'مجريات الجولة',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              '1) توزيع الأدوار: كل لاعب يكشف دوره سرًّا ثم يُخفيه.\n'
              '2) جولة الأسئلة (مؤقّت): يطرح اللاعبون أسئلة بنعم/لا، والعمدة يرد بالأزرار.\n'
              '   • حدود الردود: نعم/لا (معًا) 30 نقرة، "غير معروف" 15، "قريب جدًا" مرة واحدة.\n'
              '3) إذا وُجدت الكلمة: يبدأ نقاش قصير لـ "مطاردة العرّاف/ة".\n'
              '4) إذا لم تُوجد: يبدأ نقاش قصير لـ "اكتشاف المستذئب".\n'
              '5) بعد انتهاء النقاش: التصويت ثم عرض النتائج.',
            ),

            SizedBox(height: 12),

            // نصائح سريعة
            Text(
              'نصائح سريعة',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              '• اجعل أسئلتك محددة لتقليص الاحتمالات بسرعة.\n'
              '• المستذئب: امزج بين الصدق والتمويه كي لا تُكشف مباشرة.\n'
              '• العرّاف/ة: ساعد الفريق لكن تَجَنَّب الإشارات الواضحة لهويتك.\n'
              '• القرويون: سجّلوا الملاحظات واستفيدوا من "قريب جدًا" لتوجيه الأسئلة.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('حسنًا'),
        ),
      ],
    ),
  );
}
