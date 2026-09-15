import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../controllers/ruler_form_controller.dart';
import '../models/lookup_option.dart';
import '../ruler_service.dart';

/// Fomu ya "Ongeza/Hariri Mwanachama" - inaonekana kama DIALOG (modal) juu
/// ya ukurasa wa Orodha ya Wanachama, badala ya kufungua ukurasa mpya kabisa.
/// Matumizi: `Get.dialog<bool>(RulerFormDialog(rulerId: r.id))`
/// Inarudisha `true` kama imefanikiwa kuhifadhi (kiashiria cha ku-refresh orodha).
class RulerFormDialog extends StatefulWidget {
  final int? rulerId;
  const RulerFormDialog({super.key, this.rulerId});

  @override
  State<RulerFormDialog> createState() => _RulerFormDialogState();
}

class _RulerFormDialogState extends State<RulerFormDialog> {
  late final RulerFormController controller;

  static const _stepTitles = ['Taarifa Binafsi', 'Mawasiliano', 'Vitambulisho', 'Kadi za Uanachama', 'Uongozi'];

  @override
  void initState() {
    super.initState();
    // Hatuitumii GetX routing/binding hapa (ni dialog, si route) - tunaunda
    // controller moja kwa moja na kuita onInit() wenyewe (kama Get.put ingefanya).
    final service = RulerService(Get.find<ApiClient>());
    controller = RulerFormController(service, rulerId: widget.rulerId);
    controller.onInit();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  Future<void> _showAccountCreatedDialog(String? membershipCode, String defaultPassword) {
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
            _CredentialRow(label: 'Username (Membership No)', value: membershipCode ?? '-'),
            const SizedBox(height: 8),
            _CredentialRow(label: 'Password ya Awali', value: defaultPassword),
            const SizedBox(height: 14),
            const Text(
              'Mwambie abadilishe password baada ya kuingia mara ya kwanza.',
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxWidth = screenSize.width < 900 ? screenSize.width * 0.95 : 850.0;
    final maxHeight = screenSize.height * 0.88;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            if (controller.isLoading.value) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.isEditMode ? 'Hariri Mwanachama' : 'Ongeza Mwanachama Mpya',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 6),
                _StepHeader(current: controller.currentStep.value, titles: _stepTitles),
                const SizedBox(height: 18),
                Flexible(
                  child: SingleChildScrollView(child: _buildStepContent(context)),
                ),
                const SizedBox(height: 14),
                if (controller.errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: controller.currentStep.value == 0 ? () => Get.back() : controller.previousStep,
                      child: Text(controller.currentStep.value == 0 ? 'Ghairi' : 'Nyuma'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                              if (controller.currentStep.value == 4) {
                                final ok = await controller.submit();
                                if (ok) {
                                  if (controller.createdDefaultPassword.value != null) {
                                    await _showAccountCreatedDialog(
                                      controller.createdMembershipCode,
                                      controller.createdDefaultPassword.value!,
                                    );
                                  }
                                  Get.back(result: true);
                                }
                              } else {
                                controller.nextStep();
                              }
                            },
                      child: controller.isSaving.value
                          ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(controller.currentStep.value == 4 ? 'Hifadhi Mwanachama' : 'Endelea'),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (controller.currentStep.value) {
      case 0:
        return _StepPersonalInfo(controller: controller);
      case 1:
        return _StepContact(controller: controller);
      case 2:
        return _StepIdentification(controller: controller);
      case 3:
        return _StepMembershipCards(controller: controller);
      case 4:
      default:
        return _StepLeadership(controller: controller);
    }
  }
}

class _StepHeader extends StatelessWidget {
  final int current;
  final List<String> titles;
  const _StepHeader({required this.current, required this.titles});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(titles.length, (i) {
        final active = i == current;
        final done = i < current;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: (active || done) ? AppColors.primaryGreen : AppColors.border,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(color: (active || done) ? Colors.white : AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  titles[i],
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                    color: active ? AppColors.primaryGreen : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (i != titles.length - 1)
                Expanded(child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 6), color: AppColors.border)),
            ],
          ),
        );
      }),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            tooltip: 'Nakili',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Get.snackbar('Imenakiliwa', '"$value" imenakiliwa.', snackPosition: SnackPosition.BOTTOM);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- Helpers za fields (kupunguza urudufu) ----------------

