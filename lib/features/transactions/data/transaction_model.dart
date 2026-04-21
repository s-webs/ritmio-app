class TransactionModel {
  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    this.category,
    this.description,
    this.merchant,
    this.needsConfirmation = false,
  });

  final int id;
  final String type;
  final num amount;
  final String currency;
  final String transactionDate;
  final String? category;
  final String? description;
  final String? merchant;
  final bool needsConfirmation;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int? ?? 0,
      type: json['type']?.toString() ?? 'expense',
      amount: json['amount'] as num? ?? 0,
      currency: json['currency']?.toString() ?? 'KZT',
      transactionDate: json['transaction_date']?.toString() ?? '',
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      merchant: json['merchant']?.toString(),
      needsConfirmation: json['needs_confirmation'] as bool? ?? false,
    );
  }
}
