import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/app_text_styles.dart';
import '../core/app_styles.dart';
import '../core/responsive_wrapper.dart';
import 'history_service.dart';
import 'app_translations.dart';

/// صفحة السجل (History Page)، تعرض تاريخ جميع التحليلات التي قام بها المستخدم.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String lang = Localizations.localeOf(context).languageCode;
    final bool isArabic = lang == 'ar';
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFF18245C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF18245C),
          foregroundColor: Colors.white,
          title: Text(AppTranslations.text('historyTitle', lang)),
          actions: user == null
              ? []
              : [
                  IconButton(
                    onPressed: () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF24356F),
                            title: Text(
                              AppTranslations.text('deleteAllTitle', lang),
                                style: AppTextStyles.h3,
                            ),
                            content: Text(
                              AppTranslations.text('deleteAllMessage', lang),
                                style: AppTextStyles.bodyMedium,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: Text(
                                  AppTranslations.text('cancel', lang),
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: Text(
                                  AppTranslations.text('delete', lang),
                                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm != true) return;

                      await HistoryService.clearAllHistory();

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppTranslations.text('allDeleted', lang)),
                          backgroundColor: const Color(0xFF24356F),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.white,
                    ),
                    tooltip: AppTranslations.text('deleteAll', lang),
                  ),
                ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: const Color(0xFFF5A623),
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFFF5A623),
            tabs: [
              Tab(text: AppTranslations.text('all', lang)),
              Tab(text: AppTranslations.text('text', lang)),
              Tab(text: AppTranslations.text('image', lang)),
              Tab(text: AppTranslations.text('audio', lang)),
              Tab(text: AppTranslations.text('video', lang)),
            ],
          ),
        ),
        body: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: ResponsiveWrapper(
            child: user == null
              ? Center(
                  child: Text(
                    AppTranslations.text('noUser', lang),
                      style: AppTextStyles.bodyMedium,
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('history')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.r),
                          child: Text(
                            'Error:\n${snapshot.error}',
                              style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF5A623),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    final sortedDocs = [...docs];
                    sortedDocs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;

                      final aTime = aData['createdAt'];
                      final bTime = bData['createdAt'];

                      DateTime aDate = DateTime(2000);
                      DateTime bDate = DateTime(2000);

                      if (aTime is Timestamp) {
                        aDate = aTime.toDate();
                      } else if (aTime is DateTime) {
                        aDate = aTime;
                      }

                      if (bTime is Timestamp) {
                        bDate = bTime.toDate();
                      } else if (bTime is DateTime) {
                        bDate = bTime;
                      }

                      return bDate.compareTo(aDate);
                    });

                    return TabBarView(
                      children: [
                        _buildHistoryList(
                          context: context,
                          docs: sortedDocs,
                          lang: lang,
                          filterType: null,
                          userId: user.uid,
                        ),
                        _buildHistoryList(
                          context: context,
                          docs: sortedDocs,
                          lang: lang,
                          filterType: 'text',
                          userId: user.uid,
                        ),
                        _buildHistoryList(
                          context: context,
                          docs: sortedDocs,
                          lang: lang,
                          filterType: 'image',
                          userId: user.uid,
                        ),
                        _buildHistoryList(
                          context: context,
                          docs: sortedDocs,
                          lang: lang,
                          filterType: 'audio',
                          userId: user.uid,
                        ),
                        _buildHistoryList(
                          context: context,
                          docs: sortedDocs,
                          lang: lang,
                          filterType: 'video',
                          userId: user.uid,
                        ),
                      ],
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  /// دالة مساعدة لبناء قائمة (ListView) تعرض عناصر السجل، وتدعم الفلترة (نصوص، صور، صوت، فيديو).
  Widget _buildHistoryList({
    required BuildContext context,
    required List<QueryDocumentSnapshot> docs,
    required String lang,
    required String? filterType,
    required String userId,
  }) {
    final filteredDocs = filterType == null
        ? docs
        : docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['type'] == filterType;
          }).toList();

    if (filteredDocs.isEmpty) {
      return Center(
        child: Text(
          AppTranslations.text('empty', lang),
            style: AppTextStyles.bodyMedium,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(20.r),
      child: ListView.separated(
        itemCount: filteredDocs.length,
        separatorBuilder: (_, __) => SizedBox(height: 15.h),
        itemBuilder: (context, index) {
          final doc = filteredDocs[index];
          final data = doc.data() as Map<String, dynamic>;

          final String title = data['title'] ?? '';
          final String result = data['result'] ?? '';
          final String confidence = data['confidence'] ?? '';
          final String note = data['note'] ?? '';
          final String type = data['type'] ?? '';

          final createdAtRaw = data['createdAt'];
          DateTime? createdAt;

          if (createdAtRaw is Timestamp) {
            createdAt = createdAtRaw.toDate();
          } else if (createdAtRaw is DateTime) {
            createdAt = createdAtRaw;
          }

final lowerResult = result.toLowerCase();

final bool isAi =
    (lowerResult.contains('ai generated') ||
     lowerResult.contains('likely ai') ||
     lowerResult.contains('ai audio') ||
     lowerResult.contains('مولد') ||
     lowerResult.contains('ذكاء')) &&
    !lowerResult.contains('real') &&
    !lowerResult.contains('human') &&
    !lowerResult.contains('authentic');
          return Dismissible(
            key: Key(doc.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(16.r),
              ),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28.r,
              ),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF24356F),
                    title: Text(
                      AppTranslations.text('deleteItemTitle', lang),
                      style: const TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      AppTranslations.text('deleteItemMessage', lang),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          AppTranslations.text('cancel', lang),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          AppTranslations.text('delete', lang),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (_) async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('history')
                  .doc(doc.id)
                  .delete();

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppTranslations.text('deleted', lang)),
                  backgroundColor: const Color(0xFF24356F),
                ),
              );
            },
            child: HistoryCard(
              docId: doc.id,
              userId: userId,
              title: title,
              result: result,
              confidence: confidence,
              date: _formatDate(createdAt, lang),
              note: note,
              isAi: isAi,
              type: type,
              lang: lang,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date, String lang) {
    if (date == null) {
      return lang == 'ar' ? 'الآن' : 'Now';
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final day = twoDigits(date.day);
    final month = twoDigits(date.month);
    final year = date.year.toString();

    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);

    final minute = twoDigits(date.minute);

    final period =
        date.hour >= 12 ? (lang == 'ar' ? 'م' : 'PM') : (lang == 'ar' ? 'ص' : 'AM');

    return '$day/$month/$year - $hour:$minute $period';
  }

}

