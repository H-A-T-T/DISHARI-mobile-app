import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobileapp/providers/auth_provider.dart';
import 'package:mobileapp/providers/dashboard_provider.dart';
import 'package:mobileapp/providers/language_provider.dart';
import 'package:mobileapp/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders and toggles phone and email mode correctly', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Brand elements
    expect(find.text('নাগরিক লগইন'), findsOneWidget);
    expect(find.text('মোবাইল নম্বর'), findsWidgets);
    expect(find.text('ওটিপি কোড পাঠান'), findsOneWidget);

    // Verify Password input is NOT shown in Phone Mode
    expect(find.text('পাসওয়ার্ড'), findsNothing);

    // Toggle to Email Mode
    await tester.tap(find.text('ইমেইল ঠিকানা'));
    await tester.pumpAndSettle();

    // In Email mode, password is now visible
    expect(find.text('পাসওয়ার্ড'), findsOneWidget);
    expect(find.text('লগইন করুন'), findsOneWidget);
  });
}
