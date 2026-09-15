import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/models/user_model.dart';
import '../users_service.dart';

class UsersController extends GetxController {
  final UsersService _service;
  UsersController(this._service);

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final users = <UserModel>[].obs;
  final searchText = ''.obs;

  List<UserModel> get filteredUsers {
    final q = searchText.value.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          (u.phoneNumber ?? '').toLowerCase().contains(q) ||
          u.roles.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      users.assignAll(await _service.list());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia watumiaji.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createUser({
    required String username,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    required List<String> roles,
  }) async {
    isSaving.value = true;
    try {
      await _service.create(
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        roles: roles.join(','),
      );
      await loadUsers();
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateUser(
    int id, {
    String? firstName,
    String? lastName,
    String? phoneNumber,
    List<String>? roles,
    int? active,
    bool? isBlocked,
  }) async {
    isSaving.value = true;
    try {
      await _service.update(
        id,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        roles: roles?.join(','),
        active: active,
        isBlocked: isBlocked,
      );
      await loadUsers();
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleBlocked(UserModel user) async {
    await updateUser(user.id, isBlocked: !user.isBlocked);
  }

  Future<bool> resetPassword(int id, String newPassword) async {
    isSaving.value = true;
    try {
      await _service.resetPassword(id, newPassword: newPassword);
      Get.snackbar('Imefanikiwa', 'Password ya mtumiaji imebadilishwa.', snackPosition: SnackPosition.BOTTOM);
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _service.delete(id);
      Get.snackbar('Imefanikiwa', 'Mtumiaji amefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadUsers();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
