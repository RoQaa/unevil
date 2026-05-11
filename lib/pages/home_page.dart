import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'login_page.dart';
import 'text_page.dart';
import 'image_page.dart';
import 'audio_page.dart';
import 'video_page.dart';
import 'history_page.dart';
import 'app_translations.dart';
import 'profile_page.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';
import '../main.dart';

/// الشاشة الرئيسية للتطبيق (Home Screen).
/// تعرض أزرار التنقل السريعة للذهاب لصفحات تحليل (النص، الصورة، الصوت، الفيديو)، وزر لعرض السجل.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _emailNotif = true;
  bool _analysisNotif = true;

  @override
  Widget build(BuildContext context) {
    final String lang =
        Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF18245C),
        elevation: 0,
        centerTitle: true,

        title: Text(
          'Unveil',
          style: AppTypography.titleSmall,
        ),

        leading: PopupMenuButton<int>(
          icon: const Icon(
            Icons.person_outline,
            color: Colors.white,
          ),
          color: const Color(0xFF24356F),
          surfaceTintColor: const Color(0xFF24356F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (value) {
            switch (value) {
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
                break;
              case 2:
                _showLanguageDialog(context, lang);
                break;
              case 3:
                _showNotificationsSnackBar(context, lang);
                break;
              case 4:
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFFF5A623)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppTranslations.text('profile_profile', lang), style: AppTypography.bodySmall.copyWith(color: Colors.white))),
                ],
              ),
            ),
            PopupMenuItem(
              value: 2,
              child: Row(
                children: [
                  const Icon(Icons.language, color: Color(0xFFF5A623)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppTranslations.text('profile_language', lang), style: AppTypography.bodySmall.copyWith(color: Colors.white))),
                ],
              ),
            ),
            PopupMenuItem(
              value: 3,
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Color(0xFFF5A623)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppTranslations.text('notifications', lang), style: AppTypography.bodySmall.copyWith(color: Colors.white))),
                ],
              ),
            ),
            PopupMenuItem(
              value: 4,
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Color(0xFFF5A623)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppTranslations.text('profile_logout', lang), style: AppTypography.bodySmall.copyWith(color: Colors.white))),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Directionality(
        textDirection:
            isArabic
                ? TextDirection.rtl
                : TextDirection.ltr,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ResponsiveWrapper(
            child: Column(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 50,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        AppTranslations.text('welcomeHome', lang),
                        style: AppTypography.bodyMedium.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                _buildFeatureCard(
                  icon: Icons.text_fields_rounded,
                  title: AppTranslations.text('textAnalysis', lang),
                  subtitle: AppTranslations.text('textSub', lang),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TextAnalysisPage(),
                      ),
                    );
                  },
                ),

                _buildFeatureCard(
                  icon: Icons.image_rounded,
                  title: AppTranslations.text('imageAnalysis', lang),
                  subtitle: AppTranslations.text('imageSub', lang),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ImageAnalysisPage(),
                      ),
                    );
                  },
                ),

                _buildFeatureCard(
                  icon: Icons.mic_rounded,
                  title: AppTranslations.text('audioAnalysis', lang),
                  subtitle: AppTranslations.text('audioSub', lang),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AudioAnalysisPage(),
                      ),
                    );
                  },
                ),

                _buildFeatureCard(
                  icon: Icons.videocam_rounded,
                  title: AppTranslations.text('videoAnalysis', lang),
                  subtitle: AppTranslations.text('videoSub', lang),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const VideoAnalysisPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 48,

                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HistoryPage(),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    icon: const Icon(Icons.history),

                    label: Text(
                      AppTranslations.text('viewHistory', lang),
                      style: AppTypography.button,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// دالة مساعدة (Helper) لبناء الكروت (Cards) الموجودة في الصفحة الرئيسية لتجنب تكرار كود التصميم.
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      child: Material(
        color: const Color(0xFF24356F),

        borderRadius: BorderRadius.circular(16),

        child: InkWell(
          borderRadius: BorderRadius.circular(16),

          onTap: onTap,

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white12,

                  child: Icon(
                    icon,
                    color: const Color(0xFFF5A623),
                    size: 22,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        style: AppTypography.labelLarge,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// دالة لعرض سناك بار إعدادات الإشعارات من الأسفل.
  void _showNotificationsSnackBar(BuildContext context, String lang) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1B2B5E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        dismissDirection: DismissDirection.down,
        content: StatefulBuilder(
          builder: (context, setSnackState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: bell icon + title
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF24356F),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFFF5A623),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.text('notifications', lang),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.text('notif_subtitle', lang),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Email notifications toggle
                  _buildNotifRow(
                    label: AppTranslations.text('notif_email', lang),
                    value: _emailNotif,
                    onTap: () {
                      setSnackState(() => _emailNotif = !_emailNotif);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 14),

                  // Analysis completion alerts toggle
                  _buildNotifRow(
                    label: AppTranslations.text('notif_analysis', lang),
                    value: _analysisNotif,
                    onTap: () {
                      setSnackState(() => _analysisNotif = !_analysisNotif);
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// ويدجت مساعدة لبناء صف تبديل الإشعار (Checkbox + Label) داخل السناك بار.
  Widget _buildNotifRow({
    required String label,
    required bool value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: value ? const Color(0xFF2196F3) : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: value ? const Color(0xFF2196F3) : Colors.white38,
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, String currentLang) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            AppTranslations.text('profile_language', currentLang),
            style: AppTypography.titleSmall.copyWith(color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('English', style: AppTypography.bodySmall.copyWith(color: Colors.black)),
                onTap: () {
                  UnveilApp.of(context).changeLanguage('en');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('العربية', style: AppTypography.bodySmall.copyWith(color: Colors.black)),
                onTap: () {
                  UnveilApp.of(context).changeLanguage('ar');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}