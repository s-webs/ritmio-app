import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/widgets/wave_loader.dart';
import 'core/localization/locale_controller.dart';
import 'core/settings/currency_controller.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/storage/auth_session.dart';
import 'core/theme/app_theme.dart';
import 'features/app/presentation/app_shell.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/categories/data/categories_repository.dart';
import 'features/categories/presentation/categories_controller.dart';
import 'features/voice/data/voice_repository.dart';
import 'features/voice/presentation/voice_controller.dart';
import 'features/dashboard/data/summary_repository.dart';
import 'features/dashboard/presentation/dashboard_controller.dart';
import 'features/tasks/data/tasks_repository.dart';
import 'features/tasks/presentation/tasks_controller.dart';
import 'features/transactions/data/transactions_repository.dart';
import 'features/transactions/presentation/transactions_controller.dart';

void main() {
  runApp(const RitmioApp());
}

class RitmioApp extends StatelessWidget {
  const RitmioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(
      baseUrl: AppConfig.apiBaseUrl,
      tokenProvider: () => AuthSession.token,
    );
    return MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        Provider(create: (_) => AuthRepository(apiClient)),
        ChangeNotifierProvider(
          create: (context) =>
              AuthController(repository: context.read<AuthRepository>())..init(),
        ),
        Provider(create: (_) => SummaryRepository(apiClient)),
        ChangeNotifierProvider(
          create: (context) => DashboardController(context.read<SummaryRepository>()),
        ),
        Provider(create: (_) => TransactionsRepository(apiClient)),
        ChangeNotifierProvider(
          create: (context) =>
              TransactionsController(context.read<TransactionsRepository>()),
        ),
        Provider(create: (_) => TasksRepository(apiClient)),
        ChangeNotifierProvider(
          create: (context) => TasksController(context.read<TasksRepository>()),
        ),
        Provider(create: (_) => CategoriesRepository(apiClient)),
        ChangeNotifierProvider(
          create: (context) =>
              CategoriesController(context.read<CategoriesRepository>()),
        ),
        Provider(create: (_) => VoiceRepository(apiClient)),
        ChangeNotifierProvider(
          create: (context) =>
              VoiceController(context.read<VoiceRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => CurrencyController()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
      ],
      child: Consumer<LocaleController>(
        builder: (context, localeController, _) => MaterialApp(
          locale: localeController.locale,
          onGenerateTitle: (context) => AppLocalizations.of(context).t('appName'),
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AppBootstrap(),
        ),
      ),
    );
  }
}

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.initialized) {
      return const Scaffold(body: Center(child: WaveLoader()));
    }
    if (!auth.isAuthorized) return const AuthScreen();
    return const AppShell();
  }
}
