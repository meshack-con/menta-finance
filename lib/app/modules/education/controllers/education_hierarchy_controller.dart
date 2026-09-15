import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../rulers/models/lookup_option.dart';
import '../models/education_level_model.dart';
import '../models/education_program_model.dart';

/// Inasimamia mnyororo mzima: Mkoa -> Tawi -> Ngazi ya Elimu -> Programu.
/// Moduli MOJA inayosimamia Ngazi za Elimu NA Programu za Elimu, kwa
/// sababu zote mbili zinahitaji orodha ileile ya Mikoa/Matawi kwa
/// dropdown za "kuchuja" (cascading).
class EducationHierarchyController extends GetxController {
  final ApiClient _api;
  EducationHierarchyController(this._api);

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  final regions = <LookupOption>[].obs;
  final branches = <LookupOption>[].obs; // na region_id (parentId hatuihitaji hapa - tunachuja kwa jina la mzazi tu)
  final branchRegionOf = <int, int>{}.obs; // branch_id -> region_id (kwa kuchuja)
  final levels = <EducationLevelModel>[].obs;
  final programs = <EducationProgramModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final regionsData = await _api.get('/api/regions/', query: {'limit': 500});
      regions.assignAll((regionsData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)));

      final branchesData = await _api.get('/api/branches/', query: {'limit': 500});
      final branchList = (branchesData as List).cast<Map<String, dynamic>>();
      branches.assignAll(branchList.map((e) => LookupOption.fromJson(e)));
      branchRegionOf.assignAll({for (final b in branchList) (b['id'] as int): b['region_id'] as int? ?? -1});

      final levelsData = await _api.get('/api/education-levels/', query: {'limit': 500});
      levels.assignAll((levelsData as List).map((e) => EducationLevelModel.fromJson(e as Map<String, dynamic>)));

      final programsData = await _api.get('/api/education-programs/', query: {'limit': 500});
      programs.assignAll((programsData as List).map((e) => EducationProgramModel.fromJson(e as Map<String, dynamic>)));
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia.';
    } finally {
      isLoading.value = false;
    }
  }

  String regionName(int? id) => _find(regions, id);
  String branchName(int? id) => _find(branches, id);
  String levelName(int? id) {
    for (final l in levels) {
      if (l.id == id) return l.name;
    }
    return '-';
  }

  String _find(List<LookupOption> options, int? id) {
    if (id == null) return '-';
    for (final o in options) {
      if (o.id == id) return o.name;
    }
    return '-';
  }

  /// Matawi yaliyo ndani ya Mkoa uliochaguliwa.
  List<LookupOption> branchesForRegion(int? regionId) {
    if (regionId == null) return branches;
    return branches.where((b) => branchRegionOf[b.id] == regionId).toList();
  }

  /// Ngazi za Elimu zilizo ndani ya Tawi uliochaguliwa.
  List<EducationLevelModel> levelsForBranch(int? branchId) {
    if (branchId == null) return levels;
    return levels.where((l) => l.branchId == branchId).toList();
  }

  /// Mkoa wa Ngazi ya Elimu fulani (kupitia Tawi lake) - kwa ajili ya
  /// kuonyesha column ya "Mkoa" kwenye jedwali.
  /// NB: 'branchId' inaweza kuwa null (data za zamani kabla ya Tawi kuwa
  /// lazima) - LAZIMA ikaguliwe kabla ya kuitumia kama 'key' ya branchRegionOf,
  /// vinginevyo 'RxMap<int,int>[null]' inatupa "type 'Null' is not a
  /// subtype of type 'int'" (ndiyo hitilafu iliyoonekana kwenye picha).
  int? regionOfLevel(EducationLevelModel level) {
    if (level.branchId == null) return null;
    return branchRegionOf[level.branchId!];
  }

  int? regionOfProgram(EducationProgramModel program) {
    final level = levels.firstWhereOrNullLocal((l) => l.id == program.educationLevelId);
    if (level == null || level.branchId == null) return null;
    return branchRegionOf[level.branchId!];
  }

  int? branchOfProgram(EducationProgramModel program) {
    final level = levels.firstWhereOrNullLocal((l) => l.id == program.educationLevelId);
    return level?.branchId;
  }

  // ---------------- Ngazi ya Elimu: CRUD ----------------

  Future<bool> saveLevel({int? id, required String name, required int? branchId}) async {
    isSaving.value = true;
    try {
      final body = {'name': name, 'branch_id': branchId};
      if (id == null) {
        await _api.post('/api/education-levels/', body: body);
      } else {
        await _api.put('/api/education-levels/$id', body: body);
      }
      await loadAll();
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteLevel(int id) async {
    try {
      await _api.delete('/api/education-levels/$id');
      Get.snackbar('Imefanikiwa', 'Ngazi ya Elimu imefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ---------------- Programu za Elimu: CRUD ----------------

  Future<bool> saveProgram({int? id, required String name, required int? educationLevelId}) async {
    isSaving.value = true;
    try {
      final body = {'name': name, 'education_level_id': educationLevelId};
      if (id == null) {
        await _api.post('/api/education-programs/', body: body);
      } else {
        await _api.put('/api/education-programs/$id', body: body);
      }
      await loadAll();
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteProgram(int id) async {
    try {
      await _api.delete('/api/education-programs/$id');
      Get.snackbar('Imefanikiwa', 'Programu imefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}

extension _FirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNullLocal(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
