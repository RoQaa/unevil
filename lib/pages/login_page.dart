import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'app_translations.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      body: SafeArea(
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: const Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _LoginCard(),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please enter email and password");
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong";

      if (e.code == 'invalid-email') {
        message = "Invalid email address";
      } else if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = "Incorrect email or password";
      } else if (e.code == 'too-many-requests') {
        message = "Too many attempts, try again later";
      }

      _showMessage(message);
    } catch (e) {
      _showMessage("Unexpected error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF24356F),
        borderRadius: BorderRadius.circular(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                icon: const Icon(
                  Icons.language,
                  color: Colors.white,
                ),
                onSelected: (value) {
                  UnveilApp.of(context).changeLanguage(value);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'en',
                    child: Text(
                      'English',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ar',
                    child: Text(
                      'العربية',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'es',
                    child: Text(
                      'Español',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'fr',
                    child: Text(
                      'Français',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'zh',
                    child: Text(
                      '中文',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hi',
                    child: Text(
                      'हिन्दी',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          Center(
            child: Image.asset(
              'assets/logo.png',
              height: 95,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            AppTranslations.text('welcomeBack', lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            AppTranslations.text('loginSubtitle', lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 28),

          _buildInputField(
            controller: emailController,
            hint: AppTranslations.text('emailAddress', lang),
            icon: Icons.email_outlined,
          ),

          const SizedBox(height: 16),

          _buildInputField(
            controller: passwordController,
            hint: AppTranslations.text('password', lang),
            icon: Icons.lock_outline_rounded,
            isPassword: true,
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: resetPassword,
              child: Text(
                AppTranslations.text('forgotPassword', lang),
                style: const TextStyle(
                  color: Color(0xFFB8A7FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isLoading ? null : login,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      AppTranslations.text('login', lang),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 22),

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
              style: const TextStyle(
                color: Color(0xFFB8A7FF),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        cursorColor: Colors.black,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          icon: Icon(
            icon,
            color: Colors.grey.shade700,
            size: 28,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}