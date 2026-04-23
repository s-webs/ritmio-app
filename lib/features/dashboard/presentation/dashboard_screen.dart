import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_x.dart';
import '../../../core/settings/currency_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/wave_loader.dart';
import '../../../core/widgets/wave_refresh.dart';
import '../../tasks/data/task_model.dart';
import '../../tasks/presentation/tasks_controller.dart';
import '../../transactions/data/transaction_model.dart';
import '../../transactions/presentation/transactions_controller.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // 0=day 1=week 2=month 3=all
  int _periodIndex = 1;
  // 0=transactions 1=tasks
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
      context.read<TransactionsController>().load();
      context.read<TasksController>().load();
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  // ── Period helpers ──────────────────────────────────────────────────────────

  String? _periodStart() {
    final now = DateTime.now();
    return switch (_periodIndex) {
      0 => _fmt(DateTime(now.year, now.month, now.day)),
      1 => _fmt(now.subtract(const Duration(days: 6))),
      2 => _fmt(DateTime(now.year, now.month, 1)),
      _ => null,
    };
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<TransactionModel> _filteredTransactions(List<TransactionModel> all) {
    final start = _periodStart();
    if (start == null) return all;
    return all.where((t) => t.transactionDate.compareTo(start) >= 0).toList();
  }

  List<TaskModel> _filteredTasks(List<TaskModel> all) {
    final start = _periodStart();
    if (start == null) return all;
    return all.where((t) {
      if (t.dueDate == null || t.dueDate!.isEmpty) return false;
      return t.dueDate!.compareTo(start) >= 0;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<DashboardController>();
    final tc = context.watch<TransactionsController>();
    final tac = context.watch<TasksController>();
    final currencySymbol = context.watch<CurrencyController>().symbol;

    final summary = _periodIndex <= 1 ? c.weekly : c.monthly;
    final income = summary?.incomeTotal ?? 0;
    final expense = summary?.expenseTotal ?? 0;
    final balance = summary?.balance ?? 0;

    final transactions = _filteredTransactions(tc.items)
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final tasks = _filteredTasks(tac.items)
      ..sort((a, b) => (a.dueDate ?? '').compareTo(b.dueDate ?? ''));

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
            ? const Center(child: WaveLoader())
            : WaveRefresh(
                onRefresh: () async {
                  await Future.wait([
                    context.read<DashboardController>().load(),
                    context.read<TransactionsController>().load(),
                    context.read<TasksController>().load(),
                  ]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const AppHeader(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Balance card ──────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _gradientController,
                    builder: (context, child) {
                      final t = _gradientController.value;
                      final start = Color.lerp(
                          const Color(0xFFFF5E6D), AppColors.accentPink, t)!;
                      final mid = Color.lerp(
                          AppColors.accentPink, AppColors.accentViolet, t)!;
                      final end = Color.lerp(
                          AppColors.accentViolet, const Color(0xFFFF5E6D), t)!;
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
                        Text(l10n.t('balance'),
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$balance $currencySymbol',
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

                  // ── Income / Expense ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                          child: _statCard(l10n.t('income'), income,
                              const Color(0xFF00D26A), currencySymbol)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                          child: _statCard(l10n.t('expense'), expense,
                              const Color(0xFFFF5A6D), currencySymbol)),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Period chips ──────────────────────────────────────────
                  _chipRow(
                    items: [
                      l10n.t('day'),
                      l10n.t('week'),
                      l10n.t('month'),
                      l10n.t('all'),
                    ],
                    selected: _periodIndex,
                    onTap: (v) => setState(() => _periodIndex = v),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Section tabs ──────────────────────────────────────────
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

                  const SizedBox(height: AppSpacing.sm),

                  // ── List ─────────────────────────────────────────────────
                  if (_sectionIndex == 0)
                    _TransactionList(
                      items: transactions,
                      isLoading: tc.isLoading,
                      currencySymbol: currencySymbol,
                    )
                  else
                    _TaskList(
                      items: tasks,
                      isLoading: tac.isLoading,
                    ),

                  const SizedBox(height: 90),
                ],
              ),
              ),
      ),
    );
  }

  Widget _statCard(String title, num value, Color accent, String symbol) {
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
                  accent == const Color(0xFF00D26A)
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 14,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: AppColors.darkTextSecondary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('$value $symbol',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _chipRow({
    required List<String> items,
    required int selected,
    required ValueChanged<int> onTap,
  }) {
    return Row(
      children: List.generate(items.length, (i) {
        final isSelected = i == selected;
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: i == items.length - 1 ? 0 : AppSpacing.xs),
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.accentPink, AppColors.accentViolet],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : AppColors.darkSurface.withValues(alpha: 0.9),
                ),
                child: Text(
                  items[i],
                  style: TextStyle(
                    color:
                        isSelected ? Colors.white : AppColors.darkTextSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
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
            Icon(icon,
                size: 18,
                color: active ? Colors.white : AppColors.darkTextSecondary),
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

// ── Transaction list ──────────────────────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.items,
    required this.isLoading,
    required this.currencySymbol,
  });

  final List<TransactionModel> items;
  final bool isLoading;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return _emptyState(context);
    }
    return Column(
      children: items.map((t) => _TxTile(t, currencySymbol)).toList(),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.darkTextSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.t('transactions'),
              style: const TextStyle(color: AppColors.darkTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile(this.t, this.symbol);
  final TransactionModel t;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final isIncome = t.type == 'income';
    final color =
        isIncome ? const Color(0xFF00D26A) : const Color(0xFFFF5A6D);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.category ?? t.merchant ?? '—',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t.transactionDate,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${t.amount} $symbol',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task list ─────────────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  const _TaskList({required this.items, required this.isLoading});

  final List<TaskModel> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return _emptyState(context);
    }
    return Column(
      children: items.map((t) => _TaskTile(t)).toList(),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_box_outlined,
                size: 48,
                color: AppColors.darkTextSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.t('tasks'),
              style: const TextStyle(color: AppColors.darkTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile(this.task);
  final TaskModel task;

  static Color _priorityColor(String p) => switch (p) {
        'high' => const Color(0xFFFF5A6D),
        'low' => const Color(0xFF00D26A),
        _ => AppColors.accentViolet,
      };

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(task.priority);
    final isDone = task.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: priorityColor),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextPrimary,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.dueDate != null && task.dueDate!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.dueDate!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: priorityColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
