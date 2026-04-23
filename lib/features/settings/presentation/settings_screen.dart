import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_x.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/settings/currency_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/presentation/auth_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _pendingCurrency;
  late String _pendingLocale;

  @override
  void initState() {
    super.initState();
    final currCtrl = context.read<CurrencyController>();
    final locCtrl = context.read<LocaleController>();
    _pendingCurrency = currCtrl.code;
    _pendingLocale = locCtrl.locale?.languageCode ?? 'ru';
  }

  Future<void> _save() async {
    final currCtrl = context.read<CurrencyController>();
    final locCtrl = context.read<LocaleController>();
    final l10n = context.l10n;
    await currCtrl.setCurrency(_pendingCurrency);
    await locCtrl.setLocale(_pendingLocale);
    if (!mounted) return;
    AppToast.show(context, l10n.t('settingsSaved'));
  }

  Future<void> _logout() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.t('logout'),
          style: const TextStyle(color: AppColors.darkTextPrimary),
        ),
        content: Text(
          l10n.t('logoutConfirm'),
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('no')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.t('yes'),
              style: const TextStyle(color: AppColors.accentPink),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthController>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF170027), Color(0xFF0A001A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                children: [
                  AppHeader(),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(
                    icon: Icons.currency_exchange_rounded,
                    title: l10n.t('currency'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _OptionsCard(
                    children: CurrencyController.currencies.map((c) {
                      return _OptionTile(
                        leading: _CurrencyBadge(symbol: c.symbol, code: c.code),
                        title: c.code,
                        subtitle: c.label,
                        selected: _pendingCurrency == c.code,
                        onTap: () => setState(() => _pendingCurrency = c.code),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(
                    icon: Icons.language_rounded,
                    title: l10n.t('language'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _OptionsCard(
                    children: _langs.map((lang) {
                      return _OptionTile(
                        leading: _FlagBadge(flag: lang.flag),
                        title: lang.nativeName,
                        subtitle: lang.translatedName,
                        selected: _pendingLocale == lang.code,
                        onTap: () => setState(() => _pendingLocale = lang.code),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  // Save
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.accentViolet],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withValues(alpha: 0.40),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: MaterialButton(
                        onPressed: _save,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.t('save'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 18,
                        color: AppColors.accentPink,
                      ),
                      label: Text(
                        l10n.t('logout'),
                        style: const TextStyle(color: AppColors.accentPink),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.accentPink.withValues(alpha: 0.50),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Languages ────────────────────────────────────────────────────────────────

class _LangOption {
  const _LangOption(this.code, this.flag, this.nativeName, this.translatedName);
  final String code;
  final String flag;
  final String nativeName;
  final String translatedName;
}

const _langs = [
  _LangOption('ru', '🇷🇺', 'Русский', 'Russian'),
  _LangOption('en', '🇬🇧', 'English', 'Английский'),
];

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryPurple),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Options card ──────────────────────────────────────────────────────────────

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: AppColors.darkBorder,
                indent: 56,
              ),
          ],
        ],
      ),
    );
  }
}

// ── Option tile ───────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            leading,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Container(
                      key: const ValueKey(true),
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.accentViolet],
                        ),
                      ),
                      child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                    )
                  : Container(
                      key: const ValueKey(false),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.darkBorder, width: 1.5),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Currency badge ────────────────────────────────────────────────────────────

class _CurrencyBadge extends StatelessWidget {
  const _CurrencyBadge({required this.symbol, required this.code});
  final String symbol;
  final String code;

  static const _colors = {
    'KZT': Color(0xFF00AAFF),
    'RUB': Color(0xFF4CAF50),
    'USD': Color(0xFF27AE60),
    'EUR': Color(0xFF2980B9),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[code] ?? AppColors.primaryPurple;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Flag badge ────────────────────────────────────────────────────────────────

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.flag});
  final String flag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(flag, style: const TextStyle(fontSize: 20)),
    );
  }
}
