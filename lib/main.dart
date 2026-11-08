import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/language_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/services_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(
        "Notice: .env file not loaded ($e), using default environment configuration.");
  }

  runApp(const DishariApp());
}

class DishariApp extends StatelessWidget {
  const DishariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return MaterialApp(
            title: langProvider.isBn ? 'দিশারী' : 'Dishari',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
