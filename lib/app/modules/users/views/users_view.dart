import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../../auth/models/user_model.dart';
import '../controllers/users_controller.dart';

class UsersView extends GetView<UsersController> {
  const UsersView({super.key});

  bool get _isAdmin => Get.find<StorageService>().isAdmin;

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin;
    return AppShell(
      title: 'Watumiaji wa Mfumo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Watumiaji wa Mfumo',
                  subtitle: 'Hawa ndio watu wanaoingia (login) kusimamia Admin Panel.',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showUserDialog(context, isAdmin: isAdmin),
                icon: const Icon(Icons.person_add_alt, size: 18),
                // MANAGER anaruhusiwa kusajili STAFF MEMBER pekee (angalia
                // Backend /api/users/ - roles nyingine zinakataliwa kwake).
                label: Text(isAdmin ? 'Ongeza Mtumiaji' : 'Ongeza Staff Member'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 340,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Jina, username, simu au roles...',
                isDense: true,
              ),
              onChanged: (v) => controller.searchText.value = v,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value != null) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: controller.loadUsers, child: const Text('Jaribu tena')),
                  ]),
                );
              }
              final list = controller.filteredUsers;
              return SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Orodha ya Watumiaji', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        DataTableCard(
                          emptyIcon: Icons.group_outlined,
                          emptyTitle: controller.searchText.value.isEmpty ? 'Hakuna watumiaji bado.' : 'Hakuna matokeo.',
                          emptySubtitle: controller.searchText.value.isEmpty
                              ? 'Ongeza mtumiaji wa kwanza kwa kutumia kitufe hapo juu.'
                              : 'Badilisha neno la kutafuta ujaribu tena.',
                          columns: const [
                            DataColumn(label: Text('Jina')),
                            DataColumn(label: Text('Username')),
                            DataColumn(label: Text('Namba ya Simu')),
                            DataColumn(label: Text('Password')),
                            DataColumn(label: Text('Role')),
                            DataColumn(label: Text('Vitendo')),
                          ],
                          rows: list.map((u) {
                            return DataRow(cells: [
                              DataCell(Text(u.fullName.isEmpty ? '-' : u.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(u.username)),
                              DataCell(Text(u.phoneNumber ?? '-')),
                              const DataCell(Text('********', style: TextStyle(letterSpacing: 1.5))),
                              DataCell(Text(u.roles.isEmpty ? '-' : u.roles)),
                              // MANAGER hana ruhusa ya ku-edit, ku-block, wala
                              // kufuta mtumiaji - anaweza TU kusajili STAFF
                              // mpya (kitufe cha juu). Hivyo vitendo hivi
                              // vinaonekana kwa ADMIN pekee.
                              DataCell(isAdmin
                                  ? Row(children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                                        tooltip: 'Hariri taarifa',
                                        onPressed: () => _showUserDialog(context, existing: u, isAdmin: isAdmin),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          u.isBlocked ? Icons.lock_open_outlined : Icons.lock_outline,
                                          size: 18,
                                          color: AppColors.warning,
                                        ),
                                        tooltip: u.isBlocked ? 'Fungua (Unblock)' : 'Zuia (Block)',
                                        onPressed: () => controller.toggleBlocked(u),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                        tooltip: 'Futa',
                                        onPressed: () => _confirmDelete(context, u),
                                      ),
                                    ])
                                  : const Text('-', style: TextStyle(color: AppColors.textSecondary))),
                            ]);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Futa Mtumiaji'),
        content: Text('Una uhakika unataka kumfuta "${user.username}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.deleteUser(user.id);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }

  void _showUserDialog(BuildContext context, {UserModel? existing, required bool isAdmin}) {
    final firstNameCtrl = TextEditingController(text: existing?.firstName ?? '');
    final lastNameCtrl = TextEditingController(text: existing?.lastName ?? '');
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '');
    final passwordCtrl = TextEditingController();
    // Role MOJA TU kwa mtumiaji (Backend inatumia role moja - ADMIN,
    // MANAGER au STAFF - siyo orodha). MANAGER hawezi kuchagua - anasajili
    // STAFF MEMBER pekee, hivyo tunamlazimisha 'STAFF' moja kwa moja.
    final existingRole = (existing != null && existing.roleList.isNotEmpty) ? existing.roleList.first : 'STAFF';
    final selectedRole = RxString(isAdmin ? existingRole : 'STAFF');

    Get.dialog(
      AlertDialog(
        title: Text(existing == null ? 'Ongeza Mtumiaji' : 'Hariri Mtumiaji'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: 'Jina la Kwanza')),
                const SizedBox(height: 10),
                TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: 'Jina la Mwisho')),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameCtrl,
                  enabled: existing == null, // username haibadiliki baada ya kuundwa
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Simu')),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: existing == null ? 'Password' : 'Password Mpya (hiari)',
                    helperText: existing == null ? null : 'Acha wazi kama hutaki kuibadilisha.',
                  ),
                ),
                const SizedBox(height: 12),
                if (isAdmin) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Role', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Obx(
                    () => Column(
                      children: [
                        RadioListTile<String>(
                          value: 'ADMIN',
                          groupValue: selectedRole.value,
                          title: const Text('ADMIN'),
                          onChanged: (v) => selectedRole.value = v!,
                        ),
                        RadioListTile<String>(
                          value: 'MANAGER',
                          groupValue: selectedRole.value,
                          title: const Text('MANAGER'),
                          onChanged: (v) => selectedRole.value = v!,
                        ),
                        RadioListTile<String>(
                          value: 'STAFF',
                          groupValue: selectedRole.value,
                          title: const Text('STAFF MEMBER'),
                          onChanged: (v) => selectedRole.value = v!,
                        ),
                      ],
                    ),
                  ),
                ] else
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Role: STAFF MEMBER',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () async {
                      bool ok;
                      if (existing == null) {
                        if (usernameCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
                          Get.snackbar('Kosa', 'Username na password ni lazima.', snackPosition: SnackPosition.BOTTOM);
                          return;
                        }
                        ok = await controller.createUser(
                          username: usernameCtrl.text.trim(),
                          password: passwordCtrl.text,
                          firstName: firstNameCtrl.text.trim(),
                          lastName: lastNameCtrl.text.trim(),
                          phoneNumber: phoneCtrl.text.trim(),
                          roles: [selectedRole.value],
                        );
                      } else {
                        ok = await controller.updateUser(
                          existing.id,
                          firstName: firstNameCtrl.text.trim(),
                          lastName: lastNameCtrl.text.trim(),
                          phoneNumber: phoneCtrl.text.trim(),
                          roles: [selectedRole.value],
                        );
                      }
                      if (ok && existing != null && passwordCtrl.text.isNotEmpty) {
                        ok = await controller.resetPassword(existing.id, passwordCtrl.text);
                      }
                      if (ok) Get.back();
                    },
              child: controller.isSaving.value
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Hifadhi'),
            ),
          ),
        ],
      ),
    );
  }
}
