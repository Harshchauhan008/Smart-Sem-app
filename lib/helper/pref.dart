
import 'package:hive_ce_flutter/hive_flutter.dart';

class Pref {
  Pref._();

  static late Box _box;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('myData');
  }

  static bool get showOnboarding =>
      _box.get('showOnboarding', defaultValue: true) as bool;

  static set showOnboarding(bool value) {
    _box.put('showOnboarding', value);
  }


  static String? get authToken => _box.get('authToken') as String?;

  static set authToken(String? value) {
    if (value == null || value.isEmpty) {
      _box.delete('authToken');
    } else {
      _box.put('authToken', value);
    }
  }

  static String? get userEmail => _box.get('userEmail') as String?;

  static set userEmail(String? value) {
    if (value == null || value.isEmpty) {
      _box.delete('userEmail');
    } else {
      _box.put('userEmail', value);
    }
  }


}
