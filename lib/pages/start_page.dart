import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'app_translations.dart';
import 'login_page.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';

/// صفحة البداية الخاصة بالتطبيق، تعرض اللوجو الخاص بـ Unveil AI وزرين للبدء والانتقال للموقع.
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

/// الحالة (State) الخاصة بصفحة البداية، وتحتوي على المتحكمات (Controllers) المسؤولة عن الأنيميشن (الحركة).
class _StartPageState extends State<StartPage> with TickerProviderStateMixin {
  late AnimationController logoController;
  late AnimationController textController;
  late AnimationController buttonController;

  late Animation<double> logoAnimation;
  late Animation<double> textAnimation;
  late Animation<Offset> buttonAnimation;

  /// يتم استدعاء هذه الدالة عند بداية تحميل الصفحة، وهنا نقوم بتجهيز الأنيميشن (الحركات) للوجو والنصوص والأزرار وتشغيلها بالتتابع.
  @override
  void initState() {
    super.initState();

    logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    logoAnimation = CurvedAnimation(
      parent: logoController,
      curve: Curves.elasticOut,
    );

    textAnimation = CurvedAnimation(
      parent: textController,
      curve: Curves.easeIn,
    );

    buttonAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: buttonController,
      curve: Curves.easeOutBack,
    ));

    logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) buttonController.forward();
    });
  }

  /// تنظيف وإيقاف الأنيميشن من الذاكرة عند الخروج من الصفحة لمنع تسريب الذاكرة (Memory Leak).
  @override
  void dispose() {
    logoController.dispose();
    textController.dispose();
    buttonController.dispose();
    super.dispose();
  }

  /// دالة لفتح الرابط الخارجي (مثل فتح موقع جوجل كروم) في المتصفح الخارجي الخاص بالنظام.
  Future<void> _launchUrl() async {
    const url = 'https://www.google.com/chrome/';//////////////////////////////////////////////////////////////////////////////////////////
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url', style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF24356F),
          ),
        );
      }
    }
  }

  /// دالة الـ build تقوم ببناء واجهة الصفحة. نستخدم Directionality لدعم اللغتين العربية والإنجليزية (RTL و LTR).
  /// وتحتوي على زر تغيير اللغة (PopupMenuButton) والنصوص والأزرار التي تتحرك للداخل.
  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF18245C),
              Color(0xFF24356F),
            ],
          ),
        ),
        child: SafeArea(
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.language, color: Colors.white, size: 24),
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (String value) {
                        UnveilApp.of(context).changeLanguage(value);
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'en',
                          child: Text('English', style: AppTypography.bodySmall.copyWith(color: Colors.black)),
                        ),
                        PopupMenuItem<String>(
                          value: 'ar',
                          child: Text('العربية', style: AppTypography.bodySmall.copyWith(color: Colors.black)),
                        ),
                        PopupMenuItem<String>(
                          value: 'es',
                          child: Text('Español', style: AppTypography.bodySmall.copyWith(color: Colors.black)),
                        ),
                        PopupMenuItem<String>(
                          value: 'fr',
                          child: Text('Français', style: AppTypography.bodySmall.copyWith(color: Colors.black)),
                        ),
                        PopupMenuItem<String>(
                          value: 'zh',
                          child: Text('中文', style: AppTypography.bodySmall.copyWith(color: Colors.black)),
                        ),
                        PopupMenuItem<String>(
                          value: 'hi',
                          child: Text('हिन्दी', style: AppTypography.bodySmall.copyWith(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10.h),
                    child: ResponsiveWrapper(
                      child: Column(
                        children: [
                  SizedBox(height: 50.h),
                  ScaleTransition(
                    scale: logoAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 100,
                      ),
                    ),
                  ),
                  SizedBox(height: 35.h),
                  FadeTransition(
                    opacity: textAnimation,
                    child: Column(
                      children: [
                        Text(
                          "Unveil AI",
                          style: AppTypography.titleMedium.copyWith(
                            color: const Color(0xFFF5A623),
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 15.h),
                        Text(
                          AppTranslations.text('appDescription', lang),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 60.h),
                  SlideTransition(
                    position: buttonAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5A623),
                              elevation: 8,
                              shadowColor: const Color(0x44F5A623),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                              ),
                            ),
                            child: Text(
                              AppTranslations.text('getStarted', lang),
                              style: AppTypography.button,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _launchUrl,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E6BFF),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                              ),
                            ),
                            child: Text(
                              AppTranslations.text('visitWeb', lang),
                              style: AppTypography.button,
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "v1.0.0",
                          style: AppTypography.overline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
}
