import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/mobile/home_screen.dart';
import '../screens/mobile/assessment_screen.dart';
import '../screens/mobile/history_screen.dart';
import '../screens/mobile/profile_screen.dart';
import '../screens/mobile/emergency_screen.dart';
import '../screens/web/dashboard_screen.dart';
import '../screens/web/team_screen.dart';
import '../screens/web/reports_screen.dart';
import '../screens/web/alerts_screen.dart';
import '../screens/web/heatmap_screen.dart';
import '../screens/web/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Mobile
  static const String mobileHome = '/mobile/home';
  static const String assessment = '/mobile/assessment';
  static const String history = '/mobile/history';
  static const String profile = '/mobile/profile';
  static const String emergency = '/mobile/emergency';

  // Web
  static const String webDashboard = '/web/dashboard';
  static const String webTeam = '/web/team';
  static const String webReports = '/web/reports';
  static const String webAlerts = '/web/alerts';
  static const String webHeatmap = '/web/heatmap';
  static const String webSettings = '/web/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());
      case login:
        return _buildRoute(const LoginScreen());
      case register:
        return _buildRoute(const RegisterScreen());
      case mobileHome:
        return _buildRoute(const MobileHomeScreen());
      case assessment:
        return _buildRoute(const AssessmentScreen());
      case history:
        return _buildRoute(const HistoryScreen());
      case profile:
        return _buildRoute(const ProfileScreen());
      case emergency:
        return _buildRoute(const EmergencyScreen());
      case webDashboard:
        return _buildRoute(const DashboardScreen());
      case webTeam:
        return _buildRoute(const TeamScreen());
      case webReports:
        return _buildRoute(const ReportsScreen());
      case webAlerts:
        return _buildRoute(const AlertsScreen());
      case webHeatmap:
        return _buildRoute(const HeatmapScreen());
      case webSettings:
        return _buildRoute(const SettingsScreen());
      default:
        return _buildRoute(const SplashScreen());
    }
  }

  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
