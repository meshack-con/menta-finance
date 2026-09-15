import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../models/lookup_option.dart';
import '../models/ruler_model.dart';
import '../ruler_service.dart';

class RulerFormController extends GetxController {
  final RulerService _service;
  final int? rulerId; // null = "Ongeza Mpya", si-null = "Hariri"

  RulerFormController(this._service, {this.rulerId});

  final currentStep = 0.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  bool get isEditMode => rulerId != null;

  // ---------- Hatua ya 1: Taarifa Binafsi ----------
  final firstNameCtrl = TextEditingController();
  final middleNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final otherNameCtrl = TextEditingController();
  final genderRx = RxnString();
  final dateOfBirthRx = Rxn<DateTime>();
  final occupationCtrl = TextEditingController();
  final selectedOccupationId = RxnInt(); // Fani
  final selectedOccupationTypeId = RxnInt(); // Aina ya Kazi
  final disabilityInfoCtrl = TextEditingController();
  final selectedMemberRegionId = RxnInt(); // Mkoa (wa mwanachama mwenyewe)

  // ---------- Hatua ya 2: Mawasiliano ----------
  final phoneNumberCtrl = TextEditingController();
  final emailAddressCtrl = TextEditingController();

  // ---------- Hatua ya 3: Vitambulisho ----------
  final identificationTypeRx = RxnString();
  final identificationNumberCtrl = TextEditingController();
  final voterIdCtrl = TextEditingController();

  // ---------- Hatua ya 4: Kadi za Uanachama ----------
  final membershipCodeCtrl = TextEditingController();
  // 'membershipIdCtrl' na 'cardNumberCtrl' ZIMEONDOLEWA KABISA - fields
  // hizi hazihitajiki tena (angalia app/ruler/model.py na migration
  // d4f7e9a21c33_).
  final uwtCardNoCtrl = TextEditingController();
  final uwtCardNoDateRx = Rxn<DateTime>();
  final uvccmCardNoCtrl = TextEditingController();
  final uvccmCardNoDateRx = Rxn<DateTime>();
  final uvccmCardNoPlaceCtrl = TextEditingController();
  final wazaziCardNoCtrl = TextEditingController();
  final wazaziCardNoDateRx = Rxn<DateTime>();
  final wazaziCardNoPlaceCtrl = TextEditingController();

  // ---------- Hatua ya 4: Uongozi (hiari) ----------
  final isLeaderRx = false.obs;
  final selectedLeadershipId = RxnInt();
  final selectedRegionId = RxnInt();
  final positionStartDateRx = Rxn<DateTime>();
  final positionEndDateRx = Rxn<DateTime>();

  final leaderships = <LookupOption>[].obs;
  final regions = <LookupOption>[].obs;
  final branches = <LookupOption>[].obs; // kwa "Taasisi" - Taasisi ndio Tawi
  final occupations = <LookupOption>[].obs;
  final occupationTypes = <LookupOption>[].obs; // Aina ya Kazi
  final selectedInstituteId = RxnInt(); // "Taasisi" - inahifadhi branch_id
  final isLoadingLeadershipData = true.obs;

  /// Matawi yaliyo NDANI ya Mkoa uliochaguliwa (kwa "Taasisi/Chuo (Tawi)").
  List<LookupOption> branchesForRegion(int? regionId) {
    if (regionId == null) return branches;
    return branches.where((b) => b.parentId == regionId).toList();
  }

  static const genderOptions = ['Male', 'Female'];
  static const identificationTypeOptions = ['NIDA', 'Kitambulisho cha Mpigakura', 'Passport', 'Leseni ya Udereva'];

  @override
  void onInit() {
    super.onInit();
    if (isEditMode) _loadForEdit();
    _loadLeadershipData();
  }

  Future<void> _loadLeadershipData() async {
    isLoadingLeadershipData.value = true;
    try {
      leaderships.assignAll(await _service.listLeaderships());
      regions.assignAll(await _service.listRegions());
      branches.assignAll(await _service.listBranches());
      occupations.assignAll(await _service.listOccupations());
      occupationTypes.assignAll(await _service.listOccupationTypes());
    } catch (_) {
      // si hatari kubwa - dropdown itakuwa tupu tu
    } finally {
      isLoadingLeadershipData.value = false;
    }
  }

