import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/ai_result_model.dart';
import '../../tasks/presentation/tasks_controller.dart';
import '../../transactions/presentation/transactions_controller.dart';
import 'voice_controller.dart';

class VoiceSheet extends StatelessWidget {
  const VoiceSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final voiceCtrl = context.read<VoiceController>();
    final tasksCtrl = context.read<TasksController>();
    final transactionsCtrl = context.read<TransactionsController>();

    // Auto-start recording when sheet opens
    await voiceCtrl.toggleRecording();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: voiceCtrl),
          ChangeNotifierProvider.value(value: tasksCtrl),
          ChangeNotifierProvider.value(value: transactionsCtrl),
        ],
        child: const VoiceSheet(),
      ),
    ).whenComplete(() => voiceCtrl.cancelIfActive());
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VoiceController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: AppSpacing.md),
            _buildContent(context, controller),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.darkBorder,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VoiceController controller) {
    switch (controller.state) {
      case VoiceState.recording:
        return _RecordingView(controller: controller);
      case VoiceState.processing:
        return const _ProcessingView();
      case VoiceState.success:
        return _ResultView(
          result: controller.result!,
          onDone: () {
            _refreshLists(context);
            controller.reset();
            Navigator.of(context).pop();
          },
          onRetry: () {
            controller.reset();
            Navigator.of(context).pop();
          },
        );
      case VoiceState.error:
        return _ErrorView(
          message: controller.errorMessage ?? 'Неизвестная ошибка',
          onRetry: () {
            controller.reset();
            Navigator.of(context).pop();
          },
        );
      case VoiceState.idle:
        return const SizedBox.shrink();
    }
  }

  void _refreshLists(BuildContext context) {
    try {
      context.read<TasksController>().load();
    } catch (_) {}
    try {
      context.read<TransactionsController>().load();
    } catch (_) {}
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView({required this.controller});
  final VoiceController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PulsingMic(),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Говорите...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Например: "на 9 мая добавь поход в парк"',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.darkTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton.icon(
          onPressed: controller.toggleRecording,
          icon: const Icon(Icons.stop_rounded),
          label: const Text('Остановить'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsingMic extends StatefulWidget {
  const _PulsingMic();

  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final glow = 0.3 + 0.5 * _anim.value;
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.shade700,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: glow),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 40),
        );
      },
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: AppSpacing.md),
        CircularProgressIndicator(color: AppColors.accentPink),
        SizedBox(height: AppSpacing.md),
        Text(
          'Обрабатываю...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'ИИ анализирует вашу речь',
          style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
        ),
        SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.onDone,
    required this.onRetry,
  });

  final AiResultModel result;
  final VoidCallback onDone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _titleForIntent(result.intent),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (result.hasTasks) ..._buildTaskCards(result),
        if (result.hasTransaction) _buildTransactionCard(result),
        if (!result.hasTasks && !result.hasTransaction)
          Text(
            'Команда распознана, но данные не созданы.\nПопробуйте ещё раз.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkTextSecondary,
                  side: BorderSide(color: AppColors.darkBorder),
                ),
                child: const Text('Ещё раз'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Готово'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildTaskCards(AiResultModel result) {
    return result.tasks.map((task) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.task_alt_rounded, color: AppColors.accentPink, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (task.dueDate != null)
                    Text(
                      'До: ${task.dueDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTransactionCard(AiResultModel result) {
    final t = result.transaction!;
    final isIncome = t.type == 'income';
    final color = isIncome ? Colors.greenAccent : Colors.redAccent;
    final icon = isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final sign = isIncome ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$sign${t.amount.toStringAsFixed(0)} ${t.currency}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (t.description != null || t.merchant != null)
                  Text(
                    t.description ?? t.merchant ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                Text(
                  t.transactionDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleForIntent(String intent) {
    switch (intent) {
      case 'create_tasks':
      case 'create_task':
        return 'Задача добавлена';
      case 'create_income':
        return 'Доход записан';
      case 'create_expense':
        return 'Расход записан';
      default:
        return 'Команда выполнена';
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Не удалось распознать',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPink,
            foregroundColor: Colors.white,
          ),
          child: const Text('Попробовать снова'),
        ),
      ],
    );
  }
}
