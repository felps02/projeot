import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:psicossocial_app/app.dart';
import 'package:psicossocial_app/providers/auth_provider.dart';
import 'package:psicossocial_app/providers/assessment_provider.dart';
import 'package:psicossocial_app/providers/dashboard_provider.dart';
import 'package:psicossocial_app/providers/theme_provider.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AssessmentProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const PsicossocialApp(),
      ),
    );

    expect(find.text('Psicossocial'), findsOneWidget);
  });
}
