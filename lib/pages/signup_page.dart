import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_translations.dart';
import 'home_page.dart';
import 'login_page.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';

/// صفحة إنشاء حساب جديد (Sign Up).
/// تحتوي على فورم لجمع بيانات المستخدم وإدخالها لقاعدة بيانات Firebase.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

/// حالة (State) صفحة إنشاء الحساب.
/// تحتوي على متحكمات (Controllers) لحقول الإدخال مثل الاسم، الإيميل، والعمر، بالإضافة لمتغيرات تتبع الجنس وحالة التحميل.
class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  final GlobalKey _genderKey = GlobalKey();

  String? gender;
  bool isChecked = false;
  bool isLoading = false;

  /// دالة معالجة عملية تسجيل حساب جديد.
  /// 1. تتحقق من أن جميع الحقول ممتلئة وصحيحة (Validation).
  /// 2. تنشئ مستخدم جديد في Firebase Authentication.
  /// 3. تحفظ بيانات المستخدم (الاسم، العمر، الجنس) في Firebase Firestore.
  /// 4. تسجل الخروج للرجوع لصفحة اللوجين لكي يسجل الدخول بنفسه.
  Future<void> handleSignUp() async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String ageStr = ageController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || ageStr.isEmpty || gender == null || !isChecked) {
      showMessage("Please complete all fields");
      return;
    }

    if (name.length < 3) {
      showMessage("Name is too short");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      showMessage("Please enter a valid email address");
      return;
    }

    if (password.length < 6) {
      showMessage("Password must be at least 6 characters");
      return;
    }

    final int? ageVal = int.tryParse(ageStr);
    if (ageVal == null || ageVal < 5 || ageVal > 100) {
      debugPrint("Validation failed: Invalid age");
      showMessage("Please enter a valid age");
      return;
    }

    debugPrint("Validation passed, attempting signup for: $email");

    try {
      setState(() => isLoading = true);

      // 1. Create User
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        // 2. Save Profile Data (Minimal wait)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'fullName': name,
          'email': email,
          'gender': gender,
          'age': ageStr,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3. Sign out to force login
        await FirebaseAuth.instance.signOut();
      }

      if (mounted) {
        setState(() => isLoading = false);
        showMessage("Account created! Please login.");
        
        // Use PushAndRemoveUntil to ensure we go back to a clean Login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showMessage(e.message ?? "Signup failed");
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showMessage("Error: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// دالة مساعدة لطباعة رسالة تنبيه سفلية (SnackBar) للمستخدم في حال وجود خطأ أو نجاح العملية.
  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  /// دالة لترجمة نوع الجنس المختار وعرضه باللغة الصحيحة للمستخدم.
  String translatedGenderValue(String value, String lang) {
    switch (value) {
      case "Male": return AppTranslations.text('male', lang);
      case "Female": return AppTranslations.text('female', lang);
      case "Other": return AppTranslations.text('other', lang);
      case "Prefer not to say": return AppTranslations.text('preferNot', lang);
      default: return value;
    }
  }

  /// دالة مساعدة لبناء حقول الإدخال (TextFields) لتقليل التكرار وتوحيد الشكل.
  Widget buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isArabic,
    bool isPassword = false,
  }) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          cursorColor: Colors.black,
          style: AppTypography.input,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintTextDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            hintStyle: AppTypography.hint,
            prefixIcon: Icon(icon, color: Colors.grey.shade700, size: 24),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  /// دالة لفتح قائمة منسدلة (PopupMenu) لاختيار الجنس (ذكر، أنثى، وغيرها).
  Future<void> openGenderMenu() async {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';
    final RenderBox box = _genderKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    final double screenWidth = MediaQuery.of(context).size.width;

    final selected = await showMenu<String>(
      context: context,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: RelativeRect.fromLTRB(position.dx, position.dy + size.height + 4, screenWidth - position.dx - size.width, 0),
      items: [
        _genderMenuItem("Male", lang, isArabic),
        _genderMenuItem("Female", lang, isArabic),
        _genderMenuItem("Other", lang, isArabic),
        _genderMenuItem("Prefer not to say", lang, isArabic),
      ],
    );

    if (selected != null) { setState(() { gender = selected; }); }
  }

  PopupMenuItem<String> _genderMenuItem(String value, String lang, bool isArabic) {
    final Map<String, String> keyMap = {"Male": "male", "Female": "female", "Other": "other", "Prefer not to say": "preferNot"};
    return PopupMenuItem(
      value: value,
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SizedBox(
          width: 180,
          child: Text(AppTranslations.text(keyMap[value]!, lang), textAlign: isArabic ? TextAlign.right : TextAlign.left, style: AppTypography.bodySmall.copyWith(color: Colors.black)),
        ),
      ),
    );
  }

  /// دالة مساعدة لرسم حقل اختيار الجنس، بحيث يفتح القائمة المنسدلة عند الضغط عليه.
  Widget genderField(String lang, bool isArabic) {
    final String displayText = gender == null ? AppTranslations.text('selectGender', lang) : translatedGenderValue(gender!, lang);
    return GestureDetector(
      onTap: openGenderMenu,
      child: Container(
        key: _genderKey,
        height: 48,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(displayText, textAlign: isArabic ? TextAlign.right : TextAlign.left, style: AppTypography.input.copyWith(color: gender == null ? Colors.grey.shade600 : Colors.black))),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade700, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// دالة الـ build لرسم وتصميم واجهة صفحة التسجيل، تحتوي على حقول الإدخال، مربع الموافقة على الشروط، وزر إنشاء الحساب.
  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFF1E2E74),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ResponsiveWrapper(
            child: Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(child: Image.asset('assets/logo.png', height: 60)),
                  const SizedBox(height: 12),
                  Text(AppTranslations.text('createAccountTitle', lang), style: AppTypography.titleSmall),
                  const SizedBox(height: 10),
                  Text(AppTranslations.text('signupSubtitle', lang), textAlign: TextAlign.center, style: AppTypography.bodySmall),
                  const SizedBox(height: 20),
                  buildField(controller: nameController, icon: Icons.person_outline, hint: AppTranslations.text('fullName', lang), isArabic: isArabic),
                  const SizedBox(height: 14),
                  buildField(controller: emailController, icon: Icons.email_outlined, hint: AppTranslations.text('emailAddress', lang), isArabic: isArabic),
                  const SizedBox(height: 14),
                  buildField(controller: passwordController, icon: Icons.lock_outline, hint: AppTranslations.text('password', lang), isArabic: isArabic, isPassword: true),
                  const SizedBox(height: 14),
                  genderField(lang, isArabic),
                  const SizedBox(height: 14),
                  buildField(controller: ageController, icon: Icons.calendar_today_outlined, hint: AppTranslations.text('age', lang), isArabic: isArabic),
                  const SizedBox(height: 10),
                  Row(
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Checkbox(value: isChecked, activeColor: const Color(0xFFF5A623), onChanged: (value) { setState(() { isChecked = value!; }); }),
                      Expanded(child: Text(AppTranslations.text('terms', lang), textAlign: isArabic ? TextAlign.right : TextAlign.left, style: AppTypography.caption)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleSignUp,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A623), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(AppTranslations.text('createAccountTitle', lang), style: AppTypography.button),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(onTap: () { Navigator.pop(context); }, child: Text(AppTranslations.text('alreadyHave', lang), textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(color: const Color(0xFFB8A7FF)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}