Widget _field(String label, Widget input, {bool required = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), children: [
            if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
          ]),
        ),
        const SizedBox(height: 6),
        input,
      ],
    ),
  );
}

Widget _text(TextEditingController c, {String? hint}) => TextField(controller: c, decoration: InputDecoration(hintText: hint));

Widget _dropdown(RxnString rx, List<String> options, {String? hint}) {
  return Obx(() {
    // Ulinzi #1: ondoa nakala (duplicates) - chaguo mbili zenye jina lile
    // lile kwenye 'options' pia zinavunja DropdownButtonFormField ("2 or
    // more matches").
    final deduped = options.toSet().toList();
    // Ulinzi #2: ikiwa thamani iliyohifadhiwa (rx.value) HAIPO tena kwenye
    // orodha ya sasa (mfano Aina ya Kazi ilifutwa/kubadilishwa baada ya
    // Mwanachama huyu kuwekewa thamani hiyo), DropdownButtonFormField
    // INAVUNJIKA ("zero matches"). Suluhisho: ongeza thamani hiyo YENYEWE
    // kwenye orodha (ikiwa haipo), ili iendelee kuonekana bila kuvunja
    // fomu - data ya Mwanachama haipotei, Admin bado anaweza kuibadilisha.
    final effectiveOptions = (rx.value != null && !deduped.contains(rx.value)) ? [rx.value!, ...deduped] : deduped;
    return DropdownButtonFormField<String>(
      value: rx.value,
      hint: Text(hint ?? 'Chagua'),
      items: effectiveOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: (v) => rx.value = v,
    );
  });
}

LookupOption? _findById(List<LookupOption> options, int? id) {
  if (id == null) return null;
  for (final o in options) {
    if (o.id == id) return o;
  }
  return null;
}

/// Dropdown maalum ya Jinsia - thamani zinazohifadhiwa (data) zinabaki
/// 'Male'/'Female' (kwa uoanifu na ripoti/data ya zamani), lakini
/// zinaonyeshwa kwa Kiswahili ('Mme'/'Mke') kwenye fomu.
String _genderLabel(String value) => value == 'Male' ? 'Mme' : (value == 'Female' ? 'Mke' : value);

Widget _genderDropdown(RxnString rx, {String? hint}) {
  return Obx(() {
    final deduped = RulerFormController.genderOptions.toSet().toList();
    final effectiveOptions = (rx.value != null && !deduped.contains(rx.value)) ? [rx.value!, ...deduped] : deduped;
    return DropdownButtonFormField<String>(
      value: rx.value,
      hint: Text(hint ?? 'Chagua'),
      items: effectiveOptions.map((o) => DropdownMenuItem(value: o, child: Text(_genderLabel(o)))).toList(),
      onChanged: (v) => rx.value = v,
    );
  });
}

Widget _dateField(BuildContext context, RulerFormController controller, Rxn<DateTime> rx, {String hint = 'dd/mm/yyyy'}) {
  return Obx(
    () => TextField(
      readOnly: true,
      controller: TextEditingController(text: controller.formatDate(rx.value)),
      decoration: InputDecoration(hintText: hint, suffixIcon: const Icon(Icons.calendar_today, size: 18)),
      onTap: () => controller.pickDate(rx, context),
    ),
  );
}

Widget _row2(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)],
    );

Widget _row3(Widget a, Widget b, Widget c) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 16),
        Expanded(child: b),
        const SizedBox(width: 16),
        Expanded(child: c),
      ],
    );

// ---------------- Hatua ya 1: Taarifa Binafsi ----------------

