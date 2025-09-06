import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme.dart';

Future<void> showWordPeekSheet(
  BuildContext context, {
  required String roleLabel,
  required String secret,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PeekSheet(roleLabel: roleLabel, secret: secret),
  );
}

class _PeekSheet extends StatefulWidget {
  final String roleLabel;
  final String secret;
  const _PeekSheet({required this.roleLabel, required this.secret});

  @override
  State<_PeekSheet> createState() => _PeekSheetState();
}

class _PeekSheetState extends State<_PeekSheet> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: glassCard(24),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('سري — ${widget.roleLabel} فقط'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: AnimatedContainer(
                  duration: 200.ms,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(24),
                  decoration: glassCard(24).copyWith(
                    gradient: LinearGradient(
                      colors: _revealed
                          ? [AppColors.accent.withOpacity(0.18), AppColors.accent2.withOpacity(0.18)]
                          : [Colors.white.withOpacity(0.02), Colors.white.withOpacity(0.02)],
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: 200.ms,
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: _revealed
                          ? Column(
                              key: const ValueKey('revealed'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('الكلمة السرّية', style: TextStyle(fontSize: 16, color: Colors.white70)),
                                const SizedBox(height: 8),
                                Text(
                                  widget.secret,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, height: 1.1),
                                ).animate().scale(duration: 180.ms),
                              ],
                            )
                          : Column(
                              key: const ValueKey('cover'),
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.touch_app_rounded, size: 56),
                                SizedBox(height: 8),
                                Text('اضغط لعرض الكلمة'),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('تم — أعِد الهاتف'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
