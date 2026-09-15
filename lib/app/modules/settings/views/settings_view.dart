import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/theme_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return AppShell(
      title: 'Mipangilio',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(
              title: 'appearance'.tr,
              children: [
                Obx(
                  () => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(themeController.isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.primaryGreen),
                    title: Text('dark_mode'.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
                    value: themeController.isDark,
                    onChanged: (_) => themeController.toggle(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Card(
              title: 'Profile',
              children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: controller.firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'Jina la Kwanza'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: controller.lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Jina la Mwisho'),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: controller.usernameCtrl,
                      enabled: false,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: controller.phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Simu'),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSavingProfile.value ? null : controller.saveProfile,
                    child: controller.isSavingProfile.value
                        ? const SizedBox(
                            height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Hifadhi Mabadiliko'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Card(
              title: 'Badilisha Password',
              children: [
                TextField(
                  controller: controller.oldPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password ya Sasa'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.newPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password Mpya'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.confirmPasswordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Thibitisha Password Mpya'),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => ElevatedButton(
                    onPressed: controller.isSavingPassword.value ? null : controller.changePassword,
                    child: controller.isSavingPassword.value
                        ? const SizedBox(
                            height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Badilisha Password'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
