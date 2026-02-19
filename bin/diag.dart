import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() async {
  final updater = ShorebirdUpdater();
  print('ShorebirdUpdater created');

  // Checking for methods - this will fail to compile if they don't exist
  // but I'm checking against documentation now.
  try {
    final patch = await updater.readCurrentPatch();
    print('readCurrentPatch exists: $patch');
  } catch (e) {
    print('readCurrentPatch error: $e');
  }

  try {
    final status = await updater.checkForUpdate();
    print('checkForUpdate exists: $status');
  } catch (e) {
    print('checkForUpdate error: $e');
  }
}
