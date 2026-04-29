import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'history_service.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';

class ImageAnalysisPage extends StatefulWidget {
  const ImageAnalysisPage({super.key});

  @override
  State<ImageAnalysisPage> createState() => _ImageAnalysisPageState();
}

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

  Future<void> analyzeImage() async {
    final lang = Localizations.localeOf(context).languageCode;

    if (selectedImage == null || imageBytes == null) {
      setState(() {
        result = _text('chooseFirst', lang);
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
        Uri.parse('http://127.0.0.1:8000/analyze-image'),
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
            titleKey: _text('title', lang),
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
              content: Text(_text('savedToHistory', lang)),
              backgroundColor: const Color(0xFF24356F),
            ),
          );
        }
      } else {
        setState(() {
          result = _text('serverError', lang);
          confidence = "";
          reason = _text('tryAgain', lang);
          isLoading = false;
          isSaved = false;
          hasValidAnalysis = false;
        });
      }
    } catch (e) {
      setState(() {
        result = _text('connectionFailed', lang);
        confidence = "";
        reason = _text('backendNote', lang);
        isLoading = false;
        isSaved = false;
        hasValidAnalysis = false;
      });
    }
  }

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
        content: Text(_text('cleared', lang)),
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
        result == _text('connectionFailed', lang) ||
        result == _text('serverError', lang) ||
        result == _text('chooseFirst', lang) ||
        result == 'Analysis failed';

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18245C),
        foregroundColor: Colors.white,
        title: Text(_text('title', lang)),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ResponsiveWrapper(
            child: ListView(
              children: [
              Text(
                _text('upload', lang),
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
                  label: Text(_text('choose', lang)),
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
                            : Text(_text('analyze', lang)),
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
                      child: Text(_text('clear', lang)),
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
                          _text('analyzingNow', lang),
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
                          label: _text('status', lang),
                          value: isAiResult
                              ? _text('suspicious', lang)
                              : _text('authentic', lang),
                        ),
                        SizedBox(height: 10.h),
                        _resultLine(
                          label: _text('confidence', lang),
                          value: confidence,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (reason.isNotEmpty)
                        _resultLine(
                          label: _text('explanation', lang),
                          value: reason,
                          multiLine: true,
                        ),
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
                              _text('savedToHistory', lang),
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

  String _text(String key, String lang) {
    final data = {
      'title': {
        'en': 'Image Analysis',
        'ar': 'تحليل الصور',
      },
      'upload': {
        'en': 'Upload image to analyze:',
        'ar': 'ارفع صورة للتحليل:',
      },
      'choose': {
        'en': 'Choose Image',
        'ar': 'اختر صورة',
      },
      'analyze': {
        'en': 'Analyze',
        'ar': 'تحليل',
      },
      'clear': {
        'en': 'Clear',
        'ar': 'مسح',
      },
      'chooseFirst': {
        'en': 'Choose image first',
        'ar': 'اختر صورة أولاً',
      },
      'analyzingNow': {
        'en': 'Analyzing image, please wait...',
        'ar': 'جاري تحليل الصورة، انتظر قليلًا...',
      },
      'confidence': {
        'en': 'Confidence',
        'ar': 'الثقة',
      },
      'status': {
        'en': 'Status',
        'ar': 'الحالة',
      },
      'authentic': {
        'en': 'Authentic',
        'ar': 'أصيل',
      },
      'suspicious': {
        'en': 'Suspicious',
        'ar': 'مشبوه',
      },
      'explanation': {
        'en': 'Explanation',
        'ar': 'التفسير',
      },
      'savedToHistory': {
        'en': 'Saved to history successfully',
        'ar': 'تم حفظ النتيجة في السجل',
      },
      'cleared': {
        'en': 'Image cleared',
        'ar': 'تم مسح الصورة',
      },
      'connectionFailed': {
        'en': 'Connection failed',
        'ar': 'فشل الاتصال',
      },
      'backendNote': {
        'en': 'Make sure the backend server is running.',
        'ar': 'تأكدي أن سيرفر الخلفية شغال.',
      },
      'serverError': {
        'en': 'Server error',
        'ar': 'خطأ في السيرفر',
      },
      'tryAgain': {
        'en': 'Please try again.',
        'ar': 'حاولي مرة أخرى.',
      },
    };

    return data[key]?[lang] ?? data[key]?['en'] ?? key;
  }
}