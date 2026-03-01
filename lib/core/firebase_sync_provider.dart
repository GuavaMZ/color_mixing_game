import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cloud_sync_service.dart';

/// Firebase implementation of CloudSyncProvider using Firestore and Anonymous Auth.
class FirebaseSyncProvider implements CloudSyncProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _cachedUserId;

  @override
  Future<String?> get userId async {
    if (_cachedUserId != null) return _cachedUserId;

    try {
      final user =
          _auth.currentUser ??
          await _auth.signInAnonymously().then((v) => v.user);
      _cachedUserId = user?.uid;
      return _cachedUserId;
    } catch (e) {
      return null;
    }
  }

  DocumentReference get _userDoc {
    final uid = _cachedUserId;
    if (uid == null) throw StateError('User not authenticated');
    return _firestore.collection('player_data').doc(uid);
  }

  @override
  Future<void> upload(String key, String data, int timestamp) async {
    final uid = await userId;
    if (uid == null) return;

    await _userDoc.set({
      key: {'d': data, 't': timestamp},
    }, SetOptions(merge: true));
  }

  @override
  Future<CloudData?> download(String key) async {
    final uid = await userId;
    if (uid == null) return null;

    final doc = await _userDoc.get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey(key)) return null;

    final entry = data[key] as Map<String, dynamic>;
    return CloudData.fromJson(entry);
  }

  @override
  Future<void> syncAll(Map<String, CloudData> data) async {
    final uid = await userId;
    if (uid == null) return;

    final batch = <String, dynamic>{};
    data.forEach((key, value) {
      batch[key] = value.toJson();
    });

    await _userDoc.set(batch, SetOptions(merge: true));
  }
}
