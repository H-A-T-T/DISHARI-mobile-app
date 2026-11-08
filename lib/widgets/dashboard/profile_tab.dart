import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/language_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String _selectedDistrict = 'ঢাকা (Dhaka)';
  bool _savedSuccess = false;

  final List<String> _districts = [
    'ঢাকা (Dhaka)',
    'চট্টগ্রাম (Chattogram)',
    'রাজশাহী (Rajshahi)',
    'খুলনা (Khulna)',
    'বরিশাল (Barishal)',
    'সিলেট (Sylhet)',
    'রংপুর (Rangpur)',
    'ময়মনসিংহ (Mymensingh)',
    'নেত্রকোনা (Netrokona)',
    'বগুড়া (Bogra)',
    'কুড়িগ্রাম (Kurigram)',
    'কুমিল্লা (Cumilla)',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.user?.fullName ?? '');
    _emailController = TextEditingController(text: auth.user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.updateProfile(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
    );

    setState(() => _savedSuccess = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _savedSuccess = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final isBn = langProvider.isBn;

    final user = auth.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(
                top: BorderSide(color: AppColors.primaryGreen, width: 3),
                left: BorderSide(color: AppColors.border, width: 1),
                right: BorderSide(color: AppColors.border, width: 1),
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      isBn ? 'নাগরিক প্রোফাইল কার্যপত্র' : 'Citizen Profile Docket',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isBn
                      ? 'এই তথ্যগুলো স্বয়ংক্রিয়ভাবে আপনার সরকারি ফর্ম পূরণে ব্যবহার করা হয়।'
                      : 'This profile data is securely stored and utilized to autofill government application dockets.',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_savedSuccess)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              color: AppColors.lightGreen50,
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    isBn ? 'প্রোফাইল তথ্য সফলভাবে সংরক্ষিত হয়েছে!' : 'Profile updated successfully!',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

          // Profile Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Immutable Citizen ID
                Text(
                  isBn ? 'নাগরিক ট্র্যাকিং আইডি (অপরিবর্তনযোগ্য)' : 'Citizen Docket ID (Immutable)',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: AppColors.bgMuted,
                  child: Text(
                    auth.citizenId,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Full Name
                Text(
                  isBn ? 'পূর্ণ নাম' : 'Full Name',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone (read only)
                Text(
                  isBn ? 'মোবাইল নম্বর' : 'Phone Number',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  color: AppColors.bgMuted,
                  child: Text(
                    user?.phone.isNotEmpty == true ? user!.phone : '+8801712345678',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // District
                Text(
                  isBn ? 'বিভাগ / জেলা' : 'Division / District',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDistrict,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _districts.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(d, style: GoogleFonts.notoSansBengali(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDistrict = val);
                  },
                ),
                const SizedBox(height: 18),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isBn ? 'তথ্য সংরক্ষণ করুন' : 'Save Changes',
                      style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final dashboard = Provider.of<DashboardProvider>(context, listen: false);
                      await dashboard.clearSessionData();
                      await auth.logout();
                    },
                    icon: const Icon(Icons.logout, size: 16, color: AppColors.primaryRed),
                    label: Text(
                      isBn ? 'লগআউট করুন' : 'Log Out',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
