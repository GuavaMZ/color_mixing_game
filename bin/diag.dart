import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:flutter/foundation.dart';

void main() async {
  final updater = ShorebirdUpdater();

  // Checking for methods - this will fail to compile if they don't exist.
  try {
    await updater.readCurrentPatch();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Diag error: $e');
    }
  }

  try {
    await updater.checkForUpdate();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Diag error: $e');
    }
  }
}
