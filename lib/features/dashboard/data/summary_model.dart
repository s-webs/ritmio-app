class SummaryModel {
  SummaryModel({
    required this.periodStart,
    required this.periodEnd,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.balance,
  });

  final String periodStart;
  final String periodEnd;
  final num incomeTotal;
  final num expenseTotal;
  final num balance;

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      periodStart: json['period_start']?.toString() ?? '',
      periodEnd: json['period_end']?.toString() ?? '',
      incomeTotal: json['income_total'] as num? ?? 0,
      expenseTotal: json['expense_total'] as num? ?? 0,
      balance: json['balance'] as num? ?? 0,
    );
  }
}
