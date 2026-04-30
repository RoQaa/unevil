import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_text_styles.dart';

/// A reusable card used to display the results of an AI analysis.
/// 
/// Shows the classification (Real/AI), confidence level, and reasoning.
class AnalysisResultCard extends StatelessWidget {
  final String result;
  final String confidence;
  final String reason;
  final String lang;
  final bool isAiResult;

  const AnalysisResultCard({
    super.key,
    required this.result,
    required this.confidence,
    required this.reason,
    required this.lang,
    required this.isAiResult,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF24356F),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isAiResult ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result Status
          Row(
            children: [
              Icon(
                isAiResult ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isAiResult ? Colors.redAccent : Colors.greenAccent,
                size: 28.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  result,
                  style: AppTextStyles.h2.copyWith(
                    color: isAiResult ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Confidence Bar
          if (confidence.isNotEmpty) ...[
            Text(
              _text('confidence', lang),
              style: AppTextStyles.labelMedium,
            ),
            SizedBox(height: 8.h),
            _buildConfidenceBar(),
            SizedBox(height: 16.h),
          ],

          // Reason/Details
          if (reason.isNotEmpty) ...[
            Text(
              _text('reason', lang),
              style: AppTextStyles.labelMedium,
            ),
            SizedBox(height: 6.h),
            Text(
              reason,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBar() {
    double value = 0.0;
    try {
      value = double.parse(confidence.replaceAll('%', '')) / 100.0;
    } catch (_) {}

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10.h,
              backgroundColor: Colors.white10,
              color: isAiResult ? Colors.redAccent : Colors.greenAccent,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          confidence,
          style: AppTextStyles.h3.copyWith(
            color: isAiResult ? Colors.redAccent : Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  String _text(String key, String lang) {
    final data = {
      'confidence': {'en': 'Confidence Level', 'ar': 'مستوى الثقة'},
      'reason': {'en': 'Reasoning', 'ar': 'السبب'},
    };
    return data[key]?[lang] ?? data[key]?['en'] ?? key;
  }
}
