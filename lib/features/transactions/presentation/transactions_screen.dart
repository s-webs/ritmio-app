import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_header.dart';
import '../data/transaction_model.dart';
import 'transactions_controller.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<TransactionsController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF170027), Color(0xFF0A001A)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: c.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: AppHeader(
                        title: l10n.t('transactions'),
                        onAdd: () => _openForm(),
                      ),
                    ),
                    if (c.items.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            l10n.t('transactions'),
                            style: const TextStyle(
                                color: AppColors.darkTextSecondary),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.xs,
                            AppSpacing.md,
                            100,
                          ),
                          itemCount: c.items.length,
                          itemBuilder: (_, i) => _TransactionCard(
                            transaction: c.items[i],
                            onDelete: () => c.remove(c.items[i].id),
                            onDetails: () => _showDetails(c.items[i]),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _showDetails(TransactionModel t) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _TransactionDetailSheet(
        transaction: t,
        onEdit: () {
          Navigator.pop(context);
          _openForm(editing: t);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _confirmAndDelete(t);
        },
        onConfirm: () async {
          Navigator.pop(context);
          await context.read<TransactionsController>().confirm(t.id);
        },
      ),
    );
  }

  Future<void> _confirmAndDelete(TransactionModel t) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.t('deleteConfirm'),
            style: const TextStyle(color: AppColors.darkTextPrimary)),
        content: Text(l10n.t('deleteConfirmMsg'),
            style: const TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('yes'),
                style: const TextStyle(color: AppColors.accentPink)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<TransactionsController>().remove(t.id);
    }
  }

  Future<void> _openForm({TransactionModel? editing}) async {
    final l10n = context.l10n;
    final amountCtrl =
        TextEditingController(text: editing?.amount.toString() ?? '');
    final dateCtrl =
        TextEditingController(text: editing?.transactionDate ?? '');
    final categoryCtrl =
        TextEditingController(text: editing?.category ?? '');
    final merchantCtrl =
        TextEditingController(text: editing?.merchant ?? '');
    final descCtrl =
        TextEditingController(text: editing?.description ?? '');
    String type = editing?.type ?? 'expense';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                editing == null
                    ? l10n.t('createTransaction')
                    : l10n.t('editTransaction'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(labelText: l10n.t('type')),
                dropdownColor: AppColors.darkSurface,
                items: [
                  DropdownMenuItem(
                      value: 'expense', child: Text(l10n.t('expenseType'))),
                  DropdownMenuItem(
                      value: 'income', child: Text(l10n.t('incomeType'))),
                ],
                onChanged: (v) => setS(() => type = v ?? type),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.t('amount')),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: dateCtrl,
                decoration: InputDecoration(labelText: l10n.t('date')),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: categoryCtrl,
                decoration: InputDecoration(labelText: l10n.t('category')),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: merchantCtrl,
                decoration: InputDecoration(labelText: l10n.t('merchant')),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(labelText: l10n.t('description')),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.t('cancel')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.t('save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final body = {
      'type': type,
      'amount': num.tryParse(amountCtrl.text.trim()) ?? 0,
      'currency': 'KZT',
      'date': dateCtrl.text.trim(),
      'category': categoryCtrl.text.trim(),
      'merchant': merchantCtrl.text.trim(),
      'description': descCtrl.text.trim(),
    };
    final c = context.read<TransactionsController>();
    if (editing == null) {
      await c.create(body);
    } else {
      await c.update(editing.id, body);
    }
  }
}

// ── Swipeable card ───────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onDelete,
    required this.onDetails,
  });

  final TransactionModel transaction;
  final VoidCallback onDelete;
  final VoidCallback onDetails;

  static Color _typeColor(String type) {
    return type == 'income'
        ? const Color(0xFF00D26A)
        : const Color(0xFFFF5A6D);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = transaction;
    final typeColor = _typeColor(t.type);
    final isIncome = t.type == 'income';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
      key: ValueKey('tx-${t.id}'),
      background: _SwipeBg(
        alignment: Alignment.centerLeft,
        color: AppColors.primaryPurple,
        icon: Icons.info_outline_rounded,
        label: l10n.t('swipeLeftHint'),
      ),
      secondaryBackground: _SwipeBg(
        alignment: Alignment.centerRight,
        color: const Color(0xFFD32F2F),
        icon: Icons.delete_outline_rounded,
        label: l10n.t('swipeRightHint'),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDetails();
          return false;
        } else {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(l10n.t('deleteConfirm'),
                  style:
                      const TextStyle(color: AppColors.darkTextPrimary)),
              content: Text(l10n.t('deleteConfirmMsg'),
                  style: const TextStyle(
                      color: AppColors.darkTextSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l10n.t('no')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l10n.t('yes'),
                      style:
                          const TextStyle(color: AppColors.accentPink)),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        color: AppColors.darkSurface,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Type indicator
              Container(
                width: 4,
                color: typeColor,
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: typeColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${isIncome ? '+' : '-'}${t.amount} ${t.currency}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (t.category != null && t.category!.isNotEmpty)
                            t.category!,
                          t.transactionDate,
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.darkTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Needs confirmation badge
              if (t.needsConfirmation)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 14,
                      color: Color(0xFFFFA726),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}

// ── Detail sheet ─────────────────────────────────────────────────────────────

class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onConfirm,
  });

  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = transaction;
    final isIncome = t.type == 'income';
    final typeColor = _TransactionCard._typeColor(t.type);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Type badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isIncome ? l10n.t('incomeType') : l10n.t('expenseType'),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: typeColor),
                  ),
                ),
                if (t.needsConfirmation) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.t('needsConfirmation'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFA726)),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Amount
            Text(
              '${isIncome ? '+' : '-'}${t.amount} ${t.currency}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: typeColor,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Meta chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _DetailChip(
                  icon: Icons.calendar_today_rounded,
                  label: t.transactionDate,
                ),
                if (t.category != null && t.category!.isNotEmpty)
                  _DetailChip(
                    icon: Icons.label_outline_rounded,
                    label: t.category!,
                  ),
                if (t.merchant != null && t.merchant!.isNotEmpty)
                  _DetailChip(
                    icon: Icons.store_outlined,
                    label: t.merchant!,
                  ),
              ],
            ),

            if (t.description != null && t.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.description!,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.darkTextSecondary),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: AppSpacing.sm),

            // Actions
            Row(
              children: [
                if (t.needsConfirmation) ...[
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.check_circle_outline_rounded,
                      label: l10n.t('confirm'),
                      color: const Color(0xFF00D26A),
                      onTap: onConfirm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.edit_outlined,
                    label: l10n.t('edit'),
                    color: AppColors.primaryPurple,
                    onTap: onEdit,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    label: l10n.t('delete'),
                    color: const Color(0xFFD32F2F),
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Swipe background ─────────────────────────────────────────────────────────

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final AlignmentGeometry alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.darkTextSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
