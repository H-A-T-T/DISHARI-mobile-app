import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/jonobondhu_chat_overlay.dart';
import '../widgets/dashboard/document_locker_tab.dart';
import '../widgets/dashboard/deadlines_tab.dart';
import 'home_screen.dart';
import 'services_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dashboard = Provider.of<DashboardProvider>(context, listen: false);

    // If navigating to Locker (2), Deadlines (3), or Dashboard (4), ensure data is loaded
    if (index == 2 || index == 3 || index == 4) {
      if (auth.isLoggedIn) {
        dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    final tabs = [
      (labelBn: 'হোম', labelEn: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
      (labelBn: 'সেবা সমূহ', labelEn: 'Services', icon: Icons.search, activeIcon: Icons.search),
      (labelBn: 'নাগরিক লকার', labelEn: 'Doc Locker', icon: Icons.folder_shared_outlined, activeIcon: Icons.folder_shared),
      (labelBn: 'ডেডলাইন', labelEn: 'Deadlines', icon: Icons.notifications_none_outlined, activeIcon: Icons.notifications_active),
      (labelBn: 'ড্যাশবোর্ড', labelEn: 'Account', icon: Icons.person_outline, activeIcon: Icons.person),
    ];

    // Persistent screens for the 5 bottom navigation tabs
    final List<Widget> screens = [
      HomeScreen(onNavigateTab: _onTabTapped),
      const ServicesScreen(),
      const DocumentLockerTab(),
      const DeadlinesTab(),
      DashboardScreen(onNavigateTab: _onTabTapped),
    ];

    return JonobondhuChatOverlay(
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        // Persistent fixed top AppBar with SafeArea to prevent status bar overlap
        appBar: CustomAppBar(
          onNotificationTap: () {
            _onTabTapped(3); // Jump to Deadlines tab
          },
        ),
        // Persistent body routing: switches only the middle content
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        // Persistent fixed bottom navigation bar
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgSurface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.bgSurface,
            elevation: 0,
            selectedItemColor: AppColors.primaryGreen,
            unselectedItemColor: AppColors.textMuted,
            selectedLabelStyle: GoogleFonts.notoSansBengali(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
            unselectedLabelStyle: GoogleFonts.notoSansBengali(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            items: tabs.map((tab) {
              return BottomNavigationBarItem(
                icon: Icon(tab.icon, size: 20),
                activeIcon: Icon(tab.activeIcon, size: 20),
                label: isBn ? tab.labelBn : tab.labelEn,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
