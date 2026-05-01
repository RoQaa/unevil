import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'history_service.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';
import 'app_translations.dart';
import 'package:image_picker/image_picker.dart';

/// صفحة تحليل الصور (Analysis Page).
/// تسمح للمستخدم برفع أو إدخال المحتوى للتحقق مما إذا كان حقيقياً أم مولداً بالذكاء الاصطناعي.
class ImageAnalysisPage extends StatefulWidget {
  const ImageAnalysisPage({super.key});

  @override
  State<ImageAnalysisPage> createState() => _ImageAnalysisPageState();
}

/// الحالة الخاصة بصفحة تحليل الصور.
/// تحتفظ بالبيانات الهامة، نتيجة التحليل، وحالة التحميل.
class _ImageAnalysisPageState extends State<ImageAnalysisPage> {
  XFile? selectedImage;
  Uint8List? imageBytes;

  String result = "";
  String confidence = "";
  String reason = "";
  bool isLoading = false;
  bool isSaved = false;
  bool hasValidAnalysis = false;

  final ImagePicker picker = ImagePicker();

  /// دالة لفتح معرض الصور أو مدير الملفات واختيار صورة للتحليل.
  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();

      setState(() {
        selectedImage = image;
        imageBytes = bytes;
        result = "";
        confidence = "";
        reason = "";
        isSaved = false;
        hasValidAnalysis = false;
      });
    }
  }

  /// الدالة الأساسية لتحليل المحتوى.
  /// 1. ترسل المحتوى إلى خادم الخلفية (Backend) عبر طلب HTTP POST.
  /// 2. تستقبل النتيجة وتترجمها.
  /// 3. تحفظ النتيجة في السجل (History) عبر Firebase للرجوع إليها لاحقاً.
  Future<void> analyzeImage() async {
    final lang = Localizations.localeOf(context).languageCode;

    if (selectedImage == null || imageBytes == null) {
      setState(() {
        result = AppTranslations.text('image_chooseFirst', lang);
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
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendBaseUrl/analyze-image'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes!,
          filename: selectedImage!.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
          hasValidAnalysis = apiResult != 'Analysis failed';
        });

        if (hasValidAnalysis) {
          await HistoryService.saveHistory(
            type: 'image',
            titleKey: AppTranslations.text('image_title', lang),
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
              content: Text(AppTranslations.text('image_savedToHistory', lang)),
              backgroundColor: const Color(0xFF24356F),
            ),
          );
        }
      } else {
        setState(() {
          result = AppTranslations.text('image_serverError', lang);
          confidence = "";
          reason = AppTranslations.text('image_tryAgain', lang);
          isLoading = false;
          isSaved = false;
          hasValidAnalysis = false;
        });
      }
    } catch (e) {
      setState(() {
        result = AppTranslations.text('image_connectionFailed', lang);
        confidence = "";
        reason = AppTranslations.text('image_backendNote', lang);
        isLoading = false;
        isSaved = false;
        hasValidAnalysis = false;
      });
    }
  }

  /// دالة لمسح المحتوى الحالي من الشاشة والذاكرة للبدء من جديد.
  void clearImage() {
    final lang = Localizations.localeOf(context).languageCode;

    setState(() {
      selectedImage = null;
      imageBytes = null;
      result = "";
      confidence = "";
      reason = "";
      isLoading = false;
      isSaved = false;
      hasValidAnalysis = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppTranslations.text('image_cleared', lang)),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    final bool isAiResult = result == 'Likely AI Generated';
    final bool isErrorResult =
        result == AppTranslations.text('image_connectionFailed', lang) ||
        result == AppTranslations.text('image_serverError', lang) ||
        result == AppTranslations.text('image_chooseFirst', lang) ||
        result == 'Analysis failed';

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18245C),
        foregroundColor: Colors.white,
        title: Text(AppTranslations.text('image_title', lang)),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ResponsiveWrapper(
            child: ListView(
              children: [
              Text(
                AppTranslations.text('image_upload', lang),
                style: AppTextStyles.h1.copyWith(fontSize: 16.sp),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.upload),
                  label: Text(AppTranslations.text('image_choose', lang)),
                ),
              ),
              SizedBox(height: 20.h),
              if (imageBytes != null)
                Container(
                  height: 220.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    child: Image.memory(
                      imageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: AppStyles.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : analyzeImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8A7FF),
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
                            : Text(AppTranslations.text('image_analyze', lang)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  SizedBox(
                    height: AppStyles.buttonHeight,
                    child: OutlinedButton(
                      onPressed: clearImage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                        ),
                      ),
                      child: Text(AppTranslations.text('image_clear', lang)),
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
                          AppTranslations.text('image_analyzingNow', lang),
                          style: AppTextStyles.button,
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
                              style: AppTextStyles.button,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      if (hasValidAnalysis) ...[
                        _resultLine(
                          label: AppTranslations.text('image_status', lang),
                          value: isAiResult
                              ? AppTranslations.text('image_suspicious', lang)
                              : AppTranslations.text('image_authentic', lang),
                        ),
                        SizedBox(height: 10.h),
                        _resultLine(
                          label: AppTranslations.text('image_confidence', lang),
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
                              AppTranslations.text('image_savedToHistory', lang),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.sp,
                              ),
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

  /// دالة مساعدة (Helper) لرسم أسطر النتيجة بشكل منسق (مثل الحالة: مشبوه).
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