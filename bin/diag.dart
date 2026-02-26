import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() async {
  final updater = ShorebirdUpdater();
  // ignore: avoid_print
  print('ShorebirdUpdater created');

  // Checking for methods - this will fail to compile if they don't exist
  // but I'm checking against documentation now.
  try {
    final patch = await updater.readCurrentPatch();
    // ignore: avoid_print
    print('readCurrentPatch exists: $patch');
  } catch (e) {
    // ignore: avoid_print
    print('readCurrentPatch error: $e');
  }

  try {
    final status = await updater.checkForUpdate();
    // ignore: avoid_print
    print('checkForUpdate exists: $status');
  } catch (e) {
    // ignore: avoid_print
    print('checkForUpdate error: $e');
  }
}
