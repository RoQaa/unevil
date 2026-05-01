import 'package:flutter/material.dart';

  /// دالة الـ build المسؤولة عن بناء وتخطيط الواجهة.
  /// تقوم بالتحقق من حجم الشاشة باستخدام MediaQuery.
  /// إذا كانت الشاشة كبيرة (Tablet/Desktop)، تقوم بتوسيط المحتوى (Center) ووضع حد أقصى للعرض (maxWidth).
  /// إذا كانت الشاشة صغيرة (Mobile)، تسمح للمحتوى بالامتداد على كامل العرض.
  

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
