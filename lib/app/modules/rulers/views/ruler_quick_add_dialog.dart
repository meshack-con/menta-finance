import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../controllers/ruler_quick_add_controller.dart';
import '../ruler_service.dart';

/// "Ongeza Mwanachama Mpya" - fomu FUPI (siyo hatua 6 kama 'RulerFormDialog')
/// yenye fields ZILE ZILE za usajili wa mwanachama mwenyewe (mobile):
/// Jina la Kwanza/Kati/Mwisho, Barua Pepe, Namba ya Simu. Mkoa, Tawi,
/// Fani, Aina ya Kazi, na Namba ya Uwanachama wa CCM (hiari) HAZIOMBWI
/// hapa - mwanachama ataziongeza mwenyewe kwenye Profile yake baadaye
/// (au Admin anaweza kuzikamilisha kupitia "Hariri" kwenye orodha ya
/// Wanachama), kuepuka kurudia taarifa hizo hizo mahali pawili.
///
/// Matumizi: `Get.dialog<bool>(const RulerQuickAddDialog())`
/// Inarudisha `true` kama imefanikiwa kuhifadhi.
class RulerQuickAddDialog extends StatefulWidget {
  const RulerQuickAddDialog({super.key});

  @override
  State<RulerQuickAddDialog> createState() => _RulerQuickAddDialogState();
}

class _RulerQuickAddDialogState extends State<RulerQuickAddDialog> {
  late final RulerQuickAddController controller;

  @override
  void initState() {
    super.initState();
    final service = RulerService(Get.find<ApiClient>());
    controller = RulerQuickAddController(service);
    // MUHIMU: 'RulerQuickAddController' HAIKUWA imesajiliwa kupitia
    // Get.put()/Get.lazyPut() - ambayo ndiyo NJIA PEKEE GetX inayoita
    // 'onInit()' KIOTOMATIKO. Kwa kuitengeneza moja kwa moja (kama
    // hapo juu), 'onInit()' (na hivyo '_loadLookups()' - Mikoa/Matawi)
    // ilikuwa HAIJAWAHI kuitwa KABISA - hii ndiyo ilikuwa sababu HALISI
    // ya Mkoa/Tawi kutokuja (kwa kila mtumiaji, siyo kwa Msajili tu).
    // Kuiita wazi hapa kunahakikisha inaanza kupakia data mara moja.
    controller.onInit();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  Future<void> _showAccountCreatedDialog(String phoneNumber, String defaultPassword) {
    return Get.dialog(
      AlertDialog(
        title: const Text('Akaunti ya Mwanachama Imeundwa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mwanachama sasa anaweza ku-login kwenye simu (Mobile App) kwa taarifa hizi:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            _CredentialRow(label: 'Username (Namba ya Simu)', value: phoneNumber),
            const SizedBox(height: 8),
            _CredentialRow(label: 'Password ya Awali', value: defaultPassword),
            const SizedBox(height: 14),
            const Text(
              'Mwambie abadilishe password baada ya kuingia mara ya kwanza, na akamilishe '
              'Profile yake (Fani, Namba ya CCM, n.k.) ndani ya app.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Get.back(), child: const Text('Sawa, Nimeelewa')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _label(String text, {bool required = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text.rich(TextSpan(text: text, style: const TextStyle(fontWeight: FontWeight.w600), children: [
          if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
        ])),
      );

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxWidth = screenSize.width < 700 ? screenSize.width * 0.95 : 480.0;
    final maxHeight = screenSize.height * 0.85;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Ongeza Mwanachama Mpya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back(result: false)),
                  ],
                ),
                const Text(
                  'Baada ya kuhifadhi, Username ya mwanachama itakuwa Namba yake ya Simu, na '
                  'Password ya awali itakuwa Jina lake la Mwisho kwa herufi kubwa. Taarifa nyingine '
                  '(Fani, Aina ya Kazi, Namba ya CCM, elimu, uzoefu wa kazi, n.k.) ataziongeza mwenyewe baadaye.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Jina la Kwanza', required: true),
                        TextField(controller: controller.firstNameCtrl, decoration: const InputDecoration(hintText: 'Ingiza jina la kwanza')),

                        _label('Jina la Kati'),
                        TextField(controller: controller.middleNameCtrl, decoration: const InputDecoration(hintText: 'Ingiza jina la kati')),

                        _label('Jina la Mwisho', required: true),
                        TextField(controller: controller.lastNameCtrl, decoration: const InputDecoration(hintText: 'Ingiza jina la mwisho')),

                        _label('Jinsia', required: true),
                        DropdownButtonFormField<String>(
                          value: controller.genderRx.value,
                          hint: const Text('Chagua jinsia'),
                          items: const [
                            DropdownMenuItem(value: 'Male', child: Text('Mme')),
                            DropdownMenuItem(value: 'Female', child: Text('Mke')),
                          ],
                          onChanged: (v) => controller.genderRx.value = v,
                        ),

                        _label('Barua Pepe', required: true),
                        TextField(controller: controller.emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'mfano@example.com')),

                        _label('Namba ya Simu', required: true),
                        TextField(controller: controller.phoneNumberCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '07XXXXXXXX')),

                        _label('Mkoa', required: true),
                        SearchableDropdown(
                          label: 'Mkoa',
                          options: controller.regions,
                          value: controller.selectedRegionId.value,
                          onChanged: (id) {
                            controller.selectedRegionId.value = id;
                            controller.selectedInstituteId.value = null; // mkoa ukibadilika, tawi linaanza upya
                          },
                          hint: controller.isLoadingLookups.value ? 'Inapakia...' : 'Tafuta na uchague mkoa...',
                        ),

                        _label('Tawi', required: true),
                        SearchableDropdown(
                          label: 'Tawi',
                          options: controller.branchesForRegion(controller.selectedRegionId.value),
                          value: controller.selectedInstituteId.value,
                          onChanged: (id) => controller.selectedInstituteId.value = id,
                          hint: controller.isLoadingLookups.value
                              ? 'Inapakia...'
                              : (controller.selectedRegionId.value == null ? 'Chagua mkoa kwanza (au tafuta moja kwa moja)' : 'Tafuta na uchague tawi...'),
                        ),

                        if (controller.errorMessage.value != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(8)),
                            child: Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Get.back(result: false), child: const Text('Ghairi')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                              final ok = await controller.submit();
                              if (ok) {
                                if (controller.createdDefaultPassword.value != null && controller.createdPhoneNumber != null) {
                                  await _showAccountCreatedDialog(controller.createdPhoneNumber!, controller.createdDefaultPassword.value!);
                                }
                                Get.back(result: true);
                              }
                            },
                      child: controller.isSaving.value
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Hifadhi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  const _CredentialRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
        ],
      ),
    );
  }
}
