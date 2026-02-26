import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:color_mixing_deductive/core/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await SecurityService.initialize();
  });

  group('Redeem System Tests', () {
    test('Code should not be redeemed initially', () async {
      final isRedeemed = await SaveManager.isCodeRedeemed('richie');
      expect(isRedeemed, false);
    });

    test('Code should be marked as redeemed', () async {
      await SaveManager.markCodeAsRedeemed('richie');
      final isRedeemed = await SaveManager.isCodeRedeemed('richie');
      expect(isRedeemed, true);
    });

    test('Multiple codes can be redeemed', () async {
      await SaveManager.markCodeAsRedeemed('richie');
      await SaveManager.markCodeAsRedeemed('totymz');

      expect(await SaveManager.isCodeRedeemed('richie'), true);
      expect(await SaveManager.isCodeRedeemed('totymz'), true);
      expect(await SaveManager.isCodeRedeemed('unknown'), false);
    });
  });
}
