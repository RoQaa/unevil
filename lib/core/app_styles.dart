import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_text_styles.dart';

class AppStyles {
  // Common Dimensions
  static double buttonHeight = 52.h;
  static double inputHeight = 52.h;
  static double borderRadius = 12.r;
  static double cardRadius = 16.r;
  static double paddingGlobal = 20.r;

  // Common Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: const Color(0xFF24356F),
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10.r,
        offset: Offset(0, 4.h),
      ),
    ],
  );

  static InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    bool isArabic = false,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: AppTextStyles.hint,
      prefixIcon: Icon(
        icon,
        color: Colors.grey.shade700,
        size: 20.r,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    );
  }
}
