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

/// الشاشة الرئيسية للتطبيق (Home Screen).
/// تعرض أزرار التنقل السريعة للذهاب لصفحات تحليل (النص، الصورة، الصوت، الفيديو)، وزر لعرض السجل.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ProfilePage(),
              ),
            );
          },
          icon: const Icon(
            Icons.person_outline,
            color: Colors.white,
          ),
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
}