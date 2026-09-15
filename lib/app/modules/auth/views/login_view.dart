import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  // Rangi hizi zinafanana na gradient ya logo ya Menta Finance
  // (kijani -> teal). Zimewekwa hapa tu ili kutobadilisha rangi za
  // sehemu nyingine za app (AppColors ya jumla haijaguswa).
  static const Color _mentaGreen = Color(0xFF2BA94E);
  static const Color _mentaTeal = Color(0xFF02A593);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120,
                    child: Image.asset(
                      'assets/images/MENTA STUDIO-01 (1).png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'MENTA STUDIO',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _mentaGreen,
                    ),
                  ),
                  const Text(
                    'Mfumo wa Fedha',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ingia kwenye mfumo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Jina la Mtumiaji',
                      hintText: 'Ingiza jina la mtumiaji',
                    ),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Jina la mtumiaji linahitajika'
                                : null,
                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => TextFormField(
                      controller: controller.passwordCtrl,
                      obscureText: controller.obscurePassword.value,
                      decoration: InputDecoration(
                        labelText: 'Nywila',
                        hintText: 'Ingiza nywila',
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                          ),
                          onPressed: controller.toggleObscure,
                        ),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Nywila inahitajika'
                                  : null,
                      onFieldSubmitted: (_) => controller.login(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_mentaGreen, _mentaTeal],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed:
                              controller.isLoading.value
                                  ? null
                                  : controller.login,
                          child:
                              controller.isLoading.value
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('Ingia'),
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () =>
                        controller.errorMessage.value == null
                            ? const SizedBox(height: 8)
                            : Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                controller.errorMessage.value!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