  Future<void> _loadForEdit() async {
    isLoading.value = true;
    try {
      final r = await _service.get(rulerId!);
      firstNameCtrl.text = r.firstName;
      middleNameCtrl.text = r.middleName ?? '';
      lastNameCtrl.text = r.lastName;
      otherNameCtrl.text = r.otherName ?? '';
      genderRx.value = r.gender;
      dateOfBirthRx.value = r.dateOfBirth;
      occupationCtrl.text = r.occupation ?? '';
      selectedOccupationId.value = r.occupationId;
      selectedOccupationTypeId.value = r.occupationTypeId;
      disabilityInfoCtrl.text = r.disabilityInfo ?? '';
      selectedMemberRegionId.value = r.regionId;
      selectedInstituteId.value = r.instituteId;

      phoneNumberCtrl.text = r.phoneNumber ?? '';
      emailAddressCtrl.text = r.emailAddress ?? '';

      identificationTypeRx.value = r.identificationType;
      identificationNumberCtrl.text = r.identificationNumber ?? '';
      voterIdCtrl.text = r.voterId ?? '';

      membershipCodeCtrl.text = r.membershipCode ?? '';
      uwtCardNoCtrl.text = r.uwtCardNo ?? '';
      uwtCardNoDateRx.value = r.uwtCardNoDateIssued;
      uvccmCardNoCtrl.text = r.uvccmCardNo ?? '';
      uvccmCardNoDateRx.value = r.uvccmCardNoDateIssued;
      uvccmCardNoPlaceCtrl.text = r.uvccmCardNoPlaceIssued ?? '';
      wazaziCardNoCtrl.text = r.wazaziCardNo ?? '';
      wazaziCardNoDateRx.value = r.wazaziCardNoDateIssued;
      wazaziCardNoPlaceCtrl.text = r.wazaziCardNoPlaceIssued ?? '';
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void nextStep() {
    if (currentStep.value < 4) currentStep.value++;
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  Future<void> pickDate(Rxn<DateTime> target, BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: target.value ?? DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) target.value = picked;
  }

  String formatDate(DateTime? d) => d == null ? '' : DateFormat('dd/MM/yyyy').format(d);

  RulerModel _buildModel() {
    return RulerModel(
      membershipCode: membershipCodeCtrl.text.trim().isEmpty ? null : membershipCodeCtrl.text.trim(),
      firstName: firstNameCtrl.text.trim(),
      middleName: middleNameCtrl.text.trim().isEmpty ? null : middleNameCtrl.text.trim(),
      lastName: lastNameCtrl.text.trim(),
      otherName: otherNameCtrl.text.trim().isEmpty ? null : otherNameCtrl.text.trim(),
      gender: genderRx.value,
      dateOfBirth: dateOfBirthRx.value,
      phoneNumber: phoneNumberCtrl.text.trim().isEmpty ? null : phoneNumberCtrl.text.trim(),
      disabilityInfo: disabilityInfoCtrl.text.trim().isEmpty ? null : disabilityInfoCtrl.text.trim(),
      identificationType: identificationTypeRx.value,
      emailAddress: emailAddressCtrl.text.trim().isEmpty ? null : emailAddressCtrl.text.trim(),
      identificationNumber:
          identificationNumberCtrl.text.trim().isEmpty ? null : identificationNumberCtrl.text.trim(),
      voterId: voterIdCtrl.text.trim().isEmpty ? null : voterIdCtrl.text.trim(),
      occupation: occupationCtrl.text.trim().isEmpty ? null : occupationCtrl.text.trim(),
      occupationId: selectedOccupationId.value,
      occupationTypeId: selectedOccupationTypeId.value,
      regionId: selectedMemberRegionId.value,
      instituteId: selectedInstituteId.value,
      uwtCardNo: uwtCardNoCtrl.text.trim().isEmpty ? null : uwtCardNoCtrl.text.trim(),
      uwtCardNoDateIssued: uwtCardNoDateRx.value,
      uvccmCardNo: uvccmCardNoCtrl.text.trim().isEmpty ? null : uvccmCardNoCtrl.text.trim(),
      uvccmCardNoDateIssued: uvccmCardNoDateRx.value,
      uvccmCardNoPlaceIssued: uvccmCardNoPlaceCtrl.text.trim().isEmpty ? null : uvccmCardNoPlaceCtrl.text.trim(),
      wazaziCardNo: wazaziCardNoCtrl.text.trim().isEmpty ? null : wazaziCardNoCtrl.text.trim(),
      wazaziCardNoDateIssued: wazaziCardNoDateRx.value,
      wazaziCardNoPlaceIssued: wazaziCardNoPlaceCtrl.text.trim().isEmpty ? null : wazaziCardNoPlaceCtrl.text.trim(),
    );
  }

  /// Kama Ruler mpya ameundwa na akapewa password ya awali kiotomatiki
  /// (jina la mwisho, herufi ya kwanza kubwa), inahifadhiwa hapa kwa muda
  /// (mara moja tu) ili dialog iweze kumwonyesha Admin baada ya kuhifadhi.
  final createdDefaultPassword = RxnString();
  String? createdMembershipCode;

  /// CCM API ilishindikana kufikiwa (503) kwenye jaribio la mwisho -
  /// Admin anaonyeshwa chaguo la "kupitisha" (override) uthibitisho.
  final ccmUnavailable = false.obs;
  final overrideCcm = false.obs;

  /// Muundo unaotakiwa: C0000-0000-000-1 (sawa na inavyothibitishwa na
  /// backend/CCM API) - tunakagua hapa mapema ili Admin apate ujumbe papo
  /// hapo badala ya kusubiri jibu la mtandao.
  static final RegExp membershipCodePattern = RegExp(r'^C\d{4}-\d{4}-\d{3}-\d$');

  /// Inarudisha true kama imefanikiwa kuhifadhi (dialog inayoita hii
  /// ndiyo itakayoamua kufunga - Get.back() - siyo controller hii.
  Future<bool> submit() async {
    if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) {
      Get.snackbar('Taarifa Hazijakamilika', 'Jina la kwanza na la mwisho ni lazima.',
          snackPosition: SnackPosition.BOTTOM);
      currentStep.value = 0;
      return false;
    }
    // Membership Code (CCM) sasa NI HIARI - inakaguliwa TU kama Admin
    // ameijaza (siyo tena lazima kuwepo).
    if (membershipCodeCtrl.text.trim().isNotEmpty && !membershipCodePattern.hasMatch(membershipCodeCtrl.text.trim())) {
      Get.snackbar('Kosa', 'Membership Code si sahihi. Muundo unaotakiwa: C0000-0000-000-1',
          snackPosition: SnackPosition.BOTTOM);
      currentStep.value = 3;
      return false;
    }

    isSaving.value = true;
    errorMessage.value = null;
    ccmUnavailable.value = false;
    try {
      final model = _buildModel();
      int savedRulerId;
      if (isEditMode) {
        final updated = await _service.update(rulerId!, model);
        savedRulerId = rulerId!;
        // Kama huyu Member hakuwa na password bado (mfano aliongezwa kabla
        // ya sifa hii, au alikuwa hana last_name wakati ule), backend
        // inamtengenezea password ya default HAPA PIA - tulikuwa
        // tunaipuuza kimakosa (ndiyo sababu ya mkanganyiko "hatengenezewi
        // akaunti"). Sasa tunaithibitisha na kuionyesha kama create mpya.
        if (updated.defaultPassword != null) {
          createdDefaultPassword.value = updated.defaultPassword;
          createdMembershipCode = updated.membershipCode;
        } else {
          Get.snackbar('Imefanikiwa', 'Taarifa za mwanachama zimesasishwa.', snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        final created = await _service.create(model, overrideCcm: overrideCcm.value);
        savedRulerId = created.id!;
        if (created.defaultPassword != null) {
          createdDefaultPassword.value = created.defaultPassword;
          createdMembershipCode = created.membershipCode;
        } else {
          Get.snackbar('Imefanikiwa', 'Mwanachama mpya ameongezwa.', snackPosition: SnackPosition.BOTTOM);
        }
      }

      // Kama Admin ame-tick "Huyu ni Kiongozi" na akachagua Nafasi + Mkoa,
      // ongeza RulerPosition (itathibitishwa moja kwa moja - angalia backend).
      if (isLeaderRx.value && selectedLeadershipId.value != null && selectedRegionId.value != null) {
        try {
          await _service.addPosition(
            rulerId: savedRulerId,
            leadershipId: selectedLeadershipId.value!,
            regionId: selectedRegionId.value!,
            startDate: positionStartDateRx.value,
            endDate: positionEndDateRx.value,
          );
        } on ApiException catch (e) {
          Get.snackbar('Onyo', 'Mwanachama amehifadhiwa, lakini nafasi ya uongozi imeshindikana: ${e.message}',
              snackPosition: SnackPosition.BOTTOM);
        }
      }
      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      if (e.statusCode == 503) {
        // CCM API haifikiki - onyesha chaguo la "kupitisha" badala ya
        // ujumbe wa jumla tu (Admin anaweza kuchagua kuendelea kwa dharura).
        ccmUnavailable.value = true;
        currentStep.value = 3; // hatua ya "Kadi za Uanachama" - ndipo onyo linaonekana
        Get.snackbar(
          'CCM API Haifikiki',
          'Huwezi kuunganishwa na mfumo wa CCM kwa sasa. Unaweza "kupitisha" uthibitisho kwa dharura (chini ya fomu).',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 6),
        );
      } else {
        Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      }
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in [
      firstNameCtrl, middleNameCtrl, lastNameCtrl, otherNameCtrl, occupationCtrl,
      disabilityInfoCtrl, phoneNumberCtrl, emailAddressCtrl, identificationNumberCtrl, voterIdCtrl,
      membershipCodeCtrl, uwtCardNoCtrl, uvccmCardNoCtrl,
      uvccmCardNoPlaceCtrl, wazaziCardNoCtrl, wazaziCardNoPlaceCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}
