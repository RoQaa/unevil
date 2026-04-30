import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../config.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'history_service.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';

class AudioAnalysisPage extends StatefulWidget {
  const AudioAnalysisPage({super.key});

  @override
  State<AudioAnalysisPage> createState() => _AudioAnalysisPageState();
}

class _AudioAnalysisPageState extends State<AudioAnalysisPage> {
  String fileName = "";
  Uint8List? audioBytes;

  String result = "";
  String confidence = "";
  String reason = "";
  bool isAiAnalyzed = false;

  bool isLoading = false;
  bool isSaved = false;

  Future<void> chooseAudio() async {
    FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
      withData: true,
    );

    if (picked != null && picked.files.single.bytes != null) {
      setState(() {
        fileName = picked.files.single.name;
        audioBytes = picked.files.single.bytes;

        result = "";
        confidence = "";
        reason = "";
        isAiAnalyzed = false;

        isSaved = false;
      });
    }
  }

  Future<void> analyzeAudio() async {
    final lang = Localizations.localeOf(context).languageCode;

    if (audioBytes == null || fileName.isEmpty) {
      setState(() {
        result = _text('chooseFirst', lang);
        confidence = "";
        reason = "";
        isSaved = false;
      });
      return;
    }

    final String extension = fileName.split('.').last.toLowerCase();
    if (!['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(extension)) {
      setState(() {
        result = lang == 'ar' ? 'ملف غير صالح' : 'Invalid file';
        confidence = "";
        reason = lang == 'ar' ? 'يرجى اختيار ملف صوتب فقط' : 'Please choose an audio file only';
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
        Uri.parse('$backendBaseUrl/analyze-audio'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioBytes!,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      final analysis = data['audio_analysis'];

      setState(() {
        if (analysis != null) {
          isAiAnalyzed = analysis['is_ai'] ?? false;
          result = isAiAnalyzed ? _text('likelyAI', lang) : _text('likelyReal', lang);
          confidence = analysis['confidence'] ?? "";
          reason = analysis['note'] ?? "";
        } else {
          result = _text('analysisFailed', lang);
          isAiAnalyzed = false;
        }
        isLoading = false;
      });

      if (result == _text('analysisFailed', lang) ||
          result == 'Analysis failed') {
        return;
      }

      await HistoryService.saveHistory(
        type: 'audio',
        titleKey: _text('title', lang),
        resultKey: result,
        confidence: confidence,
        noteKey: reason,
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
    } catch (e) {
      setState(() {
        result = _text('connectionFailed', lang);
        confidence = "";
        reason = _text('backendNote', lang);
        isLoading = false;
        isSaved = false;
      });
    }
  }

  void clearAudio() {
    final lang = Localizations.localeOf(context).languageCode;

    setState(() {
      result = "";
      confidence = "";
      reason = "";
      isAiAnalyzed = false;

      isLoading = false;
      isSaved = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_text('cleared', lang)),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  // Remove the explanation line from the UI in build method
  // I will target the lines 379-384 in audio_page.dart


  double _parsePercent(String value) {
    final cleaned = value.replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    final bool isAiResult = isAiAnalyzed;

    final bool isRealResult = result.isNotEmpty && !isAiAnalyzed && !result.contains('failed');
    
    // Check if result string itself indicates failure
    final bool isFailedResult =
        result == _text('analysisFailed', lang) ||
        result == _text('connectionFailed', lang);
    final double confidenceValue = _parsePercent(confidence);
    final double mixedAiPercent = confidenceValue.clamp(0, 100);
    final double mixedRealPercent = (100 - mixedAiPercent).clamp(0, 100);

    final Color resultColor = isFailedResult
        ? Colors.orangeAccent
        : isAiResult
            ? Colors.redAccent
            : Colors.greenAccent;

    final IconData resultIcon = isFailedResult
        ? Icons.error_outline_rounded
        : isAiResult
            ? Icons.warning_amber_rounded
            : Icons.verified_rounded;

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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                height: AppStyles.buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: chooseAudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    ),
                  ),
                  icon: const Icon(Icons.audio_file),
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
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: AppStyles.buttonHeight,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : analyzeAudio,
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
                      onPressed: clearAudio,
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
                    border: Border.all(color: resultColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(resultIcon, color: resultColor, size: 28.r),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              result,
                              style: TextStyle(
                                color: resultColor,
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
                        value: isFailedResult
                            ? _text('unableToJudge', lang)
                            : isAiResult
                                ? _text('suspicious', lang)
                                : _text('authentic', lang),
                      ),
                      SizedBox(height: 10.h),
                      _resultLine(
                        label: _text('confidence', lang),
                        value: confidence,
                      ),
                      SizedBox(height: 10.h),
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
        'en': 'Audio Analysis',
        'ar': 'تحليل الصوت',
      },
      'upload': {
        'en': 'Upload audio to analyze:',
        'ar': 'ارفع ملف صوتي:',
      },
      'choose': {
        'en': 'Choose Audio',
        'ar': 'اختر صوت',
      },
      'analyze': {
        'en': 'Analyze',
        'ar': 'تحليل',
      },
      'clear': {
        'en': 'Clear',
        'ar': 'مسح',
      },
      'extraCheckHive': {
        'en': 'Extra check with Hive',
        'ar': 'تحقق إضافي بـ Hive',
      },
      'extraHiveResult': {
        'en': 'Extra Hive result',
        'ar': 'نتيجة Hive الإضافية',
      },
      'chooseFirst': {
        'en': 'Choose audio first',
        'ar': 'اختر صوت أولاً',
      },
      'analyzingNow': {
        'en': 'Analyzing audio, please wait...',
        'ar': 'جاري تحليل الصوت، انتظر قليلًا...',
      },
      'likelyAI': {
        'en': 'Likely AI Audio',
        'ar': 'غالبًا صوت مولد',
      },
      'likelyReal': {
        'en': 'Likely Real Audio',
        'ar': 'غالبًا صوت حقيقي',
      },
      'mixedDetection': {
        'en': 'Mixed Detection',
        'ar': 'نتيجة مختلطة',
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
      'mixedStatus': {
        'en': 'Mixed signals',
        'ar': 'إشارات مختلطة',
      },
      'unableToJudge': {
        'en': 'Unable to judge',
        'ar': 'تعذر التحديد',
      },
      'aiPercent': {
        'en': 'AI',
        'ar': 'ذكاء',
      },
      'realPercent': {
        'en': 'Real',
        'ar': 'حقيقي',
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
        'en': 'Audio cleared',
        'ar': 'تم مسح الملف الصوتي',
      },
      'connectionFailed': {
        'en': 'Connection failed',
        'ar': 'فشل الاتصال',
      },
      'backendNote': {
        'en': 'Make sure the backend server is running.',
        'ar': 'تأكدي أن سيرفر الخلفية شغال.',
      },
      'analysisFailed': {
        'en': 'Analysis failed',
        'ar': 'فشل التحليل',
      },
    };

    return data[key]?[lang] ?? data[key]?['en'] ?? key;
  }
}
