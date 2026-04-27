import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'history_service.dart';

class VideoAnalysisPage extends StatefulWidget {
  const VideoAnalysisPage({super.key});

  @override
  State<VideoAnalysisPage> createState() =>
      _VideoAnalysisPageState();
}

class _VideoAnalysisPageState
    extends State<VideoAnalysisPage> {
  String fileName = "";
  String result = "";
  String confidence = "";
  String reason = "";
  bool isLoading = false;
  bool isSaved = false;

  Future<void> chooseVideo() async {
    FilePickerResult? picked =
        await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi'],
    );

    if (picked != null) {
      setState(() {
        fileName = picked.files.single.name;
        result = "";
        confidence = "";
        reason = "";
        isSaved = false;
      });
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

    setState(() {
      isLoading = true;
      result = "";
      confidence = "";
      reason = "";
      isSaved = false;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (fileName.toLowerCase().contains("ai") ||
        fileName.toLowerCase().contains("fake")) {
      setState(() {
        result = _text('likelyAI', lang);
        confidence = "88%";
        reason = _text('aiReason', lang);
        isLoading = false;
      });

await HistoryService.saveHistory(
  type: 'video',
  titleKey: 'title',
  resultKey: 'likelyAI',
  confidence: "88%",
  noteKey: 'aiReason',
);
    } else {
      setState(() {
        result = _text('likelyReal', lang);
        confidence = "82%";
        reason = _text('realReason', lang);
        isLoading = false;
      });

await HistoryService.saveHistory(
  type: 'video',
  titleKey: 'title',
  resultKey: 'likelyReal',
  confidence: "82%",
  noteKey: 'realReason',
);
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
      result = "";
      confidence = "";
      reason = "";
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
                  onPressed: chooseVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A623),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.video_file),
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
                    style: const TextStyle(
                      color: Colors.white,
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
                        onPressed:
                            isLoading ? null : analyzeVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB8A7FF),
                          foregroundColor: Colors.white,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child:
                                    CircularProgressIndicator(
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
                      onPressed: clearVideo,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.white24),
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
                      color: isAiResult
                          ? Colors.redAccent
                          : Colors.greenAccent,
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
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              result,
                              style: TextStyle(
                                color: isAiResult
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
    };

    return data[key]?[lang] ?? data[key]?['en'] ?? key;
  }
}