import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String lang =
        Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF18245C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18245C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_text('profile', lang)),
      ),
      body: Directionality(
        textDirection: isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: user == null
            ? Center(
                child: Text(
                  _text('noUser', lang),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              )
            : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore
                    .instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('profile')
                    .doc('info')
                    .get(),
                builder: (context, profileSnapshot) {
                  final profileData =
                      profileSnapshot.data?.data()
                          as Map<String, dynamic>?;

                  final String fullName =
                      profileData?['fullName'] ??
                          '--';

                  final String age =
                      profileData?['age']
                              ?.toString() ??
                          '--';

                  final String gender =
                      profileData?['gender'] ??
                          '--';

                  return StreamBuilder<
                      QuerySnapshot>(
                    stream:
                        FirebaseFirestore
                            .instance
                            .collection(
                                'users')
                            .doc(user.uid)
                            .collection(
                                'history')
                            .snapshots(),
                    builder: (context,
                        historySnapshot) {
                      final docs =
                          historySnapshot
                                  .data
                                  ?.docs ??
                              [];

                      int textCount = 0;
                      int imageCount = 0;
                      int audioCount = 0;
                      int videoCount = 0;

                      for (final doc in docs) {
                        final data =
                            doc.data()
                                as Map<String,
                                    dynamic>;

                        final type =
                            data['type'];

                        if (type ==
                            'text') {
                          textCount++;
                        }

                        if (type ==
                            'image') {
                          imageCount++;
                        }

                        if (type ==
                            'audio') {
                          audioCount++;
                        }

                        if (type ==
                            'video') {
                          videoCount++;
                        }
                      }

                      return Padding(
                        padding:
                            const EdgeInsets.all(
                                20),
                        child: ListView(
                          children: [
                            const Center(
                              child:
                                  CircleAvatar(
                                radius: 42,
                                backgroundColor:
                                    Color(
                                        0xFFF5A623),
                                child: Icon(
                                  Icons.person,
                                  color: Colors
                                      .white,
                                  size: 40,
                                ),
                              ),
                            ),

                            const SizedBox(
                                height:
                                    20),

                            _infoCard(
                              icon: Icons
                                  .badge_outlined,
                              label: _text(
                                  'fullName',
                                  lang),
                              value:
                                  fullName,
                            ),

                            const SizedBox(
                                height:
                                    14),

                            _infoCard(
                              icon: Icons
                                  .email_outlined,
                              label: _text(
                                  'email',
                                  lang),
                              value:
                                  user.email ??
                                      '--',
                            ),

                            const SizedBox(
                                height:
                                    14),

                            _infoCard(
                              icon: Icons
                                  .person_outline,
                              label: _text(
                                  'gender',
                                  lang),
                              value:
                                  _translatedGender(
                                      gender,
                                      lang),
                            ),

                            const SizedBox(
                                height:
                                    14),

                            _infoCard(
                              icon: Icons
                                  .cake_outlined,
                              label: _text(
                                  'age',
                                  lang),
                              value:
                                  age,
                            ),

                            const SizedBox(
                                height:
                                    18),

                            Container(
                              padding:
                                  const EdgeInsets.all(
                                      20),
                              decoration:
                                  BoxDecoration(
                                color: const Color(
                                    0xFF24356F),
                                borderRadius:
                                    BorderRadius.circular(
                                        18),
                              ),
                              child:
                                  Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons
                                            .analytics_outlined,
                                        color:
                                            Color(
                                                0xFFF5A623),
                                        size:
                                            24,
                                      ),
                                      const SizedBox(
                                          width:
                                              10),
                                      Text(
                                        _text(
                                            'statistics',
                                            lang),
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.white,
                                          fontSize:
                                              17,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                      height:
                                          16),

                                  _statRow(
                                    _text(
                                        'analysisCount',
                                        lang),
                                    docs.length
                                        .toString(),
                                  ),

                                  const SizedBox(
                                      height:
                                          10),

                                  _statRow(
                                    _text(
                                        'text',
                                        lang),
                                    textCount
                                        .toString(),
                                  ),

                                  const SizedBox(
                                      height:
                                          10),

                                  _statRow(
                                    _text(
                                        'image',
                                        lang),
                                    imageCount
                                        .toString(),
                                  ),

                                  const SizedBox(
                                      height:
                                          10),

                                  _statRow(
                                    _text(
                                        'audio',
                                        lang),
                                    audioCount
                                        .toString(),
                                  ),

                                  const SizedBox(
                                      height:
                                          10),

                                  _statRow(
                                    _text(
                                        'video',
                                        lang),
                                    videoCount
                                        .toString(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                                height:
                                    18),

                            _languageCard(
                                context,
                                lang),

                            const SizedBox(
                                height:
                                    14),

                            _logoutCard(
                                context,
                                lang),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFF24356F),
        borderRadius:
            BorderRadius.circular(
                18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Colors.white12,
            child: Icon(
              icon,
              color: const Color(
                  0xFFF5A623),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    color: Colors
                        .white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                    height: 4),

                Text(
                  value,
                  style:
                      const TextStyle(
                    color: Colors
                        .white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    String label,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius:
            BorderRadius.circular(
                14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(
              color: Color(
                  0xFFF5A623),
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageCard(
    BuildContext context,
    String lang,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            const Color(0xFF24356F),
        borderRadius:
            BorderRadius.circular(
                18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor:
                Colors.white12,
            child: Icon(
              Icons.language,
              color: Color(
                  0xFFF5A623),
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              _text(
                  'language',
                  lang),
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),

          PopupMenuButton<
              String>(
            color: Colors.white,
            icon: const Icon(
              Icons.arrow_drop_down,
              color:
                  Colors.white,
            ),
            onSelected:
                (value) {
              UnveilApp.of(
                      context)
                  .changeLanguage(
                      value);
            },
            itemBuilder:
                (context) =>
                    const [
              PopupMenuItem(
                value: 'en',
                child: Text(
                    'English'),
              ),
              PopupMenuItem(
                value: 'ar',
                child: Text(
                    'العربية'),
              ),
              PopupMenuItem(
                value: 'es',
                child: Text(
                    'Español'),
              ),
              PopupMenuItem(
                value: 'fr',
                child: Text(
                    'Français'),
              ),
              PopupMenuItem(
                value: 'zh',
                child: Text(
                    '中文'),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Text(
                    'हिन्दी'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoutCard(
    BuildContext context,
    String lang,
  ) {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth
            .instance
            .signOut();

        if (!context.mounted)
          return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    const LoginPage(),
          ),
          (route) => false,
        );
      },
      child: Container(
        padding:
            const EdgeInsets.all(
                18),
        decoration: BoxDecoration(
          color:
              const Color(
                  0xFF24356F),
          borderRadius:
              BorderRadius.circular(
                  18),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor:
                  Colors.white12,
              child: Icon(
                Icons.logout,
                color: Colors
                    .redAccent,
                size: 22,
              ),
            ),

            const SizedBox(
                width: 14),

            Expanded(
              child: Text(
                _text(
                    'logout',
                    lang),
                style:
                    const TextStyle(
                  color: Colors
                      .white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight
                          .w600,
                ),
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
    );
  }

  String _translatedGender(
    String gender,
    String lang,
  ) {
    final data = {
      'Male': {
        'en': 'Male',
        'ar': 'ذكر',
      },
      'Female': {
        'en': 'Female',
        'ar': 'أنثى',
      },
      '--': {
        'en': '--',
        'ar': '--',
      },
    };

    return data[gender]?[lang] ??
        data[gender]?['en'] ??
        gender;
  }

  String _text(
    String key,
    String lang,
  ) {
    final data = {
      'profile': {
        'en':
            'Profile & Settings',
        'ar':
            'الملف الشخصي والإعدادات',
      },
      'noUser': {
        'en':
            'No user logged in',
        'ar':
            'لا يوجد مستخدم',
      },
      'fullName': {
        'en': 'Full Name',
        'ar': 'الاسم',
      },
      'email': {
        'en': 'Email',
        'ar':
            'البريد الإلكتروني',
      },
      'gender': {
        'en': 'Gender',
        'ar': 'الجنس',
      },
      'age': {
        'en': 'Age',
        'ar': 'العمر',
      },
      'statistics': {
        'en': 'Statistics',
        'ar':
            'الإحصائيات',
      },
      'analysisCount': {
        'en':
            'Total Analyses',
        'ar':
            'إجمالي التحليلات',
      },
      'language': {
        'en': 'Language',
        'ar': 'اللغة',
      },
      'logout': {
        'en': 'Log Out',
        'ar':
            'تسجيل الخروج',
      },
      'text': {
        'en':
            'Text Analyses',
        'ar':
            'تحليلات النص',
      },
      'image': {
        'en':
            'Image Analyses',
        'ar':
            'تحليلات الصور',
      },
      'audio': {
        'en':
            'Audio Analyses',
        'ar':
            'تحليلات الصوت',
      },
      'video': {
        'en':
            'Video Analyses',
        'ar':
            'تحليلات الفيديو',
      },
    };

    return data[key]?[lang] ??
        data[key]?['en'] ??
        key;
  }
}