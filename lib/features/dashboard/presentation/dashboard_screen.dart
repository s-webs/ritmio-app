import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_header.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _periodIndex = 1;
  int _viewIndex = 2;
  int _sectionIndex = 0;
  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardController>().load();
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<DashboardController>();
    final summary = _periodIndex == 1 ? c.weekly : c.monthly;
    final income = summary?.incomeTotal ?? 0;
    final expense = summary?.expenseTotal ?? 0;
    final balance = summary?.balance ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF170027), Color(0xFF0A001A)],
        ),
      ),
      child: SafeArea(
        child: c.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const AppHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  AnimatedBuilder(
                    animation: _gradientController,
                    builder: (context, child) {
                      final t = _gradientController.value;
                      final start = Color.lerp(
                        const Color(0xFFFF5E6D),
                        AppColors.accentPink,
                        t,
                      )!;
                      final mid = Color.lerp(
                        AppColors.accentPink,
                        AppColors.accentViolet,
                        t,
                      )!;
                      final end = Color.lerp(
                        AppColors.accentViolet,
                        const Color(0xFFFF5E6D),
                        t,
                      )!;
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            begin: Alignment(-1 + (2 * t), -1),
                            end: Alignment(1 - (2 * t), 1),
                            colors: [start, mid, end],
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('balance'), style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$balance ₽',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _statCard(l10n.t('income'), income, const Color(0xFF00D26A))),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: _statCard(l10n.t('expense'), expense, const Color(0xFFFF5A6D))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _chipRow(
                    items: [l10n.t('day'), l10n.t('week'), l10n.t('month'), l10n.t('all')],
                    selected: _periodIndex,
                    onTap: (v) => setState(() => _periodIndex = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _chipRow(
                    items: [l10n.t('overview'), l10n.t('calendar'), l10n.t('byDays')],
                    selected: _viewIndex,
                    onTap: (v) => setState(() => _viewIndex = v),
                    withIcons: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _sectionButton(
                          icon: Icons.account_balance_wallet_outlined,
                          label: l10n.t('transactions'),
                          active: _sectionIndex == 0,
                          onTap: () => setState(() => _sectionIndex = 0),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _sectionButton(
                          icon: Icons.check_box_outlined,
                          label: l10n.t('tasks'),
                          active: _sectionIndex == 1,
                          onTap: () => setState(() => _sectionIndex = 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Column(
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          size: 54, color: AppColors.darkTextSecondary.withValues(alpha: 0.45)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        c.error ?? 'Нет данных',
                        style: const TextStyle(color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statCard(String title, num value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.darkSurface.withValues(alpha: 0.8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  title == 'Доход' || title == 'Income' ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.darkTextSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('$value ₽', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _chipRow({
    required List<String> items,
    required int selected,
    required ValueChanged<int> onTap,
    bool withIcons = false,
  }) {
    return Row(
      children: List.generate(items.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : AppSpacing.xs),
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: i == selected
                      ? const LinearGradient(
                          colors: [AppColors.accentPink, AppColors.accentViolet],
                        )
                      : null,
                  color: i == selected ? null : AppColors.darkSurface.withValues(alpha: 0.9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (withIcons) ...[
                      Icon(
                        i == 0
                            ? Icons.account_box_outlined
                            : i == 1
                                ? Icons.calendar_month_outlined
                                : Icons.insert_chart_outlined_rounded,
                        size: 16,
                        color: i == selected ? Colors.white : AppColors.darkTextSecondary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      items[i],
                      style: TextStyle(
                        color: i == selected ? Colors.white : AppColors.darkTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _sectionButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: active ? AppColors.accentPink : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : AppColors.darkTextSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.darkTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
