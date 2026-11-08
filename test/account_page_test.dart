import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/providers/dashboard_provider.dart';
import 'package:mobileapp/providers/language_provider.dart';
import 'package:mobileapp/screens/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DashboardScreen renders in authenticated mode without color/decoration assertion error', (tester) async {
    final authProvider = AuthProvider();
    final dashboardProvider = DashboardProvider();
    final languageProvider = LanguageProvider();

    await authProvider.loginAsDemoCitizen();
    await dashboardProvider.seedDemoData();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: languageProvider),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: dashboardProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      ),
    );

    // Verify user profile header
    expect(find.text('নাগরিক ট্র্যাকিং আইডি: BD-USER-782'), findsOneWidget);
    expect(find.text('সক্রিয় নাগরিক'), findsOneWidget);

    // Verify subtab chips
    expect(find.text('সারসংক্ষেপ (হোম)'), findsOneWidget);
    expect(find.text('আমার আবেদনসমূহ'), findsOneWidget);
    expect(find.text('নাগরিক প্রোফাইল'), findsOneWidget);

    // No assertion error occurred
    expect(tester.takeException(), isNull);
  });
}
