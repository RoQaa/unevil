import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'history_service.dart';

class TextAnalysisPage extends StatefulWidget {
  const TextAnalysisPage({super.key});

  @override
  State<TextAnalysisPage> createState() => _TextAnalysisPageState();
}

class _TextAnalysisPageState extends State<TextAnalysisPage> {
  final TextEditingController controller = TextEditingController();

  String result = "";
  String confidence = "";
  String reason = "";
  bool isLoading = false;
  bool isSaved = false;
  bool hasValidAnalysis = false;

  Future<void> analyzeText() async {
    final lang = Localizations.localeOf(context).languageCode;
    final text = controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        result = _text('pleaseEnterText', lang);
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
        Uri.parse('http://127.0.0.1:8000/analyze-text'),
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
          title: _text('textAnalysis', lang),
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
        content: Text(_text('cleared', lang)),
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
        result == _text('connectionFailed', lang) ||
        result == _text('serverError', lang) ||
        result == _text('pleaseEnterText', lang);

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18245C),
        foregroundColor: Colors.white,
        title: Text(_text('textAnalysis', lang)),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                _text('pasteText', lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 8,
                  cursorColor: Colors.black,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _text('enterText', lang),
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                    ),
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
                        onPressed: isLoading ? null : analyzeText,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A623),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                            : Text(
                                _text('analyze', lang),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: clearText,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
      'textAnalysis': {
        'en': 'Text Analysis',
        'ar': 'تحليل النص',
      },
      'pasteText': {
        'en': 'Paste or write text below:',
        'ar': 'ألصق أو اكتب النص:',
      },
      'enterText': {
        'en': 'Enter text here...',
        'ar': 'اكتب النص هنا...',
      },
      'analyze': {
        'en': 'Analyze',
        'ar': 'تحليل',
      },
      'clear': {
        'en': 'Clear',
        'ar': 'مسح',
      },
      'pleaseEnterText': {
        'en': 'Please enter text first',
        'ar': 'أدخل نص أولاً',
      },
      'analyzingNow': {
        'en': 'Analyzing text, please wait...',
        'ar': 'جاري تحليل النص، انتظر قليلًا...',
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
        'en': 'Text cleared',
        'ar': 'تم مسح النص',
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