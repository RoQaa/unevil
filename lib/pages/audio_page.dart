import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'history_service.dart';

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

  String extraResult = "";
  String extraConfidence = "";
  String extraReason = "";

  bool isLoading = false;
  bool isExtraLoading = false;
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

        extraResult = "";
        extraConfidence = "";
        extraReason = "";

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

    setState(() {
      isLoading = true;
      result = "";
      confidence = "";
      reason = "";

      extraResult = "";
      extraConfidence = "";
      extraReason = "";

      isSaved = false;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/analyze-audio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio_base64': base64Encode(audioBytes!),
          'file_name': fileName,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        result = data['result'] ?? _text('analysisFailed', lang);
        confidence = data['confidence'] ?? "";
        reason = data['reason'] ?? "";
        isLoading = false;
      });

      if (result == _text('analysisFailed', lang) ||
          result == 'Analysis failed') {
        return;
      }

      await HistoryService.saveHistory(
        type: 'audio',
        title: _text('title', lang),
        result: result,
        confidence: confidence,
        note: reason,
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

  Future<void> analyzeAudioWithHive() async {
    final lang = Localizations.localeOf(context).languageCode;

    if (audioBytes == null || fileName.isEmpty) {
      setState(() {
        extraResult = _text('chooseFirst', lang);
        extraConfidence = "";
        extraReason = "";
      });
      return;
    }

    setState(() {
      isExtraLoading = true;
      extraResult = "";
      extraConfidence = "";
      extraReason = "";
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/analyze-audio-hive'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio_base64': base64Encode(audioBytes!),
          'file_name': fileName,
        }),
      );

      final data = jsonDecode(response.body);

      setState(() {
        extraResult = data['result'] ?? _text('analysisFailed', lang);
        extraConfidence = data['confidence'] ?? "";
        extraReason = data['reason'] ?? "";
        isExtraLoading = false;
      });
    } catch (e) {
      setState(() {
        extraResult = _text('connectionFailed', lang);
        extraConfidence = "";
        extraReason = _text('backendNote', lang);
        isExtraLoading = false;
      });
    }
  }

  void clearAudio() {
    final lang = Localizations.localeOf(context).languageCode;

    setState(() {
      fileName = "";
      audioBytes = null;

      result = "";
      confidence = "";
      reason = "";

      extraResult = "";
      extraConfidence = "";
      extraReason = "";

      isLoading = false;
      isExtraLoading = false;
      isSaved = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_text('cleared', lang)),
        backgroundColor: const Color(0xFF24356F),
      ),
    );
  }

  double _parsePercent(String value) {
    final cleaned = value.replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

final normalizedResult = result.toLowerCase();

final bool isAiResult =
    normalizedResult.contains('ai') &&
    !normalizedResult.contains('real') &&
    !normalizedResult.contains('mixed');

final bool isRealResult =
    normalizedResult.contains('real') ||
    normalizedResult.contains('human') ||
    normalizedResult.contains('authentic');

final bool isMixedResult =
    normalizedResult.contains('mixed') ||
    normalizedResult.contains('partially');

final bool isFailedResult =
    normalizedResult.contains('failed') ||
    normalizedResult.contains('error') ||
    result == _text('connectionFailed', lang);
    final double confidenceValue = _parsePercent(confidence);
    final double mixedAiPercent = confidenceValue.clamp(0, 100);
    final double mixedRealPercent = (100 - mixedAiPercent).clamp(0, 100);

    final Color resultColor = isFailedResult
        ? Colors.orangeAccent
        : isMixedResult
            ? Colors.yellowAccent
            : isAiResult
                ? Colors.redAccent
                : Colors.greenAccent;

    final IconData resultIcon = isFailedResult
        ? Icons.error_outline_rounded
        : isMixedResult
            ? Icons.help_outline_rounded
            : isAiResult
                ? Icons.warning_amber_rounded
                : Icons.verified_rounded;

    final bool isExtraAi = extraResult == _text('likelyAI', lang);
    final bool isExtraReal = extraResult == _text('likelyReal', lang);
    final bool isExtraFailed = extraResult == _text('analysisFailed', lang) ||
        extraResult == _text('connectionFailed', lang);

    final Color extraColor = isExtraFailed
        ? Colors.orangeAccent
        : isExtraAi
            ? Colors.redAccent
            : isExtraReal
                ? Colors.greenAccent
                : Colors.orangeAccent;

    final IconData extraIcon = isExtraFailed
        ? Icons.error_outline_rounded
        : isExtraAi
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
                  onPressed: chooseAudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.audio_file),
                  label: Text(_text('choose', lang)),
                ),
              ),
              const SizedBox(height: 20),
              if (fileName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24356F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    fileName,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : analyzeAudio,
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
                      onPressed: clearAudio,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_text('clear', lang)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isExtraLoading ? null : analyzeAudioWithHive,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    foregroundColor: Colors.white,
                  ),
                  icon: isExtraLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(_text('extraCheckHive', lang)),
                ),
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
                    border: Border.all(color: resultColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(resultIcon, color: resultColor, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              result,
                              style: TextStyle(
                                color: resultColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _resultLine(
                        label: _text('status', lang),
                        value: isMixedResult
                            ? _text('mixedStatus', lang)
                            : isFailedResult
                                ? _text('unableToJudge', lang)
                                : isAiResult
                                    ? _text('suspicious', lang)
                                    : isRealResult
                                        ? _text('authentic', lang)
                                        : _text('unableToJudge', lang),
                      ),
                      const SizedBox(height: 10),
                      _resultLine(
                        label: _text('confidence', lang),
                        value: confidence,
                      ),
                      if (isMixedResult) ...[
                        const SizedBox(height: 10),
                        _resultLine(
                          label: _text('aiPercent', lang),
                          value: "${mixedAiPercent.toStringAsFixed(2)}%",
                        ),
                        const SizedBox(height: 10),
                        _resultLine(
                          label: _text('realPercent', lang),
                          value: "${mixedRealPercent.toStringAsFixed(2)}%",
                        ),
                      ],
                      const SizedBox(height: 10),
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
              if (extraResult.isNotEmpty && !isExtraLoading) ...[
                const SizedBox(height: 18),
                Text(
                  _text('extraHiveResult', lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24356F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: extraColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(extraIcon, color: extraColor, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              extraResult,
                              style: TextStyle(
                                color: extraColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _resultLine(
                        label: _text('confidence', lang),
                        value: extraConfidence,
                      ),
                      const SizedBox(height: 10),
                      _resultLine(
                        label: _text('explanation', lang),
                        value: extraReason,
                        multiLine: true,
                      ),
                    ],
                  ),
                ),
              ],
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
