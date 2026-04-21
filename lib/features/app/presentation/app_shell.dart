import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_x.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../tasks/presentation/tasks_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../voice/presentation/voice_controller.dart';
import '../../voice/presentation/voice_sheet.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = const [
      DashboardScreen(),
      TransactionsScreen(),
      TasksScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: pages[_index],
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: SizedBox(
          height: 84,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.darkBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _TabItem(
                      icon: Icons.query_stats_rounded,
                      label: l10n.t('dashboard'),
                      selected: _index == 0,
                      onTap: () => setState(() => _index = 0),
                    ),
                    _TabItem(
                      icon: Icons.payments_rounded,
                      label: l10n.t('transactions'),
                      selected: _index == 1,
                      onTap: () => setState(() => _index = 1),
                    ),
                    const SizedBox(width: 72),
                    _TabItem(
                      icon: Icons.task_alt_rounded,
                      label: l10n.t('tasks'),
                      selected: _index == 2,
                      onTap: () => setState(() => _index = 2),
                    ),
                    _TabItem(
                      icon: Icons.settings_outlined,
                      label: l10n.t('settings'),
                      selected: _index == 3,
                      onTap: () => setState(() => _index = 3),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -2,
                child: _MicButton(pulseController: _pulseController),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.pulseController});

  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    final voiceCtrl = context.watch<VoiceController>();
    final isActive = voiceCtrl.isRecording || voiceCtrl.isProcessing;

    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final t = isActive ? 1.0 : pulseController.value;
        final scale = 1 + (0.07 * t);
        final glowAlpha = isActive ? 0.65 : (0.25 + (0.30 * t));
        final glowColor = isActive ? Colors.red : AppColors.accentPink;
        final gradientColors = isActive
            ? [Colors.red.shade700, Colors.red.shade400]
            : const [Color(0xFFFF6E61), AppColors.accentPink];

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () => _onTap(context, voiceCtrl),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: glowAlpha),
                    blurRadius: 18 + (18 * t),
                    spreadRadius: 1 + (2 * t),
                  ),
                ],
              ),
              child: voiceCtrl.isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(
                      isActive ? Icons.stop_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onTap(BuildContext context, VoiceController voiceCtrl) async {
    if (voiceCtrl.isProcessing || voiceCtrl.isRecording) return;
    await VoiceSheet.show(context);
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : AppColors.darkTextSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
