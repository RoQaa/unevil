import 'package:flutter/material.dart';
import 'login_page.dart';
import 'text_page.dart';
import 'image_page.dart';
import 'audio_page.dart';
import 'video_page.dart';
import 'history_page.dart';
import 'app_translations.dart';
import 'profile_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String lang =
        Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF18245C),
        elevation: 0,
        centerTitle: true,

        title: const Text(
          'Unveil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ProfilePage(),
              ),
            );
          },
          icon: const Icon(
            Icons.person_outline,
            color: Colors.white,
          ),
        ),
      ),

      body: Directionality(
        textDirection:
            isArabic
                ? TextDirection.rtl
                : TextDirection.ltr,

        child: Padding(
          padding:
              const EdgeInsets.all(20),

          child: ListView(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 60,
                  ),

                  const SizedBox(
                      width: 12),

                  Expanded(
                    child: Text(
                      _text(
                        'welcomeHome',
                        lang,
                      ),
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                  height: 30),

              _buildFeatureCard(
                icon:
                    Icons.text_fields_rounded,
                title:
                    _text(
                        'textAnalysis',
                        lang),
                subtitle:
                    _text(
                        'textSub',
                        lang),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const TextAnalysisPage(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                icon:
                    Icons.image_rounded,
                title:
                    _text(
                        'imageAnalysis',
                        lang),
                subtitle:
                    _text(
                        'imageSub',
                        lang),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const ImageAnalysisPage(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                icon:
                    Icons.mic_rounded,
                title:
                    _text(
                        'audioAnalysis',
                        lang),
                subtitle:
                    _text(
                        'audioSub',
                        lang),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const AudioAnalysisPage(),
                    ),
                  );
                },
              ),

              _buildFeatureCard(
                icon:
                    Icons.videocam_rounded,
                title:
                    _text(
                        'videoAnalysis',
                        lang),
                subtitle:
                    _text(
                        'videoSub',
                        lang),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const VideoAnalysisPage(),
                    ),
                  );
                },
              ),

              const SizedBox(
                  height: 25),

              SizedBox(
                width:
                    double.infinity,
                height: 52,

                child:
                    ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const HistoryPage(),
                      ),
                    );
                  },

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                            0xFFF5A623),
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                  ),

                  icon: const Icon(
                      Icons.history),

                  label: Text(
                    _text(
                      'viewHistory',
                      lang,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _text(
    String key,
    String lang,
  ) {
    final data = {
      'welcomeHome': {
        'en':
            'Welcome back,\nLet’s detect suspicious content.',
        'ar':
            'مرحبًا بعودتك،\nلنكتشف المحتوى المشبوه.',
      },
      'textAnalysis': {
        'en':
            'Text Analysis',
        'ar':
            'تحليل النص',
      },
      'imageAnalysis': {
        'en':
            'Image Analysis',
        'ar':
            'تحليل الصور',
      },
      'audioAnalysis': {
        'en':
            'Audio Analysis',
        'ar':
            'تحليل الصوت',
      },
      'videoAnalysis': {
        'en':
            'Video Analysis',
        'ar':
            'تحليل الفيديو',
      },
      'viewHistory': {
        'en':
            'View History',
        'ar':
            'عرض السجل',
      },
      'textSub': {
        'en':
            'Analyze written content.',
        'ar':
            'تحليل النصوص المكتوبة.',
      },
      'imageSub': {
        'en':
            'Detect AI-generated images.',
        'ar':
            'كشف الصور المولدة.',
      },
      'audioSub': {
        'en':
            'Inspect voice files.',
        'ar':
            'فحص الملفات الصوتية.',
      },
      'videoSub': {
        'en':
            'Analyze video content.',
        'ar':
            'تحليل الفيديو.',
      },
    };

    return data[key]?[lang] ??
        data[key]?['en'] ??
        key;
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
              bottom: 15),

      child: Material(
        color:
            const Color(
                0xFF24356F),

        borderRadius:
            BorderRadius.circular(
                18),

        child: InkWell(
          borderRadius:
              BorderRadius.circular(
                  18),

          onTap: onTap,

          child: Padding(
            padding:
                const EdgeInsets.all(
                    18),

            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      Colors.white12,

                  child: Icon(
                    icon,
                    color:
                        const Color(
                            0xFFF5A623),
                    size: 28,
                  ),
                ),

                const SizedBox(
                    width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        title,
                        style:
                            const TextStyle(
                          color: Colors
                              .white,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                          height: 6),

                      Text(
                        subtitle,
                        style:
                            const TextStyle(
                          color: Colors
                              .white70,
                          fontSize:
                              13,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  color:
                      Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}