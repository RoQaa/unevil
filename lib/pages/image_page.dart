import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'history_service.dart';

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
      final imageBase64 = base64Encode(imageBytes!);

      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/analyze-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': imageBase64,
        }),
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
          hasValidAnalysis = apiResult != 'Analysis failed';
        });

        if (hasValidAnalysis) {
          await HistoryService.saveHistory(
            type: 'image',
            title: _text('title', lang),
            result: apiResult,
            confidence: apiConfidence,
            note: apiReason,
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
          child: ListView(
            children: [
              Text(
                _text('upload', lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
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
              const SizedBox(height: 20),
              if (imageBytes != null)
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : analyzeImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8A7FF),
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(_text('analyze', lang)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: clearImage,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_text('clear', lang)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24356F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFFF5A623),
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _text('analyzingNow', lang),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (result.isNotEmpty && !isLoading)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24356F),
                    borderRadius: BorderRadius.circular(16),
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
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              result,
                              style: TextStyle(
                                color: isErrorResult
                                    ? Colors.orangeAccent
                                    : isAiResult
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (hasValidAnalysis) ...[
                        _resultLine(
                          label: _text('status', lang),
                          value: isAiResult
                              ? _text('suspicious', lang)
                              : _text('authentic', lang),
                        ),
                        const SizedBox(height: 10),
                        _resultLine(
                          label: _text('confidence', lang),
                          value: confidence,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _resultLine(
                        label: _text('explanation', lang),
                        value: reason,
                        multiLine: true,
                      ),
                      if (isSaved) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.history,
                              size: 18,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _text('savedToHistory', lang),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
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