import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'history_service.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';
import 'app_translations.dart';

/// صفحة تحليل النصوص (Analysis Page).
/// تسمح للمستخدم برفع أو إدخال المحتوى للتحقق مما إذا كان حقيقياً أم مولداً بالذكاء الاصطناعي.
class TextAnalysisPage extends StatefulWidget {
  const TextAnalysisPage({super.key});

  @override
  State<TextAnalysisPage> createState() => _TextAnalysisPageState();
}

/// الحالة الخاصة بصفحة تحليل النصوص.
/// تحتفظ بالبيانات الهامة، نتيجة التحليل، وحالة التحميل.
class _TextAnalysisPageState extends State<TextAnalysisPage> {
  final TextEditingController controller = TextEditingController();

  String result = "";
  String confidence = "";
  String reason = "";
  bool isLoading = false;
  bool isSaved = false;
  bool hasValidAnalysis = false;

  /// الدالة الأساسية لتحليل المحتوى.
  /// 1. ترسل المحتوى إلى خادم الخلفية (Backend) عبر طلب HTTP POST.
  /// 2. تستقبل النتيجة وتترجمها.
  /// 3. تحفظ النتيجة في السجل (History) عبر Firebase للرجوع إليها لاحقاً.
  Future<void> analyzeText() async {
    final lang = Localizations.localeOf(context).languageCode;
    final text = controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        result = AppTranslations.text('text_pleaseEnterText', lang);
        confidence = "";
        reason = "";
        isSaved = false;
        hasValidAnalysis = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
      confidence = "";
      reason = "";
      isSaved = false;
      hasValidAnalysis = false;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/analyze-text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String apiResult = data['result'] ?? '';
        final String apiConfidence = data['confidence'] ?? '';
        final String apiReason = data['reason'] ?? '';

        setState(() {
          result = apiResult;
          confidence = apiConfidence;
          reason = apiReason;
          isLoading = false;
          hasValidAnalysis = true;
        });

        await HistoryService.saveHistory(
          type: 'text',
          titleKey: AppTranslations.text('text_textAnalysis', lang),
          resultKey: apiResult,
          confidence: apiConfidence,
          noteKey: apiReason,
        );

        if (!mounted) return;

        setState(() {
          isSaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.text('text_savedToHistory', lang)),
            backgroundColor: const Color(0xFF24356F),
          ),
        );
      } else {
        setState(() {
          result = AppTranslations.text('text_serverError', lang);
          confidence = "";
          reason = AppTranslations.text('text_tryAgain', lang);
          isLoading = false;
          isSaved = false;
          hasValidAnalysis = false;
        });
      }
    } catch (e) {
      setState(() {
        result = AppTranslations.text('text_connectionFailed', lang);
        confidence = "";
        reason = AppTranslations.text('text_backendNote', lang);
        isLoading = false;
        isSaved = false;
        hasValidAnalysis = false;
      });
    }
  }

  /// دالة لمسح المحتوى الحالي من الشاشة والذاكرة للبدء من جديد.
  void clearText() {
    final lang = Localizations.localeOf(context).languageCode;

    setState(() {
      controller.clear();
      result = "";
      confidence = "";
      reason = "";
      isLoading = false;
      isSaved = false;
      hasValidAnalysis = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.text('text_cleared', lang)),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    final bool isAiResult = result == 'Likely AI Generated' ||
        result == 'غالبًا مولد بالذكاء الاصطناعي';

    final bool isErrorResult =
        result == AppTranslations.text('text_connectionFailed', lang) ||
        result == AppTranslations.text('text_serverError', lang) ||
        result == AppTranslations.text('text_pleaseEnterText', lang);

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18245C),
        foregroundColor: Colors.white,
        title: Text(AppTranslations.text('text_textAnalysis', lang)),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ResponsiveWrapper(
            child: ListView(
              children: [
              Text(
                AppTranslations.text('text_pasteText', lang),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 15.h),
              Container(
                padding: EdgeInsets.all(15.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 8,
                  cursorColor: Colors.black,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: AppTranslations.text('text_enterText', lang),
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: AppStyles.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : analyzeText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A623),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 24.r,
                                width: 24.r,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                AppTranslations.text('text_analyze', lang),
                                style: AppTextStyles.button,
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  SizedBox(
                    height: AppStyles.buttonHeight,
                    child: OutlinedButton(
                      onPressed: clearText,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                        ),
                      ),
                      child: Text(AppTranslations.text('text_clear', lang), style: AppTextStyles.button),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              if (isLoading)
                Container(
                  padding: EdgeInsets.all(18.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24356F),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24.r,
                        width: 24.r,
                        child: const CircularProgressIndicator(
                          color: Color(0xFFF5A623),
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          AppTranslations.text('text_analyzingNow', lang),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              if (result.isNotEmpty && !isLoading)
                Container(
                  padding: EdgeInsets.all(18.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24356F),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isErrorResult
                          ? Colors.orangeAccent
                          : isAiResult
                              ? Colors.redAccent
                              : Colors.greenAccent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isErrorResult
                                ? Icons.error_outline
                                : isAiResult
                                    ? Icons.warning_amber_rounded
                                    : Icons.verified_rounded,
                            color: isErrorResult
                                ? Colors.orangeAccent
                                : isAiResult
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                            size: 28.r,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              result,
                              style: AppTextStyles.h2.copyWith(
                                color: isErrorResult
                                    ? Colors.orangeAccent
                                    : isAiResult
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      if (hasValidAnalysis) ...[
                        _resultLine(
                          label: AppTranslations.text('text_status', lang),
                          value: isAiResult
                              ? AppTranslations.text('text_suspicious', lang)
                              : AppTranslations.text('text_authentic', lang),
                        ),
                        SizedBox(height: 10.h),
                        _resultLine(
                          label: AppTranslations.text('text_confidence', lang),
                          value: confidence,
                        ),
                        SizedBox(height: 10.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: LinearProgressIndicator(
                            value: (double.tryParse(confidence.replaceAll('%', '')) ?? 0) / 100,
                            minHeight: 10.h,
                            backgroundColor: Colors.white10,
                            color: isAiResult ? Colors.redAccent : Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (isSaved) ...[
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 18.r,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              AppTranslations.text('text_savedToHistory', lang),
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _resultLine({
    required String label,
    required String value,
    bool multiLine = false,
  }) {
    return Row(
      crossAxisAlignment:
          multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15.sp,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

}