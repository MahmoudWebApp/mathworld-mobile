import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/error_notebook_screen.dart';
import '../screens/dashboard/solved_screen.dart';
import '../screens/dashboard/leaderboard_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/problems/problem_details_screen.dart';
import '../screens/problems/problems_list_screen.dart';
import '../screens/settings/privacy_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/stages/stage_categories_screen.dart';
import '../screens/stages/learning_stage_screen.dart';

/// Central route names and route builders for the application.
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String solved = '/solved';
  static const String errorNotebook = '/error-notebook';
  static const String stageCategories = '/stage-categories';
  static const String learningStage = '/learning-stage';
  static const String leaderboard = '/leaderboard';
  static const String problems = '/problems';
  static const String problemDetails = '/problem-details';
  static const String privacy = '/privacy';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (_) => const SplashScreen(),
      login: (_) => const LoginScreen(),
      register: (_) => const RegisterScreen(),
      home: (_) => const MainShell(),
      solved: (_) => const SolvedScreen(),
      errorNotebook: (_) => const ErrorNotebookScreen(),
      stageCategories: (_) => const StageCategoriesScreen(),
      learningStage: (_) => const LearningStageScreen(),
      leaderboard: (_) => const LeaderboardScreen(),
      problems: (_) => const ProblemsListScreen(),
      problemDetails: (_) => const ProblemDetailsScreen(),
      privacy: (_) => const PrivacyScreen(),
    };
  }
}
