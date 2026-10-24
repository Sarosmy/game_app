import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false){
    _load();
  }

  final _key = "ThemeNotifier";
  final _storage = FlutterSecureStorage();

  void _load() async {
    String value = await _storage.read(key: _key) ?? "false";
    state = bool.tryParse(value) ?? false;
  }

  void toggleDark() {
    state = !state;
    _storage.write(key: _key, value: state.toString());
  }
}final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
}); // StateNotifierProvider

class ColorNotifier extends StateNotifier<int> {
  ColorNotifier() : super(0) {
    _load();
  }

  final _storage = FlutterSecureStorage();
  final _key = "ColorIndex";

  void _load() async {
    String value = await _storage.read(key: _key) ?? "0";
    state = int.tryParse(value) ?? 0;
  }

  void changeIndex(int index) {
    state = index;
    _storage.write(key: _key, value: index.toString());
  }
}

final colorNotifierProvider = StateNotifierProvider<ColorNotifier, int>((ref) {
  return ColorNotifier();
});
