import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_strings.dart';
import 'core/config/supabase_config.dart';
import 'core/services/app_dependencies.dart';
import 'core/services/db_factory/db_factory.dart';
import 'core/services/prefs_service.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/analytics/state/analytics_provider.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/state/auth_provider.dart';
import 'features/chapters/state/chapter_provider.dart';
import 'features/flashcards/state/flashcard_provider.dart';
import 'features/shell/presentation/root_shell.dart';
import 'routes/app_router.dart';

Future<void> main() async {
  // Errors are logged, never allowed to take the whole app down (Stage 11).
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };
      configureDatabaseFactory();
      final supabaseClient = await _initializeSupabase();
      final prefs = await PrefsService.init();
      final deps = AppDependencies(
        prefs: prefs,
        supabaseClient: supabaseClient,
      );
      // Ads disabled temporarily.
      // unawaited(deps.adManager.initialize());
      runApp(ExamPrepApp(deps: deps));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

/// The app is online-only: all study content and user data live in
/// Supabase, so it is always initialized.
Future<SupabaseClient> _initializeSupabase() async {
  const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: SupabaseConfig.url,
  );
  const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: SupabaseConfig.publishableKey,
  );

  await Supabase.initialize(url: url, publishableKey: publishableKey);
  return Supabase.instance.client;
}

class ExamPrepApp extends StatelessWidget {
  const ExamPrepApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: deps),
        Provider<PrefsService>.value(value: deps.prefs),
        ChangeNotifierProvider(
          create: (_) => ChapterProvider(
            deps.chapterRepository,
            deps.progressRepository,
            deps.practiceProgressRepository,
          )..load(),
        ),
        if (deps.authRepository != null)
          ChangeNotifierProvider(
            create: (context) => AuthProvider(
              deps.authRepository!,
              contentCache: deps.contentCache,
              contentSource: deps.contentSource,
              onContentInvalidated: (signedIn) async {
                final chapters = context.read<ChapterProvider>();
                if (signedIn) {
                  await chapters.reloadContent();
                } else {
                  chapters.clearContent();
                }
              },
            ),
          ),
        // Provider<AdManager>.value(value: deps.adManager),
        ChangeNotifierProvider(create: (_) => ThemeProvider(deps.prefs)),
        ChangeNotifierProvider(
          create: (_) =>
              AnalyticsProvider(deps.resultsRepository, deps.chapterRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => FlashcardProvider(deps.flashcardRepository),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: theme.mode,
          home: deps.authRepository == null
              ? const _LocalEntry()
              : const _AuthEntry(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}

/// Without a Supabase client (tests only) there is no sign-in step.
class _LocalEntry extends StatelessWidget {
  const _LocalEntry();

  @override
  Widget build(BuildContext context) => const RootShell();
}

class _AuthEntry extends StatelessWidget {
  const _AuthEntry();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isSignedIn ? const RootShell() : const AuthScreen();
  }
}
