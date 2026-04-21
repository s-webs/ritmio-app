import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/l10n_x.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isRegister = false;
  bool _obscurePassword = true;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode() {
    setState(() => _isRegister = !_isRegister);
    _fadeController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          const _AuthBackground(),

          // Scrollable content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.06),

                        // Logo
                        _Logo(),

                        SizedBox(height: size.height * 0.05),

                        // Card
                        _AuthCard(
                          formKey: _formKey,
                          isRegister: _isRegister,
                          obscurePassword: _obscurePassword,
                          nameCtrl: _name,
                          emailCtrl: _email,
                          passwordCtrl: _password,
                          onTogglePassword: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          onSubmit: auth.isLoading ? null : _submit,
                          onSwitchMode: auth.isLoading ? null : _switchMode,
                          isLoading: auth.isLoading,
                          error: auth.error,
                        ),

                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    if (_isRegister) {
      await auth.register(_name.text.trim(), _email.text.trim(), _password.text);
    } else {
      await auth.login(_email.text.trim(), _password.text);
    }
  }
}

// ── Background ──────────────────────────────────────────────────────────────

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Base dark
          Container(color: AppColors.darkBackground),

          // Top purple radial glow
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.35),
                    AppColors.deepPurple.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom pink glow
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPink.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo ────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Glow container behind logo
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.50),
                blurRadius: 40,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: AppColors.accentPink.withValues(alpha: 0.25),
                blurRadius: 60,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: SvgPicture.asset(
              'assets/images/logo.svg',
              width: 96,
              height: 96,
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // App name
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.darkTextPrimary, AppColors.darkTextSecondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'Ritmio',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Ваш личный помощник',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.darkTextSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Auth Card ────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.formKey,
    required this.isRegister,
    required this.obscurePassword,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onSwitchMode,
    required this.isLoading,
    this.error,
  });

  final GlobalKey<FormState> formKey;
  final bool isRegister;
  final bool obscurePassword;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSubmit;
  final VoidCallback? onSwitchMode;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.darkBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.12),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkSurface.withValues(alpha: 0.95),
            AppColors.darkSurfaceSoft.withValues(alpha: 0.90),
          ],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              isRegister ? 'Создать аккаунт' : 'Добро пожаловать',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isRegister
                  ? 'Зарегистрируйтесь, чтобы начать'
                  : 'Войдите в свой аккаунт',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkTextSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Name field (register only)
            if (isRegister) ...[
              _FieldLabel('Имя'),
              const SizedBox(height: 6),
              TextFormField(
                controller: nameCtrl,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Ваше имя',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.t('invalidName') : null,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Email
            _FieldLabel('Email'),
            const SizedBox(height: 6),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? l10n.t('invalidEmail') : null,
            ),

            const SizedBox(height: AppSpacing.sm),

            // Password
            _FieldLabel('Пароль'),
            const SizedBox(height: 6),
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit?.call(),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.darkTextSecondary,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 8) ? l10n.t('invalidPassword') : null,
            ),

            // Error
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentPink.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.accentPink,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: AppColors.accentPink,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Submit button
            _GradientButton(
              onPressed: onSubmit,
              isLoading: isLoading,
              label: isRegister ? 'Создать аккаунт' : 'Войти',
            ),

            const SizedBox(height: AppSpacing.sm),

            // Switch mode
            Center(
              child: TextButton(
                onPressed: onSwitchMode,
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkTextSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: isRegister
                            ? 'Уже есть аккаунт? '
                            : 'Нет аккаунта? ',
                      ),
                      TextSpan(
                        text: isRegister ? 'Войти' : 'Зарегистрироваться',
                        style: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.accentViolet],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: onPressed == null ? AppColors.darkSurfaceSoft : null,
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: MaterialButton(
          onPressed: onPressed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}
