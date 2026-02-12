import 'package:color_mixing_deductive/helpers/string_manager.dart';

void main() {
  final List<Map<String, dynamic>> maps = [
    AppStrings.En,
    AppStrings.Ar,
    AppStrings.Es,
    AppStrings.Fr,
  ];
  final List<String> names = ['En', 'Ar', 'Es', 'Fr'];

  // Identify all keys used across all maps
  Set<String> allKeys = {};
  for (var map in maps) {
    allKeys.addAll(map.keys);
  }

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
    print('\n[SUCCESS] All language maps are synchronized!');
  } else {
    print('\n[ERROR] Localization mismatch detected:');
    missingReport.forEach((name, missing) {
      print('\nMap $name is missing ${missing.length} keys:');
      for (var key in missing) {
        print('  - $key');
      }
    });
  }
}
