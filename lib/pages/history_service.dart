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
}