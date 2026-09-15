import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/storage_service.dart';
import '../../users/users_service.dart';

class SettingsController extends GetxController {
  final UsersService _usersService;
  final StorageService _storage;

  SettingsController(this._usersService, this._storage);

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  final oldPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();

  final isSavingProfile = false.obs;
  final isSavingPassword = false.obs;

  int? get _userId => _storage.user?['id'] as int?;

  @override
  void onInit() {
    super.onInit();
    final u = _storage.user;
    if (u != null) {
      firstNameCtrl.text = u['first_name'] ?? '';
      lastNameCtrl.text = u['last_name'] ?? '';
      usernameCtrl.text = u['username'] ?? '';
      phoneCtrl.text = u['phone_number'] ?? '';
    }
  }

  Future<void> saveProfile() async {
    if (_userId == null) return;
    isSavingProfile.value = true;
    try {
      final updated = await _usersService.update(
        _userId!,
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
      );
      await _storage.saveUser(updated.toJson());
      Get.snackbar('Imefanikiwa', 'Taarifa za profile zimesasishwa.', snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSavingProfile.value = false;
    }
  }

  Future<void> changePassword() async {
    if (_userId == null) return;
    if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
      Get.snackbar('Kosa', 'Password mpya hazifanani.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (newPasswordCtrl.text.length < 6) {
      Get.snackbar('Kosa', 'Password mpya iwe angalau herufi 6.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    isSavingPassword.value = true;
    try {
      await _usersService.changePassword(
        _userId!,
        oldPassword: oldPasswordCtrl.text,
        newPassword: newPasswordCtrl.text,
      );
      oldPasswordCtrl.clear();
      newPasswordCtrl.clear();
      confirmPasswordCtrl.clear();
      Get.snackbar('Imefanikiwa', 'Password imebadilishwa.', snackPosition: SnackPosition.BOTTOM);
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSavingPassword.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in [
      firstNameCtrl, lastNameCtrl, usernameCtrl, phoneCtrl,
      oldPasswordCtrl, newPasswordCtrl, confirmPasswordCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
