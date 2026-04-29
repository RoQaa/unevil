import 'package:flutter/material.dart';

/// Constrains content to a mobile-friendly max width on large screens.
/// On mobile, it fills the full width. On tablet/desktop, it centers
/// the content with a maximum width to maintain visual proportion.
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
