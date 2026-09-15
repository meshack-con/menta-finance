import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../rulers/models/lookup_option.dart';

class ReportsController extends GetxController {
  final ApiClient _api;
  ReportsController(this._api);

  final isLoadingLookups = true.obs;
  final regions = <LookupOption>[].obs;
  final branches = <LookupOption>[].obs;
  final leaderships = <LookupOption>[].obs;

  // ---- Filters: Wanachama ----
  final membersGender = RxnString();
  final membersRegionId = RxnInt();
  final membersBranchId = RxnInt();
  final membersStatus = RxnString();

  // ---- Filters: Uongozi ----
  final leadershipFilterId = RxnInt();
  final leadershipRegionId = RxnInt();

  // ---- Filters: Elimu ---- ('TextEditingController' halisi - siyo tu
  // 'RxString' - ili "Weka Upya Vichujio" iweze KUONEKANA imefuta fields
  // hizi kwenye skrini, siyo thamani ya ndani tu)
  final educationLevelCtrl = TextEditingController();
  final educationProgramCtrl = TextEditingController();

  // ---- Filters: Ajira ----
  final employmentTypeCtrl = TextEditingController();

  // ---- Filters: Mafunzo ----
  final trainingTypeCtrl = TextEditingController();
  final trainingLocationCtrl = TextEditingController();

  // ---- Filters: Wadau ----
  final stakeholderKind = RxnString();

  // ---- Filters: Usajili kwa Kipindi ----
  final registrationStart = Rxn<DateTime>();
  final registrationEnd = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    _loadLookups();
  }

  @override
  void onClose() {
    for (final c in [educationLevelCtrl, educationProgramCtrl, employmentTypeCtrl, trainingTypeCtrl, trainingLocationCtrl]) {
      c.dispose();
    }
    super.onClose();
  }

  Future<void> _loadLookups() async {
    isLoadingLookups.value = true;
    try {
      final regionsData = await _api.get('/api/regions/', query: {'limit': 500});
      regions.assignAll((regionsData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)));
      final branchesData = await _api.get('/api/branches/', query: {'limit': 500});
      branches.assignAll((branchesData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)));
      final leadershipsData = await _api.get('/api/leaderships/', query: {'limit': 500});
      leaderships.assignAll((leadershipsData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      // si hatari kubwa - filters zitakuwa tupu, ripoti bado zinaweza kutengenezwa bila filters
    } finally {
      isLoadingLookups.value = false;
    }
  }

  Map<String, dynamic> get membersQuery => {
        if (membersGender.value != null) 'gender': membersGender.value,
        if (membersRegionId.value != null) 'region_id': membersRegionId.value,
        if (membersBranchId.value != null) 'branch_id': membersBranchId.value,
        if (membersStatus.value != null) 'membership_status': membersStatus.value,
      };

  Map<String, dynamic> get leadershipQuery => {
        if (leadershipFilterId.value != null) 'leadership_id': leadershipFilterId.value,
        if (leadershipRegionId.value != null) 'region_id': leadershipRegionId.value,
      };

  Map<String, dynamic> get educationQuery => {
        if (educationLevelCtrl.text.trim().isNotEmpty) 'education_level': educationLevelCtrl.text.trim(),
        if (educationProgramCtrl.text.trim().isNotEmpty) 'education_program': educationProgramCtrl.text.trim(),
      };

  Map<String, dynamic> get employmentQuery => {
        if (employmentTypeCtrl.text.trim().isNotEmpty) 'employment_type': employmentTypeCtrl.text.trim(),
      };

  Map<String, dynamic> get trainingQuery => {
        if (trainingTypeCtrl.text.trim().isNotEmpty) 'training_type': trainingTypeCtrl.text.trim(),
        if (trainingLocationCtrl.text.trim().isNotEmpty) 'location': trainingLocationCtrl.text.trim(),
      };

  Map<String, dynamic> get stakeholderQuery => {
        if (stakeholderKind.value != null) 'kind': stakeholderKind.value,
      };

  String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic>? get registrationPeriodQuery {
    if (registrationStart.value == null || registrationEnd.value == null) return null;
    return {'start_date': _isoDate(registrationStart.value!), 'end_date': _isoDate(registrationEnd.value!)};
  }

  // ---- "Weka Upya Vichujio" (Reset) - kwa kila sehemu ya ripoti ----
  void resetMembersFilters() {
    membersGender.value = null;
    membersRegionId.value = null;
    membersBranchId.value = null;
    membersStatus.value = null;
  }

  void resetLeadershipFilters() {
    leadershipFilterId.value = null;
    leadershipRegionId.value = null;
  }

  void resetEducationFilters() {
    educationLevelCtrl.clear();
    educationProgramCtrl.clear();
  }

  void resetEmploymentFilters() {
    employmentTypeCtrl.clear();
  }

  void resetTrainingFilters() {
    trainingTypeCtrl.clear();
    trainingLocationCtrl.clear();
  }

  void resetStakeholderFilters() {
    stakeholderKind.value = null;
  }

  void resetRegistrationPeriodFilters() {
    registrationStart.value = null;
    registrationEnd.value = null;
  }
}
