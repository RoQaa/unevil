import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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