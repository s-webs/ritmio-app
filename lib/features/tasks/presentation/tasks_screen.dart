import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/wave_loader.dart';
import '../../../core/widgets/wave_refresh.dart';
import '../data/task_model.dart';
import 'tasks_controller.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TasksController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<TasksController>();

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
              ? const Center(child: WaveLoader())
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
                        title: l10n.t('tasks'),
                        onAdd: () => _openForm(),
                      ),
                    ),
                    Expanded(child: WaveRefresh(
                      onRefresh: () => c.load(),
                      child: Builder(builder: (_) {
                        if (c.items.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    l10n.t('tasks'),
                                    style: const TextStyle(
                                        color: AppColors.darkTextSecondary),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        final withDate = c.items
                            .where((t) =>
                                t.dueDate != null && t.dueDate!.isNotEmpty)
                            .toList()
                          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
                        final withoutDate = c.items
                            .where(
                                (t) => t.dueDate == null || t.dueDate!.isEmpty)
                            .toList();

                        final rows = <Object>[];
                        String? lastDate;
                        for (final t in withDate) {
                          if (t.dueDate != lastDate) {
                            rows.add(t.dueDate!);
                            lastDate = t.dueDate;
                          }
                          rows.add(t);
                        }
                        if (withoutDate.isNotEmpty) {
                          rows.add('—');
                          rows.addAll(withoutDate);
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.xs,
                            AppSpacing.md,
                            100,
                          ),
                          itemCount: rows.length,
                          itemBuilder: (_, i) {
                            final row = rows[i];
                            if (row is String) {
                              return _DateHeader(label: row);
                            }
                            final t = row as TaskModel;
                            return _TaskCard(
                              task: t,
                              onDelete: () => c.remove(t.id),
                              onDetails: () => _showDetails(t),
                            );
                          },
                        );
                      }),
                    )),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _showDetails(TaskModel task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _TaskDetailSheet(
        task: task,
        onEdit: () {
          Navigator.pop(context);
          _openForm(editing: task);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _confirmAndDelete(task);
        },
        onComplete: () async {
          Navigator.pop(context);
          await context.read<TasksController>().complete(task.id);
        },
        onCancel: () async {
          Navigator.pop(context);
          await context.read<TasksController>().cancel(task.id);
        },
      ),
    );
  }

  Future<void> _confirmAndDelete(TaskModel task) async {
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
      await context.read<TasksController>().remove(task.id);
    }
  }

  Future<void> _openForm({TaskModel? editing}) async {
    final l10n = context.l10n;
    final titleCtrl = TextEditingController(text: editing?.title ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');
    final dueDateCtrl = TextEditingController(text: editing?.dueDate ?? '');
    String priority = editing?.priority ?? 'normal';

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                editing == null ? l10n.t('createTask') : l10n.t('editTask'),
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(labelText: l10n.t('title')),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(labelText: l10n.t('description')),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: InputDecoration(labelText: l10n.t('priority')),
                dropdownColor: AppColors.darkSurface,
                items: [
                  DropdownMenuItem(value: 'low', child: Text(l10n.t('low'))),
                  DropdownMenuItem(value: 'normal', child: Text(l10n.t('normal'))),
                  DropdownMenuItem(value: 'high', child: Text(l10n.t('high'))),
                ],
                onChanged: (v) => setS(() => priority = v ?? priority),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: dueDateCtrl,
                decoration: InputDecoration(labelText: l10n.t('dueDate')),
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
      'title': titleCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'priority': priority,
      'status': editing?.status ?? 'pending',
      'due_date': dueDateCtrl.text.trim(),
      'category': 'work',
    };
    final c = context.read<TasksController>();
    if (editing == null) {
      await c.create(body);
    } else {
      await c.update(editing.id, body);
    }
  }
}

// ── Date header ──────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AppColors.darkTextSecondary,
        ),
      ),
    );
  }
}

// ── Swipeable card ───────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onDelete,
    required this.onDetails,
  });

  final TaskModel task;
  final VoidCallback onDelete;
  final VoidCallback onDetails;

  static Color _priorityColor(String p) {
    return switch (p) {
      'high' => const Color(0xFFFF5A6D),
      'low' => const Color(0xFF00D26A),
      _ => AppColors.accentViolet,
    };
  }

  static Color _statusColor(String s) {
    return switch (s) {
      'completed' => const Color(0xFF00D26A),
      'cancelled' => AppColors.darkTextSecondary,
      _ => AppColors.accentViolet,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
      key: ValueKey('task-${task.id}'),
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
          final l10n = context.l10n;
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
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
        }
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        color: AppColors.darkSurface,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority indicator
              Container(
                width: 4,
                color: priorityColor,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextPrimary,
                          decoration: task.status == 'completed'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (task.dueDate != null) ...[
                            Icon(Icons.calendar_today_rounded,
                                size: 11,
                                color: AppColors.darkTextSecondary),
                            const SizedBox(width: 3),
                            Text(
                              task.dueDate!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (task.category != null)
                            Text(
                              task.category!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Status badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.status,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
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

class _TaskDetailSheet extends StatelessWidget {
  const _TaskDetailSheet({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    required this.onCancel,
  });

  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final priorityColor = _TaskCard._priorityColor(task.priority);
    final statusColor = _TaskCard._statusColor(task.status);

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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Status + priority row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(task.status,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: statusColor)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(task.priority,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: priorityColor)),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Title
            Text(task.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.darkTextPrimary)),

            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(task.description!,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.darkTextSecondary)),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Meta row
            Row(
              children: [
                if (task.dueDate != null)
                  _DetailChip(
                    icon: Icons.calendar_today_rounded,
                    label: task.dueDate!,
                  ),
                if (task.category != null) ...[
                  const SizedBox(width: 8),
                  _DetailChip(
                    icon: Icons.label_outline_rounded,
                    label: task.category!,
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.darkBorder),
            const SizedBox(height: AppSpacing.sm),

            // Actions
            Row(
              children: [
                if (task.status == 'pending') ...[
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.check_circle_outline_rounded,
                      label: l10n.t('complete'),
                      color: const Color(0xFF00D26A),
                      onTap: onComplete,
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
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
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
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
