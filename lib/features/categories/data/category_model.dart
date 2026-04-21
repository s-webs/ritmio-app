class CategoryModel {
  CategoryModel({
    required this.id,
    required this.type,
    required this.slug,
    required this.nameRu,
    required this.nameEn,
  });

  final int id;
  final String type;
  final String slug;
  final String nameRu;
  final String nameEn;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return CategoryModel(
      id: data['id'] as int? ?? 0,
      type: data['type']?.toString() ?? 'expense',
      slug: data['slug']?.toString() ?? '',
      nameRu: data['name_ru']?.toString() ?? '',
      nameEn: data['name_en']?.toString() ?? '',
    );
  }
}
