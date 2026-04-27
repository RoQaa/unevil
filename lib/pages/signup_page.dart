import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_translations.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  final GlobalKey _genderKey = GlobalKey();

  String? gender;
  bool isChecked = false;
  bool isLoading = false;

  Future<void> signUp() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        ageController.text.trim().isEmpty ||
        gender == null ||
        !isChecked) {
      showMessage("Please complete all fields");
      return;
    }

    try {
      setState(() => isLoading = true);

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('info')
            .set({
          'fullName': nameController.text.trim(),
          'email': emailController.text.trim(),
          'gender': gender,
          'age': ageController.text.trim(),
          'createdAt': DateTime.now(),
        });
      }

      showMessage("Account created successfully");

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Signup failed");
    } catch (_) {
      showMessage("Unexpected error");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  String translatedGenderValue(String value, String lang) {
    switch (value) {
      case "Male":
        return AppTranslations.text('male', lang);
      case "Female":
        return AppTranslations.text('female', lang);
      case "Other":
        return AppTranslations.text('other', lang);
      case "Prefer not to say":
        return AppTranslations.text('preferNot', lang);
      default:
        return value;
    }
  }

  Widget buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isArabic,
    bool isPassword = false,
  }) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
          cursorColor: Colors.black,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintTextDirection:
                isArabic ? TextDirection.rtl : TextDirection.ltr,
            hintStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.grey.shade700,
              size: 28,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Future<void> openGenderMenu() async {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    final RenderBox box =
        _genderKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;
    final double screenWidth = MediaQuery.of(context).size.width;

    final selected = await showMenu<String>(
      context: context,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height + 4,
        screenWidth - position.dx - size.width,
        0,
      ),
      items: [
        PopupMenuItem(
          value: "Male",
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SizedBox(
              width: 180,
              child: Text(
                AppTranslations.text('male', lang),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: "Female",
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SizedBox(
              width: 180,
              child: Text(
                AppTranslations.text('female', lang),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: "Other",
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SizedBox(
              width: 180,
              child: Text(
                AppTranslations.text('other', lang),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        PopupMenuItem(
          value: "Prefer not to say",
          child: Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SizedBox(
              width: 180,
              child: Text(
                AppTranslations.text('preferNot', lang),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (selected != null) {
      setState(() {
        gender = selected;
      });
    }
  }

  Widget genderField(String lang, bool isArabic) {
    final String displayText = gender == null
        ? AppTranslations.text('selectGender', lang)
        : translatedGenderValue(gender!, lang);

    return GestureDetector(
      onTap: openGenderMenu,
      child: Container(
        key: _genderKey,
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Colors.grey.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayText,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: gender == null ? Colors.grey.shade600 : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade700,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF1E2E74),
      body: SafeArea(
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 90,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  AppTranslations.text('createAccountTitle', lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppTranslations.text('signupSubtitle', lang),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 30),
                buildField(
                  controller: nameController,
                  icon: Icons.person_outline,
                  hint: AppTranslations.text('fullName', lang),
                  isArabic: isArabic,
                ),
                const SizedBox(height: 14),
                buildField(
                  controller: emailController,
                  icon: Icons.email_outlined,
                  hint: AppTranslations.text('emailAddress', lang),
                  isArabic: isArabic,
                ),
                const SizedBox(height: 14),
                buildField(
                  controller: passwordController,
                  icon: Icons.lock_outline,
                  hint: AppTranslations.text('password', lang),
                  isArabic: isArabic,
                  isPassword: true,
                ),
                const SizedBox(height: 14),
                genderField(lang, isArabic),
                const SizedBox(height: 14),
                buildField(
                  controller: ageController,
                  icon: Icons.calendar_today_outlined,
                  hint: AppTranslations.text('age', lang),
                  isArabic: isArabic,
                ),
                const SizedBox(height: 10),
                Row(
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Checkbox(
                      value: isChecked,
                      activeColor: const Color(0xFFF5A623),
                      onChanged: (value) {
                        setState(() {
                          isChecked = value!;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        AppTranslations.text('terms', lang),
                        textAlign:
                            isArabic ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            AppTranslations.text('createAccountTitle', lang),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    AppTranslations.text('alreadyHave', lang),
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
          ),
        ),
      ),
    );
  }
}