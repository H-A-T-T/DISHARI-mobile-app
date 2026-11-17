import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/action_center_drawer.dart';
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

  @override
  void initState() {
    super.initState();
    JonobondhuChatOverlay.globalNavigateTab = _onTabTapped;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dashboard = Provider.of<DashboardProvider>(context, listen: false);

    // If navigating to Locker (2), Deadlines (3), or Dashboard (4), ensure data is loaded
    if (index == 2 || index == 4) {
      if (auth.isLoggedIn) {
        dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1);
      }
    } else if (index == 3) {
      // Deadlines are public civic dates available to all citizens
      dashboard.loadDashboardData(auth.user?.id, isDemo: auth.user?.id == 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isBn = langProvider.isBn;

    final tabs = [
      (
        key: 'home',
        labelBn: 'হোম',
        labelEn: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
      ),
      (
        key: 'services',
        labelBn: 'সেবা সমূহ',
        labelEn: 'Services',
        icon: Icons.search,
        activeIcon: Icons.search,
      ),
      (
        key: 'locker',
        labelBn: 'নাগরিক লকার',
        labelEn: 'Doc Locker',
        icon: Icons.folder_shared_outlined,
        activeIcon: Icons.folder_shared,
      ),
      (
        key: 'deadlines',
        labelBn: 'ডেডলাইন',
        labelEn: 'Deadlines',
        icon: Icons.notifications_none_outlined,
        activeIcon: Icons.notifications_active,
      ),
      (
        key: 'profile',
        labelBn: 'ড্যাশবোর্ড',
        labelEn: 'Account',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];

    // Persistent screens for the 5 bottom navigation tabs
    final List<Widget> screens = [
      HomeScreen(onNavigateTab: _onTabTapped),
      const ServicesScreen(),
      const DocumentLockerTab(),
      const DeadlinesTab(),
      DashboardScreen(onNavigateTab: _onTabTapped),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      // Persistent top AppBar with dual language pill, notifications and hamburger toggle
      appBar: CustomAppBar(
        onNotificationTap: () {
          _onTabTapped(3); // Jump to Deadlines tab
        },
      ),
      // Windows 10 Action Center Drawer (Matches web Navbar.tsx slide-out)
      endDrawer: ActionCenterDrawer(
        onNavigateTab: _onTabTapped,
      ),
      // Persistent body routing: switches only the middle content
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // Windows 10 Mobile Bottom Navigation Bar (1:1 with web MobileNav.tsx)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isActive = _currentIndex == index;

                return Expanded(
                  child: InkWell(
                    onTap: () => _onTabTapped(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFF9FAFB)
                            : Colors.white,
                        border: Border(
                          right: index < tabs.length - 1
                              ? const BorderSide(
                                  color: Color(0xFFF3F4F6),
                                  width: 1,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Windows 10 Active Top Accent Bar (3px Primary Green)
                          if (isActive)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                color: AppColors.primaryGreen,
                              ),
                            ),

                          // Icon and Label
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isActive ? tab.activeIcon : tab.icon,
                                  size: 20,
                                  color: isActive
                                      ? AppColors.primaryGreen
                                      : const Color(0xFF9CA3AF),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isBn ? tab.labelBn : tab.labelEn,
                                  style: isBn
                                      ? GoogleFonts.notoSansBengali(
                                          fontSize: 10.5,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isActive
                                              ? AppColors.primaryGreen
                                              : const Color(0xFF4B5563),
                                          height: 1.2,
                                        )
                                      : GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isActive
                                              ? AppColors.primaryGreen
                                              : const Color(0xFF4B5563),
                                          height: 1.2,
                                        ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
