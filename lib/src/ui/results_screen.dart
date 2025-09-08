import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import 'theme.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final _guessCtrl = TextEditingController();
  bool _checked = false;
  bool? _villagersWin;

  @override
  void dispose() {
    _guessCtrl.dispose();
    super.dispose();
  }

  String _roleLabel(Role r) {
    switch (r) {
      case Role.mayor:
        return 'العمدة';
      case Role.werewolf:
        return 'المستذئب';
      case Role.seer:
        return 'العرّاف/ة';
      case Role.villager:
        return 'قروي';
    }
  }

  @override
  Widget build(BuildContext context) {
    final secret = ref.watch(secretWordProvider) ?? '—';
    final roles = ref.watch(assignedRolesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('النتائج'),
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            // subtle background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.08),
                    Colors.transparent,
                    AppColors.accent2.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Secret word / reveal
                  Container(
                    decoration: glassCard(18),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_open_rounded),
                        const SizedBox(width: 10),
                        const Text('الكلمة السرّية:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            secret,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Roles recap
                  Container(
                    decoration: glassCard(20),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'كشف الأدوار',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(roles.length, (i) {
                          final r = roles[i];
                          final icon = switch (r) {
                            Role.mayor => Icons.workspace_premium_rounded,
                            Role.werewolf => Icons.pets_rounded,
                            Role.seer => Icons.auto_awesome_rounded,
                            Role.villager => Icons.home_rounded,
                          };
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: glassCard(14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(icon),
                                const SizedBox(width: 10),
                                Text('اللاعب ${i + 1}'),
                                const SizedBox(width: 10),
                                const Text('—'),
                                const SizedBox(width: 10),
                                Text(
                                  _roleLabel(r),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // leave space so content doesn't sit under bottom buttons
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ],
        ),

        // Bottom big buttons — same style as other screens
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity, // no fixed height
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
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
              icon: const Icon(Icons.replay_rounded, size: 28),
              label: const Text('جولة جديدة', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }

  void _check(String secret) {
    final guess = _normalize(_guessCtrl.text);
    final target = _normalize(secret);
    final win = guess.isNotEmpty && guess == target;
    setState(() {
      _checked = true;
      _villagersWin = win;
    });
  }

  String _normalize(String s) {
    // Arabic is case-agnostic; trim and collapse inner spaces.
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    return t;
  }
}

class _OutcomeBanner extends StatelessWidget {
  final bool villagersWin;
  const _OutcomeBanner({required this.villagersWin});

  @override
  Widget build(BuildContext context) {
    final color = villagersWin ? Colors.greenAccent : Colors.redAccent;
    final text = villagersWin ? 'القرويون فازوا 🎉' : 'المستذئب فاز 🐺';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            villagersWin ? Icons.emoji_events_rounded : Icons.warning_rounded,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
