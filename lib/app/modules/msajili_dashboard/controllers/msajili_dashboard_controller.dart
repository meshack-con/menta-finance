import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../rulers/models/lookup_option.dart';
import '../../auth/models/user_model.dart';
import '../../users/users_service.dart';

class RegionCount {
  final int id;
  final String name;
  final int count;
  RegionCount(this.id, this.name, this.count);
  factory RegionCount.fromJson(Map<String, dynamic> j) => RegionCount(j['id'] as int, j['name'] as String, j['count'] as int);
}

class BranchCount {
  final String name;
  final int? regionId;
  final int count;
  BranchCount(this.name, this.regionId, this.count);
  factory BranchCount.fromJson(Map<String, dynamic> j) => BranchCount(j['name'] as String, j['region_id'] as int?, j['count'] as int);
}

class RegisteredMemberRow {
  final int id;
  final String fullName;
  final String? phoneNumber;
  final String? genderLabel;
  final String createdAt;
  RegisteredMemberRow({required this.id, required this.fullName, this.phoneNumber, this.genderLabel, required this.createdAt});

  factory RegisteredMemberRow.fromJson(Map<String, dynamic> j) {
    final name = [j['first_name'], j['middle_name'], j['last_name']]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(' ');
    return RegisteredMemberRow(
      id: j['id'] as int,
      fullName: name.isEmpty ? 'Mwanachama #${j['id']}' : name,
      phoneNumber: j['phone_number'],
      genderLabel: j['gender'] == 'Male' ? 'Mme' : (j['gender'] == 'Female' ? 'Mke' : null),
      createdAt: j['created_at']?.toString() ?? '',
    );
  }
}

/// Dashibodi ya "Msajili" (Web/Admin Panel) - inatumia ENDPOINT ZILE ZILE
/// zinazotumiwa na Mobile App ('/api/rulers/mine/...') - takwimu za
/// Wanachama aliowasajili YEYE MWENYEWE (Msajili aliye-login sasa), AU
/// (kwa ADMIN/USER TU) za Msajili/Staff MWINGINE aliyemchagua. Pia
/// inaweza kuchujwa kwa kipindi cha tarehe, Mkoa, na/au Tawi.
class MsajiliDashboardController extends GetxController {
  final ApiClient _api;
  MsajiliDashboardController(this._api);

  final isLoading = true.obs;
  final isLoadingFilters = true.obs;
  final errorMessage = RxnString();

  final total = 0.obs;
  final male = 0.obs;
  final female = 0.obs;
  final byRegion = <RegionCount>[].obs;
  final byBranch = <BranchCount>[].obs;
  final recentMembers = <RegisteredMemberRow>[].obs;

  /// True kama mtumiaji aliye-login sasa ana ruhusa kamili (ADMIN/USER) -
  /// ndipo dropdown ya "Chagua Msajili" inaonekana.
  bool get hasFullAccess => Get.find<StorageService>().hasFullAccess;

  // ---- Vichujio ----
  final msajiliUsers = <UserModel>[].obs; // orodha ya Watumiaji wenye role MSAJILI (kwa ADMIN kuchagua)
  final selectedUserId = RxnInt(); // null = mwenyewe (au Msajili aliye-login)
  final regions = <LookupOption>[].obs;
  final branches = <LookupOption>[].obs;
  final filterRegionId = RxnInt();
  final filterBranchId = RxnInt();
  final filterStartDate = Rxn<DateTime>();
  final filterEndDate = Rxn<DateTime>();

  List<LookupOption> branchesForRegion(int? regionId) {
    if (regionId == null) return branches;
    return branches.where((b) => b.parentId == regionId).toList();
  }

  /// Matawi (na idadi) ndani ya Mkoa MOJA aliouchagua (tap) kwenye
  /// drill-down ya takwimu - TOFAUTI na 'branchesForRegion' (ambayo ni
  /// kwa dropdown ya kichujio - orodha ya Matawi YOTE, siyo idadi).
  List<BranchCount> branchesInRegion(int regionId) => byBranch.where((b) => b.regionId == regionId).toList();

  @override
  void onInit() {
    super.onInit();
    _loadFilters();
    loadAll();
  }

  Future<void> _loadFilters() async {
    isLoadingFilters.value = true;
    try {
      if (hasFullAccess) {
        final users = await UsersService(_api).list();
        msajiliUsers.assignAll(users.where((u) => u.roleList.map((r) => r.toUpperCase()).contains('MSAJILI')));
      }
      final regionsData = await _api.get('/api/regions/', query: {'limit': 500});
      regions.assignAll((regionsData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)));
      final branchesData = await _api.get('/api/branches/', query: {'limit': 500});
      branches.assignAll((branchesData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>, parentKey: 'region_id')));
    } catch (_) {
      // si hatari kubwa - vichujio vitakuwa tupu, dashibodi bado inaonyesha data ya msingi
    } finally {
      isLoadingFilters.value = false;
    }
  }

  void resetFilters() {
    filterRegionId.value = null;
    filterBranchId.value = null;
    filterStartDate.value = null;
    filterEndDate.value = null;
    loadAll();
  }

  String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final query = <String, dynamic>{
        if (selectedUserId.value != null) 'user_id': selectedUserId.value,
        if (filterStartDate.value != null) 'start_date': _isoDate(filterStartDate.value!),
        if (filterEndDate.value != null) 'end_date': _isoDate(filterEndDate.value!),
        if (filterRegionId.value != null) 'region_id': filterRegionId.value,
        if (filterBranchId.value != null) 'branch_id': filterBranchId.value,
      };

      final stats = await _api.get('/api/rulers/mine/registered-stats', query: query) as Map<String, dynamic>;
      total.value = stats['total'] as int;
      male.value = stats['male'] as int;
      female.value = stats['female'] as int;
      byRegion.assignAll((stats['by_region'] as List).map((e) => RegionCount.fromJson(e as Map<String, dynamic>)));
      byBranch.assignAll((stats['by_branch'] as List).map((e) => BranchCount.fromJson(e as Map<String, dynamic>)));

      final list = await _api.get('/api/rulers/mine/registered', query: {...query, 'limit': 30}) as List;
      recentMembers.assignAll(list.map((e) => RegisteredMemberRow.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia taarifa.';
    } finally {
      isLoading.value = false;
    }
  }
}
