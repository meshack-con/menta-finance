import 'package:get_storage/get_storage.dart';

/// Wrapper juu ya GetStorage - sehemu pekee ya app inayogusa storage moja
/// kwa moja. Moduli nyingine zote zinapitia hapa (usitumie GetStorage()
/// moja kwa moja kwingine popote).
class StorageService {
  static const _boxName = 'umis_admin_box';
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';
  static const _keyThemeMode = 'theme_mode'; // 'light' | 'dark'

  final GetStorage _box = GetStorage(_boxName);

  /// Lazima iitwe mara moja kabla ya runApp() - ona main.dart
  static Future<void> init() async {
    await GetStorage.init(_boxName);
  }

  String? get token => _box.read<String>(_keyToken);

  Future<void> saveToken(String token) => _box.write(_keyToken, token);

  Map<String, dynamic>? get user => _box.read<Map<String, dynamic>>(_keyUser);

  Future<void> saveUser(Map<String, dynamic> user) => _box.write(_keyUser, user);

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  Future<void> clearSession() async {
    await _box.remove(_keyToken);
    await _box.remove(_keyUser);
  }

  String get themeMode => _box.read<String>(_keyThemeMode) ?? 'light';
  Future<void> saveThemeMode(String mode) => _box.write(_keyThemeMode, mode);

  /// Roles za mtumiaji aliyeingia (kutoka 'auth_user.roles' - mfano
  /// "ADMIN" au "MSAJILI") - kwa ajili ya kuonyesha/kuficha sehemu za UI
  /// kulingana na ruhusa zake (Backend bado ndiyo inayolinda kwa uhalisia
  /// - hii ni kwa UX tu, isionyeshe vitu asivyoweza kubofya).
  List<String> get userRoles {
    final rolesStr = user?['roles'] as String? ?? '';
    return rolesStr.split(',').map((r) => r.trim().toUpperCase()).where((r) => r.isNotEmpty).toList();
  }

  /// True kwa roles za kawaida zenye ruhusa za mfumo.
  bool get hasFullAccess =>
      userRoles.contains('ADMIN') ||
      userRoles.contains('MANAGER') ||
      userRoles.contains('STAFF MEMBER') ||
      userRoles.contains('USER');

  /// True kama mtumiaji ni MSAJILI TU (hana ADMIN/USER pia) - ruhusa yake
  /// ni kusajili Wanachama tu (angalia backend app/ruler/router.py kwa
  /// ruhusa halisi - hii ni UI-gating tu).
  bool get isMsajiliOnly => userRoles.contains('MSAJILI') && !hasFullAccess;

  /// Role halisi ya mtumiaji kwenye mfumo wa Menta Studio (ADMIN, MANAGER
  /// au STAFF) - tofauti na 'userRoles'/'isMsajiliOnly' (mabaki ya mfumo
  /// wa awali wa UVCCM). Backend ndiyo inayolinda kwa uhalisia - haya ni
  /// kwa ajili ya kuonyesha/kuficha UI tu.
  String get menuRole => user?['roles'] as String? ?? 'STAFF';
  bool get isAdmin => menuRole == 'ADMIN';
  bool get isManager => menuRole == 'MANAGER';
  bool get isStaffOnly => menuRole == 'STAFF';
}
