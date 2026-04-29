import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'history_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';

class VideoAnalysisPage extends StatefulWidget {
  const VideoAnalysisPage({super.key});

  @override
  State<VideoAnalysisPage> createState() =>
      _VideoAnalysisPageState();
}

class _VideoAnalysisPageState
    extends State<VideoAnalysisPage> {
  String fileName = "";
  Uint8List? videoBytes;
  String result = "";
  String confidence = "";
  String reason = "";
  bool isLoading = false;
  bool isSaved = false;
  bool hasValidAnalysis = false;

  Future<void> chooseVideo() async {
    FilePickerResult? picked =
        await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi'],
      withData: true,
    );

    if (picked != null) {
      final file = picked.files.single;
      Uint8List? bytes = file.bytes;

      // On mobile/desktop, if bytes is null, read from path
      if (bytes == null && !kIsWeb && file.path != null) {
        final fileObj = File(file.path!);
        bytes = await fileObj.readAsBytes();
      }

      if (bytes != null) {
        setState(() {
          fileName = file.name;
          videoBytes = bytes;
          result = "";
          confidence = "";
          reason = "";
          isSaved = false;
          hasValidAnalysis = false;
        });
      }
    }
  }

  Future<void> analyzeVideo() async {
    final lang =
        Localizations.localeOf(context).languageCode;

    if (fileName.isEmpty) {
      setState(() {
        result = _text('chooseFirst', lang);
        confidence = "";
        reason = "";
        isSaved = false;
      });
      return;
    }

    final String extension = fileName.split('.').last.toLowerCase();
    if (!['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
      setState(() {
        result = lang == 'ar' ? 'ملف غير صالح' : 'Invalid file';
        confidence = "";
        reason = lang == 'ar' ? 'يرجى اختيار ملف فيديو فقط' : 'Please choose a video file only';
        isSaved = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = "";
      confidence = "";
      reason = "";
      isSaved = false;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/analyze-video'),
      );

      if (videoBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            videoBytes!,
            filename: fileName,
          ),
        );
      }

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
          hasValidAnalysis = true;
        });

        await HistoryService.saveHistory(
          type: 'video',
          titleKey: _text('title', lang),
          resultKey: apiResult,
          confidence: apiConfidence,
          noteKey: apiReason,
        );
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

  void clearVideo() {
    final lang =
        Localizations.localeOf(context).languageCode;

    setState(() {
      fileName = "";
      videoBytes = null;
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
    final lang =
        Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';
    final bool isAiResult = result == _text('likelyAI', lang);

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18245C),
        foregroundColor: Colors.white,
        title: Text(_text('title', lang)),
      ),
      body: Directionality(
        textDirection:
            isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ResponsiveWrapper(
            child: ListView(
              children: [
              Text(
                _text('upload', lang),
                style: AppTextStyles.h1.copyWith(fontSize: 24.sp),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                height: AppStyles.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: chooseVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    ),
                  ),
                  icon: const Icon(Icons.video_file),
                  label: Text(_text('choose', lang)),
                ),
              ),
              SizedBox(height: 20.h),
              if (fileName.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24356F),
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                  ),
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.white,
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
                        onPressed:
                            isLoading ? null : analyzeVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8A7FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                height: 24.h,
                                width: 24.w,
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5.w,
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
                      onPressed: clearVideo,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.white24, width: 1.w),
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
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24.h,
                        width: 24.w,
                        child: CircularProgressIndicator(
                          color: const Color(0xFFF5A623),
                          strokeWidth: 2.5.w,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          _text('analyzingNow', lang),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
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
                      color: isAiResult
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      width: 1.w,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAiResult
                                ? Icons.warning_amber_rounded
                                : Icons.verified_rounded,
                            color: isAiResult
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            size: 28.r,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              result,
                              style: TextStyle(
                                color: isAiResult
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
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
                      SizedBox(height: 10.h),
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
        'en': 'Video Analysis',
        'ar': 'تحليل الفيديو',
      },
      'upload': {
        'en': 'Upload video to analyze:',
        'ar': 'ارفع فيديو للتحليل:',
      },
      'choose': {
        'en': 'Choose Video',
        'ar': 'اختر فيديو',
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
        'en': 'Choose video first',
        'ar': 'اختر فيديو أولاً',
      },
      'analyzingNow': {
        'en': 'Analyzing video, please wait...',
        'ar': 'جاري تحليل الفيديو، انتظر قليلًا...',
      },
      'likelyAI': {
        'en': 'Likely AI Video',
        'ar': 'غالبًا فيديو مولد',
      },
      'likelyReal': {
        'en': 'Likely Real Video',
        'ar': 'غالبًا فيديو حقيقي',
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
      'aiReason': {
        'en':
            'Possible synthetic frames or unusual video patterns were detected.',
        'ar':
            'تم اكتشاف إطارات اصطناعية محتملة أو أنماط غير طبيعية في الفيديو.',
      },
      'realReason': {
        'en':
            'The video appears normal with no strong AI indicators.',
        'ar':
            'يبدو الفيديو طبيعيًا ولا توجد مؤشرات قوية على الذكاء الاصطناعي.',
      },
      'savedToHistory': {
        'en': 'Saved to history successfully',
        'ar': 'تم حفظ النتيجة في السجل',
      },
      'cleared': {
        'en': 'Video cleared',
        'ar': 'تم مسح الفيديو',
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