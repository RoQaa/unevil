import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../main.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'app_translations.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';

/// صفحة تسجيل الدخول الرئيسية. هذه الصفحة تحتوي على تصميم الـ Scaffold الخارجي (الخلفية الزرقاء)
/// وتستدعي الكارد الداخلي الخاص باللوجين.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  /// دالة الـ build المسؤولة عن رسم وتصميم كارد تسجيل الدخول.
  /// تحتوي على الشعار، نصوص الترحيب، حقول الإدخال، وزر تسجيل الدخول.
  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      body: SafeArea(
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ResponsiveWrapper(
              child: const _LoginCard(),
            ),
          ),
        ),
      ),
    );
  }
}

/// واجهة الكارد الداخلي لتسجيل الدخول، تحتوي على حالة (State) لتتبع التحميل والمدخلات.
class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  /// دالة تسجيل الدخول (Login).
  /// تقوم بالتحقق من المدخلات (الإيميل وكلمة المرور) أولاً.
  /// ثم تتواصل مع Firebase للتحقق من صحة البيانات.
  /// إذا نجحت العملية، يتم نقل المستخدم لصفحة التطبيق الرئيسية (HomeScreen).
  Future<void> login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter email and password");
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showMessage("Please enter a valid email address");
      return;
    }

    if (password.length < 6) {
      debugPrint("Validation failed: Password too short");
      _showMessage("Password must be at least 6 characters");
      return;
    }

    debugPrint("Validation passed, attempting login for: $email");

    try {
      setState(() => isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      _showMessage("Login successful! Welcome back.");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') message = "No user found with this email";
      else if (e.code == 'wrong-password') message = "Incorrect password";
      else if (e.code == 'invalid-email') message = "Invalid email format";
      else if (e.code == 'user-disabled') message = "This account has been disabled";
      
      _showMessage(e.message ?? message);
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// دالة إعادة تعيين كلمة المرور.
  /// ترسل رابط على البريد الإلكتروني المدخل لتمكين المستخدم من تغيير كلمة المرور عبر Firebase.
  Future<void> resetPassword() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage("Enter your email first");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage("Password reset email sent");
    } on FirebaseAuthException catch (e) {
      String message = "Could not send reset email";

      if (e.code == 'invalid-email') {
        message = "Invalid email address";
      } else if (e.code == 'user-not-found') {
        message = "No user found with this email";
      }

      _showMessage(message);
    } catch (e) {
      _showMessage("Unexpected error: $e");
    }
  }

  /// دالة مساعدة (Helper function) لطباعة رسالة منبثقة (SnackBar) للمستخدم في أسفل الشاشة.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  /// دالة الـ build المسؤولة عن رسم وتصميم كارد تسجيل الدخول.
  /// تحتوي على الشعار، نصوص الترحيب، حقول الإدخال، وزر تسجيل الدخول.
  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF24356F),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/logo.png',
              height: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppTranslations.text('welcomeBack', lang),
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.text('loginSubtitle', lang),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 30),
          _buildInput(
            controller: emailController,
            hint: AppTranslations.text('emailAddress', lang),
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          _buildInput(
            controller: passwordController,
            hint: AppTranslations.text('password', lang),
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          Align(
            alignment: lang == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
            child: TextButton(
              onPressed: resetPassword,
              child: Text(
                AppTranslations.text('forgotPassword', lang),
                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      AppTranslations.text('login', lang),
                      style: AppTypography.button,
                    ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignUpPage(),
                ),
              );
            },
            child: Text(
              AppTranslations.text('createAccount', lang),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// دالة مساعدة لرسم حقول الإدخال (TextFields) بشكل موحد ومتناسق (لتقليل تكرار الكود).
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        cursorColor: Colors.black,
        style: AppTypography.input,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTypography.hint,
          prefixIcon: Icon(icon, color: Colors.grey.shade700, size: 22),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}