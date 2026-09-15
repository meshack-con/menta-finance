import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/storage_service.dart';

/// Inasimamia Dark/Light theme ya Admin Panel nzima - imehifadhiwa kwenye
/// storage ili ibaki ile ile Admin akifunga na kufungua browser tena.
/// (Awali kulikuwa na 'ThemeController' ya Provider ambayo haikuwa
/// imeunganishwa na 'theme:' ya GetMaterialApp kabisa - ilikuwa 'mfano'
/// tu. Hii sasa inafanya kazi kikamilifu, GetX-based kama sehemu nyingine
/// zote za app hii.)
class ThemeController extends GetxController {
  final StorageService _storage;
  ThemeController(this._storage);

  final themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _storage.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => themeMode.value == ThemeMode.dark;

  void toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  void setMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    _storage.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
  }
}