/// بطاقة مخصصة لعرض كل عملية تحليل سابقة في السجل بشكل منسق.
class HistoryCard extends StatelessWidget {
  final String docId;
  final String userId;
  final String title;
  final String result;
  final String confidence;
  final String date;
  final String note;
  final bool isAi;
  final String type;
  final String lang;

  const HistoryCard({
    super.key,
    required this.docId,
    required this.userId,
    required this.title,
    required this.result,
    required this.confidence,
    required this.date,
    required this.note,
    required this.isAi,
    required this.type,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isAi ? Colors.redAccent : Colors.greenAccent;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: const Color(0xFF24356F),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color,
          width: 1.3.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAi ? Icons.smart_toy_outlined : Icons.verified_outlined,
            color: color,
            size: 28.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF24356F),
                              title: Text(
                                lang == 'ar'
                                    ? 'حذف هذا العنصر؟'
                                    : 'Delete this item?',
                                style: const TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                lang == 'ar'
                                    ? 'سيتم حذف هذا التحليل من السجل.'
                                    : 'This analysis will be removed from history.',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    lang == 'ar' ? 'إلغاء' : 'Cancel',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: Text(
                                    lang == 'ar' ? 'حذف' : 'Delete',
                                    style: TextStyle(
                                        color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm != true) return;

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('history')
                            .doc(docId)
                            .delete();

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              lang == 'ar'
                                  ? 'تم حذف العنصر'
                                  : 'Item deleted',
                            ),
                            backgroundColor: const Color(0xFF24356F),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.white70,
                        size: 20.r,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  result,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "${lang == 'ar' ? 'الثقة' : 'Confidence'}: $confidence",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _typeLabel(type, lang),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type, String lang) {
    final labels = {
      'text': {
        'en': 'TEXT',
        'ar': 'نص',
      },
      'image': {
        'en': 'IMAGE',
        'ar': 'صورة',
      },
      'audio': {
        'en': 'AUDIO',
        'ar': 'صوت',
      },
      'video': {
        'en': 'VIDEO',
        'ar': 'فيديو',
      },
    };

    return labels[type]?[lang] ?? labels[type]?['en'] ?? type.toUpperCase();
  }
}
