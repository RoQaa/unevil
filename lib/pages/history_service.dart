import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة السجل (History Service).
/// مسؤولة عن التخاطب مع Firebase Firestore لحفظ واسترجاع وحذف عمليات التحليل السابقة الخاصة بالمستخدم.
class HistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// دالة لحفظ نتيجة تحليل جديدة في قاعدة البيانات (Firestore).
  /// تقوم بتخزين نوع التحليل (نص، صورة، فيديو، صوت)، النتيجة، ونسبة الثقة مع ربطها بمعرف المستخدم (UID).
  static Future<void> saveHistory({
    required String type,
    required String titleKey,
    required String resultKey,
    required String confidence,
    required String noteKey,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .add({
      'type': type,
      'titleKey': titleKey,
      'resultKey': resultKey,
      'confidence': confidence,
      'noteKey': noteKey,
      'createdAt': DateTime.now(),
      'userId': user.uid,
    });
  }

  /// دالة لمسح كافة السجل الخاص بالمستخدم الحالي دفعة واحدة.
  /// تقوم بجلب جميع المستندات (Documents) الخاصة به وحذفها عبر عملية مجمعة (Batch) لضمان السرعة وتجنب الأخطاء.
  static Future<void> clearAllHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// دالة لحذف عنصر تحليل واحد فقط من السجل باستخدام المعرف الخاص به (docId).
  static Future<void> deleteHistoryItem(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .doc(docId)
        .delete();
  }
}