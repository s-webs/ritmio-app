import '../../tasks/data/task_model.dart';
import '../../transactions/data/transaction_model.dart';

class AiResultModel {
  AiResultModel({
    required this.intent,
    required this.tasks,
    this.language,
    this.confidence,
    this.transaction,
    this.interactionId,
  });

  final String intent;
  final String? language;
  final double? confidence;
  final TransactionModel? transaction;
  final List<TaskModel> tasks;
  final int? interactionId;

  bool get hasTransaction => transaction != null;
  bool get hasTasks => tasks.isNotEmpty;

  factory AiResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final parsed = data['parsed'] as Map<String, dynamic>? ?? {};
    final rawTransaction = data['transaction'];
    final rawTasks = data['tasks'];

    TransactionModel? transaction;
    if (rawTransaction is Map<String, dynamic>) {
      transaction = TransactionModel.fromJson(rawTransaction);
    }

    final tasks = <TaskModel>[];
    if (rawTasks is List) {
      for (final t in rawTasks) {
        if (t is Map<String, dynamic>) {
          tasks.add(TaskModel.fromJson(t));
        }
      }
    }

    return AiResultModel(
      intent: parsed['intent']?.toString() ?? 'unknown',
      language: parsed['language']?.toString(),
      confidence: (parsed['confidence'] as num?)?.toDouble(),
      transaction: transaction,
      tasks: tasks,
      interactionId: data['interaction_id'] as int?,
    );
  }
}
