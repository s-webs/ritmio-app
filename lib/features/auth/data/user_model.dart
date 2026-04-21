class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.locale,
    this.timezone,
    this.defaultCurrency,
  });

  final int id;
  final String name;
  final String email;
  final String? locale;
  final String? timezone;
  final String? defaultCurrency;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      locale: json['locale']?.toString(),
      timezone: json['timezone']?.toString(),
      defaultCurrency: json['default_currency']?.toString(),
    );
  }
}
