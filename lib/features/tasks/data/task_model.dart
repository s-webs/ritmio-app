class TaskModel {
  TaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.description,
    this.dueDate,
    this.category,
  });

  final int id;
  final String title;
  final String status;
  final String priority;
  final String? description;
  final String? dueDate;
  final String? category;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return TaskModel(
      id: data['id'] as int? ?? 0,
      title: data['title']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      priority: data['priority']?.toString() ?? 'normal',
      description: data['description']?.toString(),
      dueDate: data['due_date']?.toString(),
      category: data['category']?.toString(),
    );
  }
}