class _StepPersonalInfo extends StatelessWidget {
  final RulerFormController controller;
  const _StepPersonalInfo({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row3(
          _field('Jina la Kwanza', _text(controller.firstNameCtrl, hint: 'Ingiza jina la kwanza'), required: true),
          _field('Jina la Kati', _text(controller.middleNameCtrl, hint: 'Ingiza jina la kati')),
          _field('Jina la Mwisho', _text(controller.lastNameCtrl, hint: 'Ingiza jina la mwisho'), required: true),
        ),
        _row2(
          _field('Jina Lingine', _text(controller.otherNameCtrl, hint: 'Ingiza jina lingine')),
          _field('Jinsia', _genderDropdown(controller.genderRx, hint: 'Chagua jinsia'), required: true),
        ),
        _row2(
          _field('Tarehe ya Kuzaliwa', _dateField(context, controller, controller.dateOfBirthRx), required: true),
          _field(
            'Fani',
            Obx(
              () => SearchableDropdown(
                label: 'Fani',
                options: controller.occupations,
                value: controller.selectedOccupationId.value,
                onChanged: (id) {
                  controller.selectedOccupationId.value = id;
                  final match = _findById(controller.occupations, id);
                  controller.occupationCtrl.text = match?.name ?? '';
                },
                hint: 'Tafuta na uchague Fani...',
              ),
            ),
          ),
        ),
        _row2(
          _field(
            'Aina ya Kazi',
            Obx(
              () => SearchableDropdown(
                label: 'Aina ya Kazi',
                options: controller.occupationTypes,
                value: controller.selectedOccupationTypeId.value,
                onChanged: (id) => controller.selectedOccupationTypeId.value = id,
                hint: 'Tafuta na uchague Aina ya Kazi...',
              ),
            ),
          ),
          _field('Taarifa za Ulemavu (kama zipo)', _text(controller.disabilityInfoCtrl, hint: 'Eleza aina ya ulemavu')),
        ),
        _row2(
          _field(
            'Mkoa',
            Obx(
              () => SearchableDropdown(
                label: 'Mkoa',
                options: controller.regions,
                value: controller.selectedMemberRegionId.value,
                onChanged: (id) {
                  controller.selectedMemberRegionId.value = id;
                  controller.selectedInstituteId.value = null; // mkoa ukibadilika, tawi linaanza upya
                },
                hint: 'Tafuta na uchague mkoa...',
              ),
            ),
          ),
          _field(
            'Taasisi/Chuo (Tawi)',
            Obx(
              () => SearchableDropdown(
                label: 'Taasisi/Chuo',
                options: controller.branchesForRegion(controller.selectedMemberRegionId.value),
                value: controller.selectedInstituteId.value,
                onChanged: (id) => controller.selectedInstituteId.value = id,
                hint: controller.selectedMemberRegionId.value == null
                    ? 'Chagua mkoa kwanza (au tafuta moja kwa moja)'
                    : 'Tafuta taasisi/chuo (tawi)...',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Hatua ya 2: Mawasiliano ----------------

class _StepContact extends StatelessWidget {
  final RulerFormController controller;
  const _StepContact({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row2(
          _field(
            'Namba ya Simu',
            TextField(
              controller: controller.phoneNumberCtrl,
              enabled: !controller.isEditMode,
              decoration: InputDecoration(
                hintText: '07XXXXXXXX',
                helperText: controller.isEditMode ? 'Haiwezi kubadilishwa (ni Username ya kuingia)' : null,
              ),
            ),
            required: true,
          ),
          _field('Barua Pepe', _text(controller.emailAddressCtrl, hint: 'mfano@example.com')),
        ),
      ],
    );
  }
}

// ---------------- Hatua ya 3: Vitambulisho ----------------

class _StepIdentification extends StatelessWidget {
  final RulerFormController controller;
  const _StepIdentification({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row2(
          _field('Aina ya Kitambulisho',
              _dropdown(controller.identificationTypeRx, RulerFormController.identificationTypeOptions)),
          _field('Namba ya Kitambulisho', _text(controller.identificationNumberCtrl)),
        ),
        _field('Voter ID', _text(controller.voterIdCtrl)),
      ],
    );
  }
}

// ---------------- Hatua ya 4: Kadi za Uanachama ----------------

class _StepMembershipCards extends StatelessWidget {
  final RulerFormController controller;
  const _StepMembershipCards({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field('Namba ya Uwanachama wa CCM (Hiari)', _text(controller.membershipCodeCtrl, hint: 'Mfano: C0000-0000-000-1')),
        Obx(() {
          if (!controller.ccmUnavailable.value) return const SizedBox();
          return Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('Mfumo wa CCM haufikiki kwa sasa.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                ]),
                const SizedBox(height: 8),
                Obx(
                  () => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: controller.overrideCcm.value,
                    onChanged: (v) => controller.overrideCcm.value = v ?? false,
                    title: const Text(
                      'Pitisha uthibitisho wa CCM kwa DHARURA (nitawajibika mimi Admin) - hii itaandikwa kwenye Audit Trail.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 24),
        _row2(
          _field('UWT Card No', _text(controller.uwtCardNoCtrl)),
          _field('Tarehe ya UWT Card', _dateField(context, controller, controller.uwtCardNoDateRx)),
        ),
        _row3(
          _field('UVCCM Card No', _text(controller.uvccmCardNoCtrl)),
          _field('Tarehe ya UVCCM Card', _dateField(context, controller, controller.uvccmCardNoDateRx)),
          _field('Mahali Ilipotolewa', _text(controller.uvccmCardNoPlaceCtrl)),
        ),
        _row3(
          _field('Wazazi Card No', _text(controller.wazaziCardNoCtrl)),
          _field('Tarehe ya Wazazi Card', _dateField(context, controller, controller.wazaziCardNoDateRx)),
          _field('Mahali Ilipotolewa', _text(controller.wazaziCardNoPlaceCtrl)),
        ),
      ],
    );
  }
}

// ---------------- Hatua ya 4: Uongozi (hiari) ----------------

class _StepLeadership extends StatelessWidget {
  final RulerFormController controller;
  const _StepLeadership({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kama unajua tayari kwamba mwanachama huyu ni/alikuwa kiongozi, '
          'unaweza kumwekea nafasi yake hapa. Nafasi zinazoongezwa na Admin '
          'zinathibitishwa (verified) MOJA KWA MOJA.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 16),
        Obx(
          () => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: controller.isLeaderRx.value,
            onChanged: (v) => controller.isLeaderRx.value = v ?? false,
            title: const Text('Huyu ni Kiongozi', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        Obx(() {
          if (!controller.isLeaderRx.value) return const SizedBox();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _row2(
                _field(
                  'Nafasi ya Uongozi',
                  Obx(
                    () => DropdownButtonFormField<int>(
                      value: controller.selectedLeadershipId.value,
                      hint: Text(controller.isLoadingLeadershipData.value ? 'Inapakia...' : 'Chagua nafasi'),
                      items: controller.leaderships.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                      onChanged: (v) => controller.selectedLeadershipId.value = v,
                    ),
                  ),
                  required: true,
                ),
                _field(
                  'Mkoa',
                  Obx(
                    () => SearchableDropdown(
                      label: 'Mkoa',
                      options: controller.regions,
                      value: controller.selectedRegionId.value,
                      onChanged: (v) => controller.selectedRegionId.value = v,
                    ),
                  ),
                  required: true,
                ),
              ),
              _row2(
                _field('Tarehe ya Kuanza', _dateField(context, controller, controller.positionStartDateRx)),
                _field('Tarehe ya Mwisho (kama ipo)', _dateField(context, controller, controller.positionEndDateRx)),
              ),
            ],
          );
        }),
      ],
    );
  }
}
