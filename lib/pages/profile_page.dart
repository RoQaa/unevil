import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import 'login_page.dart';
import '../core/app_text_styles.dart';
import '../core/responsive_wrapper.dart';
import 'app_translations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String lang =
        Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18245C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(AppTranslations.text('profile_profile', lang)),
      ),
      body: Directionality(
        textDirection: isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: user == null
            ? Center(
                child: Text(
                  AppTranslations.text('profile_noUser', lang),
                  style: AppTextStyles.bodyMedium,
                ),
              )
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.hasError) {
                    return Center(
                      child: Text(
                        AppTranslations.text('profile_errorLoading', lang),
                        style: AppTextStyles.bodySmall,
                      ),
                    );
                  }
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFF5A623)));
                  }
                  final profileData = profileSnapshot.data?.data() as Map<String, dynamic>?;

                  final String fullName = profileData?['fullName'] ?? '--';
                  final String age = profileData?['age']?.toString() ?? '--';
                  final String gender = profileData?['gender'] ?? '--';

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('history')
                        .snapshots(),
                    builder: (context, historySnapshot) {
                      // Even if history fails, we still show the profile info
                      final docs = historySnapshot.data?.docs ?? [];

                      int textCount = 0;
                      int imageCount = 0;
                      int audioCount = 0;
                      int videoCount = 0;

                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>?;
                        if (data == null) continue;
                        
                        final type = data['type'];
                        if (type == 'text') textCount++;
                        else if (type == 'image') imageCount++;
                        else if (type == 'audio') audioCount++;
                        else if (type == 'video') videoCount++;
                      }

                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: ResponsiveWrapper(
                          child: ListView(
                            children: [
                            Center(
                              child:
                                  CircleAvatar(
                                radius: 40.r,
                                backgroundColor: const Color(0xFFF5A623),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 40.r,
                                ),
                              ),
                            ),

                            SizedBox(
                                height:
                                    20.h),

                            _infoCard(
                              icon: Icons
                                  .badge_outlined,
                              label: AppTranslations.text('profile_fullName', lang),
                              value:
                                  fullName,
                            ),

                            SizedBox(
                                height:
                                    14.h),

                            _infoCard(
                              icon: Icons
                                  .email_outlined,
                              label: AppTranslations.text('profile_email', lang),
                              value:
                                  user.email ??
                                      '--',
                            ),

                            SizedBox(
                                height:
                                    14.h),

                            _infoCard(
                              icon: Icons
                                  .person_outline,
                              label: AppTranslations.text('profile_gender', lang),
                              value:
                                  _translatedGender(
                                      gender,
                                      lang),
                            ),

                            SizedBox(
                                height:
                                    14.h),

                            _infoCard(
                              icon: Icons
                                  .cake_outlined,
                              label: AppTranslations.text('profile_age', lang),
                              value:
                                  age,
                            ),

                            SizedBox(
                                height:
                                    18.h),

                            Container(
                              padding: EdgeInsets.all(20.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFF24356F),
                                borderRadius: BorderRadius.circular(18.r),
                              ),
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        color: const Color(0xFFF5A623),
                                        size: 24.r,
                                      ),
                                      SizedBox(height: 10.h),
                                      Text(
                                        AppTranslations.text('profile_statistics', lang),
                                        style: AppTextStyles.h3,
                                      ),
                                    ],
                                  ),

                                  SizedBox(
                                      height:
                                          16.h),

                                  _statRow(
                                    AppTranslations.text('profile_analysisCount', lang),
                                    docs.length
                                        .toString(),
                                  ),

                                  SizedBox(
                                      height:
                                          10.h),

                                  _statRow(
                                    AppTranslations.text('profile_text', lang),
                                    textCount
                                        .toString(),
                                  ),

                                  SizedBox(
                                      height:
                                          10.h),

                                  _statRow(
                                    AppTranslations.text('profile_image', lang),
                                    imageCount
                                        .toString(),
                                  ),

                                  SizedBox(
                                      height:
                                          10.h),

                                  _statRow(
                                    AppTranslations.text('profile_audio', lang),
                                    audioCount
                                        .toString(),
                                  ),

                                  SizedBox(
                                      height:
                                          10.h),

                                  _statRow(
                                    AppTranslations.text('profile_video', lang),
                                    videoCount
                                        .toString(),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(
                                height:
                                    18.h),

                            _languageCard(
                                context,
                                lang),

                            SizedBox(
                                height:
                                    14.h),

                            _logoutCard(
                                context,
                                lang),
                          ],
                        ),
                      ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  /// دالة مساعدة لرسم كارت يعرض بيانات المستخدم الأساسية (الاسم، الإيميل، العمر).
  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding:
          EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color:
            const Color(0xFF24356F),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: Colors.white12,
            child: Icon(
              icon,
              color: const Color(0xFFF5A623),
              size: 20.r,
            ),
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium,
                ),

                SizedBox(
                    height: 4.h),

                Text(
                  value,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// دالة مساعدة لرسم صف يعرض إحصائية معينة (مثل عدد تحليلات الصور).
  Widget _statRow(
    String label,
    String value,
  ) {
    return Container(
      padding:
          EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius:
            BorderRadius.circular(
                14.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 15.sp),
            ),
          ),
          Text(
            value,
              style: AppTextStyles.h3.copyWith(color: const Color(0xFFF5A623), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// دالة مساعدة لرسم كارت يحتوي على زر تغيير لغة التطبيق.
  Widget _languageCard(
    BuildContext context,
    String lang,
  ) {
    return Container(
      padding:
          EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color:
            const Color(0xFF24356F),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor:
                Colors.white12,
            child: Icon(
              Icons.language,
              color: const Color(0xFFF5A623),
              size: 20.r,
            ),
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Text(
              AppTranslations.text('profile_language', lang),
                      style: AppTextStyles.h2.copyWith(fontSize: 18.sp),
            ),
          ),

          PopupMenuButton<
              String>(
            color: Colors.white,
            icon: const Icon(
              Icons.arrow_drop_down,
              color:
                  Colors.white,
            ),
            onSelected:
                (value) {
              UnveilApp.of(
                      context)
                  .changeLanguage(
                      value);
            },
            itemBuilder:
                (context) =>
                    const [
              PopupMenuItem(
                value: 'en',
                child: Text('English', style: TextStyle(color: Colors.black)),
              ),
              PopupMenuItem(
                value: 'ar',
                child: Text('العربية', style: TextStyle(color: Colors.black)),
              ),
              PopupMenuItem(
                value: 'es',
                child: Text('Español', style: TextStyle(color: Colors.black)),
              ),
              PopupMenuItem(
                value: 'fr',
                child: Text('Français', style: TextStyle(color: Colors.black)),
              ),
              PopupMenuItem(
                value: 'zh',
                child: Text('中文', style: TextStyle(color: Colors.black)),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Text('हिन्दी', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// دالة مساعدة لرسم كارت وزر تسجيل الخروج من التطبيق.
  Widget _logoutCard(
    BuildContext context,
    String lang,
  ) {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth
            .instance
            .signOut();

        if (!context.mounted)
          return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const LoginPage(),
          ),
          (route) => false,
        );
      },
      child: Container(
        padding:
            const EdgeInsets.all(
                18),
        decoration: BoxDecoration(
          color:
              const Color(
                  0xFF24356F),
          borderRadius:
              BorderRadius.circular(
                  18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.r,
              backgroundColor:
                  Colors.white12,
              child: Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: 22.r,
              ),
            ),

            SizedBox(
                width: 14.w),

            Expanded(
              child: Text(
                AppTranslations.text('profile_logout', lang),
                style: AppTypography.bodySmall,
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              color:
                  Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _translatedGender(
    String gender,
    String lang,
  ) {
    final data = {
      'Male': {
        'en': 'Male',
        'ar': 'ذكر',
      },
      'Female': {
        'en': 'Female',
        'ar': 'أنثى',
      },
      'Other': {
        'en': 'Other',
        'ar': 'آخر',
      },
      'Prefer not to say': {
        'en': 'Prefer not to say',
        'ar': 'أفضل عدم القول',
      },
      '--': {
        'en': '--',
        'ar': '--',
      },
    };

    return data[gender]?[lang] ??
        data[gender]?['en'] ??
        gender;
  }

}