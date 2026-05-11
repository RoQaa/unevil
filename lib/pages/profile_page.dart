import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import '../core/app_text_styles.dart';
import '../core/responsive_wrapper.dart';
import 'app_translations.dart';

/// صفحة الملف الشخصي - تعرض بيانات المستخدم وتتيح تعديل الاسم والجنس والعمر.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // بيانات المستخدم المعروضة
  String fullName = '--';
  String age = '--';
  String gender = '--';
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// تحميل بيانات المستخدم من Firestore
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (mounted) {
        setState(() {
          fullName = data?['fullName'] ?? '--';
          age = data?['age']?.toString() ?? '--';
          gender = data?['gender'] ?? '--';
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// فتح ديالوج تعديل الاسم والجنس والعمر
  Future<void> _openEditDialog(String lang) async {
    final nameController = TextEditingController(text: fullName == '--' ? '' : fullName);
    final ageController = TextEditingController(text: age == '--' ? '' : age);
    String selectedGender = gender == '--' ? 'Male' : gender;

    final genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF24356F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              AppTranslations.text('profile_editTitle', lang),
              style: AppTextStyles.h2,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // حقل الاسم
                  Text(
                    AppTranslations.text('profile_fullName', lang),
                    style: AppTextStyles.labelMedium,
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFFF5A623),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      hintText: AppTranslations.text('fullName', lang),
                      hintStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // حقل العمر
                  Text(
                    AppTranslations.text('profile_age', lang),
                    style: AppTextStyles.labelMedium,
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFFF5A623),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      hintText: AppTranslations.text('age', lang),
                      hintStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // اختيار الجنس
                  Text(
                    AppTranslations.text('profile_gender', lang),
                    style: AppTextStyles.labelMedium,
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedGender,
                        dropdownColor: const Color(0xFF24356F),
                        style: const TextStyle(color: Colors.white),
                        items: genderOptions.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(
                              _translatedGender(g, lang),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedGender = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  AppTranslations.text('profile_cancel', lang),
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop({
                    'fullName': nameController.text.trim(),
                    'age': ageController.text.trim(),
                    'gender': selectedGender,
                  });
                },
                child: Text(AppTranslations.text('profile_save', lang)),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      await _saveProfile(result, lang);
    }
  }

  /// حفظ البيانات المعدلة في Firestore
  Future<void> _saveProfile(Map<String, String> data, String lang) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // التحقق من صحة البيانات
    final newName = data['fullName'] ?? '';
    final newAgeStr = data['age'] ?? '';
    final newGender = data['gender'] ?? '';

    if (newName.isEmpty) {
      _showSnackBar(AppTranslations.text('profile_updateFailed', lang));
      return;
    }

    final int? newAge = int.tryParse(newAgeStr);
    if (newAgeStr.isEmpty || newAge == null || newAge < 5 || newAge > 100) {
      _showSnackBar(AppTranslations.text('validAgeError', lang));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': newName,
        'age': newAge,
        'gender': newGender,
      });

      if (mounted) {
        setState(() {
          fullName = newName;
          age = newAge.toString();
          gender = newGender;
        });
        _showSnackBar(AppTranslations.text('profile_updateSuccess', lang));
      }
    } catch (_) {
      _showSnackBar(AppTranslations.text('profile_updateFailed', lang));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18245C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(AppTranslations.text('profile_profile', lang)),
        actions: [
          // زر التعديل في الـ AppBar
          if (!_isLoading && !_hasError && user != null)
            IconButton(
              onPressed: () => _openEditDialog(lang),
              icon: const Icon(Icons.edit_outlined, color: Color(0xFFF5A623)),
              tooltip: AppTranslations.text('profile_edit', lang),
            ),
        ],
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: user == null
            ? Center(
                child: Text(
                  AppTranslations.text('profile_noUser', lang),
                  style: AppTextStyles.bodyMedium,
                ),
              )
            : _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF5A623),
                    ),
                  )
                : _hasError
                    ? Center(
                        child: Text(
                          AppTranslations.text('profile_errorLoading', lang),
                          style: AppTextStyles.bodySmall,
                        ),
                      )
                    : _buildProfileBody(context, user, lang),
      ),
    );
  }

  /// رسم جسم صفحة الملف الشخصي
  Widget _buildProfileBody(BuildContext context, User user, String lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .snapshots(),
      builder: (context, historySnapshot) {
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
                // صورة المستخدم الرمزية
                Center(
                  child: CircleAvatar(
                    radius: 40.r,
                    backgroundColor: const Color(0xFFF5A623),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40.r,
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // كارت الاسم
                _infoCard(
                  icon: Icons.badge_outlined,
                  label: AppTranslations.text('profile_fullName', lang),
                  value: fullName,
                ),

                SizedBox(height: 14.h),

                // كارت البريد الإلكتروني
                _infoCard(
                  icon: Icons.email_outlined,
                  label: AppTranslations.text('profile_email', lang),
                  value: user.email ?? '--',
                ),

                SizedBox(height: 14.h),

                // كارت الجنس
                _infoCard(
                  icon: Icons.person_outline,
                  label: AppTranslations.text('profile_gender', lang),
                  value: _translatedGender(gender, lang),
                ),

                SizedBox(height: 14.h),

                // كارت العمر
                _infoCard(
                  icon: Icons.cake_outlined,
                  label: AppTranslations.text('profile_age', lang),
                  value: age,
                ),

                SizedBox(height: 18.h),

                // قسم الإحصائيات
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24356F),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: const Color(0xFFF5A623),
                            size: 24.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            AppTranslations.text('profile_statistics', lang),
                            style: AppTextStyles.h3,
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      _statRow(
                        AppTranslations.text('profile_analysisCount', lang),
                        docs.length.toString(),
                      ),
                      SizedBox(height: 10.h),
                      _statRow(
                        AppTranslations.text('profile_text', lang),
                        textCount.toString(),
                      ),
                      SizedBox(height: 10.h),
                      _statRow(
                        AppTranslations.text('profile_image', lang),
                        imageCount.toString(),
                      ),
                      SizedBox(height: 10.h),
                      _statRow(
                        AppTranslations.text('profile_audio', lang),
                        audioCount.toString(),
                      ),
                      SizedBox(height: 10.h),
                      _statRow(
                        AppTranslations.text('profile_video', lang),
                        videoCount.toString(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18.h),

                // زر تعديل الملف الشخصي
                SizedBox(
                  height: 52.h,
                  child: ElevatedButton.icon(
                    onPressed: () => _openEditDialog(lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: Text(
                      AppTranslations.text('profile_edit', lang),
                      style: AppTextStyles.button,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// دالة مساعدة لرسم كارت يعرض بيانات المستخدم (مع أيقونة تعديل اختيارية).
  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFF24356F),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium,
                ),
                SizedBox(height: 4.h),
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

  /// دالة مساعدة لرسم صف يعرض إحصائية معينة.
  Widget _statRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 15.spMin),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: const Color(0xFFF5A623),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// ترجمة قيمة الجنس بناءً على اللغة
  String _translatedGender(String g, String lang) {
    final data = {
      'Male': {'en': 'Male', 'ar': 'ذكر'},
      'Female': {'en': 'Female', 'ar': 'أنثى'},
      'Other': {'en': 'Other', 'ar': 'آخر'},
      'Prefer not to say': {'en': 'Prefer not to say', 'ar': 'أفضل عدم القول'},
      '--': {'en': '--', 'ar': '--'},
    };
    return data[g]?[lang] ?? data[g]?['en'] ?? g;
  }
}