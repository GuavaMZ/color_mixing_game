import 'package:color_mixing_deductive/helpers/string_manager.dart';

void main() {
  final List<Map<String, dynamic>> maps = [
    AppStrings.en,
    AppStrings.ar,
    AppStrings.es,
    AppStrings.fr,
  ];
  final List<String> names = ['En', 'Ar', 'Es', 'Fr'];

  // Identify all keys used across all maps
  Set<String> allKeys = {};
  for (var map in maps) {
    allKeys.addAll(map.keys);
  }

  // ignore: avoid_print
  print('Total unique keys found in maps: ${allKeys.length}');

  bool overallPass = true;
  Map<String, List<String>> missingReport = {};

  for (int i = 0; i < maps.length; i++) {
    final map = maps[i];
    final name = names[i];

    List<String> missing = [];
    for (var key in allKeys) {
      if (!map.containsKey(key)) {
        missing.add(key);
      }
    }

    if (missing.isNotEmpty) {
      missingReport[name] = missing;
      overallPass = false;
    }
  }

  if (overallPass) {
    // ignore: avoid_print
    print('\n[SUCCESS] All language maps are synchronized!');
  } else {
    // ignore: avoid_print
    print('\n[ERROR] Localization mismatch detected:');
    missingReport.forEach((name, missing) {
      // ignore: avoid_print
      print('\nMap $name is missing ${missing.length} keys:');
      for (var key in missing) {
        // ignore: avoid_print
        print('  - $key');
      }
    });
  }
}
