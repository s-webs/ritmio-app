import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/category_model.dart';
import 'categories_controller.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<CategoriesController>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF170027), Color(0xFF0A001A)],
          ),
        ),
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
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.t('categories'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.xs,
                        AppSpacing.sm,
                        90,
                      ),
                      itemCount: c.items.length,
                      itemBuilder: (_, i) {
                        final item = c.items[i];
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.warmYellow.withValues(alpha: 0.2),
                              child: const Icon(Icons.category, color: AppColors.warmYellow),
                            ),
                            title: Text(item.nameRu.isNotEmpty ? item.nameRu : item.nameEn),
                            subtitle: Text('${item.type} | ${item.slug}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) => _onAction(v, item),
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'edit', child: Text(l10n.t('edit'))),
                                PopupMenuItem(value: 'delete', child: Text(l10n.t('delete'))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onAction(String action, CategoryModel item) async {
    final c = context.read<CategoriesController>();
    if (action == 'delete') await c.remove(item.id);
    if (action == 'edit') await _openForm(editing: item);
  }

  Future<void> _openForm({CategoryModel? editing}) async {
    final l10n = context.l10n;
    final slug = TextEditingController(text: editing?.slug ?? '');
    final nameRu = TextEditingController(text: editing?.nameRu ?? '');
    final nameEn = TextEditingController(text: editing?.nameEn ?? '');
    String type = editing?.type ?? 'expense';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          editing == null ? l10n.t('createCategory') : l10n.t('editCategory'),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                items: [
                  DropdownMenuItem(value: 'expense', child: Text(l10n.t('expenseType'))),
                  DropdownMenuItem(value: 'income', child: Text(l10n.t('incomeType'))),
                ],
                onChanged: (v) => type = v ?? type,
              ),
              TextField(controller: slug, decoration: InputDecoration(labelText: l10n.t('slug'))),
              TextField(controller: nameRu, decoration: InputDecoration(labelText: l10n.t('nameRu'))),
              TextField(controller: nameEn, decoration: InputDecoration(labelText: l10n.t('nameEn'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.t('save'))),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final c = context.read<CategoriesController>();
    if (editing == null) {
      await c.create({
        'type': type,
        'slug': slug.text.trim(),
        'name_ru': nameRu.text.trim(),
        'name_en': nameEn.text.trim(),
      });
    } else {
      await c.update(editing.id, {
        'name_ru': nameRu.text.trim(),
        'name_en': nameEn.text.trim(),
      });
    }
  }
}
