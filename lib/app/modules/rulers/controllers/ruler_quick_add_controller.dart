import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../models/lookup_option.dart';
import '../models/ruler_model.dart';
import '../ruler_service.dart';

/// Usajili WA HARAKA wa Mwanachama mpya na Admin - fields: Jina la
/// Kwanza, Jina la Kati (hiari), Jina la Mwisho, Jinsia, Barua Pepe,
/// Namba ya Simu, Mkoa, Tawi (sawa na usajili wa mwanachama mwenyewe -
/// mobile self registration). Fani, Aina ya Kazi, na Namba ya
/// Uwanachama wa CCM (hiari) HAZIOMBWI hapa - mwanachama ataziongeza
/// MWENYEWE baadaye kwenye Profile yake (au Admin anaweza kuzikamilisha
/// kupitia "Hariri" baadaye), kuepuka kurudia taarifa hizo hizo mahali
/// pawili (duplication).
class RulerQuickAddController extends GetxController {
  final RulerService _service;
  RulerQuickAddController(this._service);

  final isSaving = false.obs;
  final isLoadingLookups = true.obs;
  final errorMessage = RxnString();

  final regions = <LookupOption>[].obs; // Mkoa
  final branches = <LookupOption>[].obs; // Tawi

  final firstNameCtrl = TextEditingController();
  final middleNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneNumberCtrl = TextEditingController();

  final genderRx = RxnString();
  final selectedRegionId = RxnInt();
  final selectedInstituteId = RxnInt(); // Tawi

  /// Kama Ruler mpya ameundwa na akapewa password ya awali kiotomatiki,
  /// inahifadhiwa hapa kwa muda (mara moja tu) ili dialog iweze kumwonyesha
  /// Admin baada ya kuhifadhi.
  final createdDefaultPassword = RxnString();
  String? createdPhoneNumber;

  @override
  void onInit() {
    super.onInit();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    isLoadingLookups.value = true;
    try {
      regions.assignAll(await _service.listRegions());
      branches.assignAll(await _service.listBranches());
    } on ApiException catch (e) {
      // NB: HATUFICHI hitilafu tena (kimya) - kama Mkoa/Tawi haziji,
      // hii itamwonyesha Admin/Msajili SABABU HALISI (mfano "Huna
      // ruhusa" badala ya kuonekana "hakuna chaguo" bila maelezo).
      Get.snackbar('Imeshindikana Kupakia Mikoa/Matawi', e.message, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 6));
    } catch (_) {
      // si hatari kubwa - dropdown itakuwa tupu tu, Admin anaweza jaribu tena
    } finally {
      isLoadingLookups.value = false;
    }
  }

  /// Matawi yaliyo NDANI ya Mkoa uliochaguliwa.
  List<LookupOption> branchesForRegion(int? regionId) {
    if (regionId == null) return branches;
    return branches.where((b) => b.parentId == regionId).toList();
  }

  bool _validate() {
    if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) {
      Get.snackbar('Taarifa Hazijakamilika', 'Jina la Kwanza na Jina la Mwisho ni lazima.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (genderRx.value == null) {
      Get.snackbar('Taarifa Hazijakamilika', 'Chagua Jinsia.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (phoneNumberCtrl.text.trim().isEmpty) {
      Get.snackbar('Taarifa Hazijakamilika', 'Namba ya Simu ni lazima.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (emailCtrl.text.trim().isEmpty) {
      Get.snackbar('Taarifa Hazijakamilika', 'Barua Pepe ni lazima.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (selectedRegionId.value == null) {
      Get.snackbar('Taarifa Hazijakamilika', 'Chagua Mkoa.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (selectedInstituteId.value == null) {
      Get.snackbar('Taarifa Hazijakamilika', 'Chagua Tawi.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    return true;
  }

  /// Inarudisha true kama imefanikiwa kuhifadhi.
  Future<bool> submit() async {
    if (!_validate()) return false;

    isSaving.value = true;
    errorMessage.value = null;
    try {
      final phone = phoneNumberCtrl.text.trim();
      final model = RulerModel(
        firstName: firstNameCtrl.text.trim(),
        middleName: middleNameCtrl.text.trim().isEmpty ? null : middleNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        gender: genderRx.value,
        emailAddress: emailCtrl.text.trim(),
        phoneNumber: phone,
        regionId: selectedRegionId.value,
        instituteId: selectedInstituteId.value,
      );

      final created = await _service.create(model);
      if (created.defaultPassword != null) {
        createdDefaultPassword.value = created.defaultPassword;
        createdPhoneNumber = phone;
      } else {
        Get.snackbar('Imefanikiwa', 'Mwanachama mpya ameongezwa.', snackPosition: SnackPosition.BOTTOM);
      }
      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      errorMessage.value = 'Hitilafu isiyotarajiwa.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in [firstNameCtrl, middleNameCtrl, lastNameCtrl, emailCtrl, phoneNumberCtrl]) {
      c.dispose();
    }
    super.onClose();
  }
}
