import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 🎯 Semantic Typography System
/// Naming based on UI meaning (Title / Body / Label)
class AppTypography {
  AppTypography._();

  // ========================
  // 🏷️ Titles (Headings)
  // ========================

  static TextStyle get titleLarge => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle get titleMedium => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle get titleSmall => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ========================
  // 📄 Body Text (Main content)
  // ========================

  static TextStyle get bodyLarge => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  // ========================
  // 🏷️ Labels (Buttons, forms, tags)
  // ========================

  static TextStyle get labelLarge => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get labelMedium => TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ========================
  // 🧷 Captions (Hints, metadata)
  // ========================

  static TextStyle get caption => TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: Colors.grey.shade400,
  );

  static TextStyle get overline => TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.2,
    color: Colors.white70,
  );

  // ========================
  // 🛠️ Specialized (For current app usage)
  // ========================
  static TextStyle get button => labelLarge;
  static TextStyle get input => bodySmall.copyWith(color: Colors.black, fontWeight: FontWeight.w500);
  static TextStyle get hint => caption.copyWith(color: Colors.grey.shade600);
}

// For backward compatibility during transition
class AppTextStyles {
  static TextStyle get h1 => AppTypography.titleMedium;
  static TextStyle get h2 => AppTypography.titleSmall;
  static TextStyle get h3 => AppTypography.titleSmall;
  static TextStyle get bodyLarge => AppTypography.bodySmall;
  static TextStyle get bodyMedium => AppTypography.bodySmall;
  static TextStyle get button => AppTypography.button;
  static TextStyle get input => AppTypography.input;
  static TextStyle get hint => AppTypography.hint;
  static TextStyle get label => AppTypography.labelMedium.copyWith(color: const Color(0xFFB8A7FF));
  static TextStyle get labelMedium => AppTypography.labelMedium;
  static TextStyle get bodySmall => AppTypography.bodySmall;
  static TextStyle get labelSmall => AppTypography.labelSmall;
}
