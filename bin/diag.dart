import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() async {
  final updater = ShorebirdUpdater();

  // Checking for methods - this will fail to compile if they don't exist
  // but I'm checking against documentation now.
  try {
    await updater.readCurrentPatch();
  } catch (e) {}

  try {
    await updater.checkForUpdate();
  } catch (e) {}
}
