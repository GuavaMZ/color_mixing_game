import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../helpers/global_variables.dart';

enum UpdateStatus { upToDate, optionalUpdate, mandatoryUpdate }

class VersionCheckService {
  VersionCheckService._();
  static final VersionCheckService instance = VersionCheckService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UpdateStatus> checkUpdate() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('app_version')
          .get();
      if (!doc.exists) return UpdateStatus.upToDate;

      final data = doc.data()!;
      final latestVersion = data['latest_version'] as String?;
      final minVersion = data['min_version'] as String?;

      if (latestVersion == null) return UpdateStatus.upToDate;

      final currentVersion = GlobalConstants.appVersion.split(
        '+',
      )[0]; // Ignore build number for simple comparison

      if (minVersion != null && _isVersionGreater(minVersion, currentVersion)) {
        return UpdateStatus.mandatoryUpdate;
      }

      if (_isVersionGreater(latestVersion, currentVersion)) {
        return UpdateStatus.optionalUpdate;
      }

      return UpdateStatus.upToDate;
    } catch (e) {
      debugPrint('Version check failed: $e');
      return UpdateStatus.upToDate;
    }
  }

  bool _isVersionGreater(String v1, String v2) {
    final nums1 = v1.split('.').map(int.parse).toList();
    final nums2 = v2.split('.').map(int.parse).toList();
    final maxLength = nums1.length > nums2.length ? nums1.length : nums2.length;

    for (int i = 0; i < maxLength; i++) {
      final n1 = i < nums1.length ? nums1[i] : 0;
      final n2 = i < nums2.length ? nums2[i] : 0;
      if (n1 > n2) return true;
      if (n1 < n2) return false;
    }
    return false;
  }
}
