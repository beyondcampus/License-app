import 'package:flutter/material.dart';

import '../core/widgets/error_state.dart';
import '../features/bookmarks/presentation/bookmarks_screen.dart';
import '../features/chapters/presentation/topic_list_screen.dart';
import '../features/formulas/presentation/formula_sheet_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/quiz/domain/quiz_config.dart';
import '../features/quiz/presentation/quiz_results_screen.dart';
import '../features/quiz/presentation/quiz_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/shell/presentation/root_shell.dart';
import '../features/theory/presentation/theory_reader_screen.dart';

/// Centralized navigation. Route names are constants; screens register here
/// as their features are implemented.
abstract final class AppRoutes {
  static const String root = '/';
  static const String topics = '/topics';
  static const String theory = '/theory';
  static const String quiz = '/quiz';
  static const String results = '/results';
  static const String formulas = '/formulas';
  static const String bookmarks = '/bookmarks';
  static const String search = '/search';
  static const String profile = '/profile';
}

abstract final class AppRouter {
  static Route<dynamic> _badArguments(RouteSettings settings) =>
      MaterialPageRoute(
        settings: settings,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: ErrorState(
              message: 'Invalid arguments for route ${settings.name}'),
        ),
      );

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.root:
        return MaterialPageRoute(
            settings: settings, builder: (_) => const RootShell());
      case AppRoutes.topics:
        if (settings.arguments case final TopicListArgs args) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => TopicListScreen(args: args));
        }
        return _badArguments(settings);
      case AppRoutes.theory:
        if (settings.arguments case final TheoryReaderArgs args) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => TheoryReaderScreen(args: args));
        }
        return _badArguments(settings);
      case AppRoutes.quiz:
        if (settings.arguments case final QuizConfig config) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => QuizScreen(config: config));
        }
        return _badArguments(settings);
      case AppRoutes.results:
        if (settings.arguments case final QuizResultsArgs args) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => QuizResultsScreen(args: args));
        }
        return _badArguments(settings);
      case AppRoutes.formulas:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FormulaSheetScreen(
              initialChapterId: settings.arguments as String?),
        );
      case AppRoutes.bookmarks:
        return MaterialPageRoute(
            settings: settings, builder: (_) => const BookmarksScreen());
      case AppRoutes.search:
        return MaterialPageRoute(
            settings: settings, builder: (_) => const SearchScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(
            settings: settings, builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not found')),
            body: ErrorState(
                message: 'Unknown route: ${settings.name}'),
          ),
        );
    }
  }
}
