import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../rulers/models/lookup_option.dart';

enum _TargetMode { all, single, group }

/// Ukurasa wa Admin kutuma ujumbe wa moja kwa moja kwa Mwanachama mmoja,
/// kwa KIKUNDI maalum (Jinsia/Mkoa/Tawi/Fani/Aina ya Kazi/Viongozi Active),
/// AU kwa Wanachama WOTE kwa mkupuo mmoja (broadcast) - inatumia mfumo
/// ule ule wa notification uliopo tayari (WebSocket + FCM push halisi).
/// Pia inaonyesha 'History' ya ujumbe zote alizowahi kutuma Admin.
///
/// NB: Hii inatuma TU kwa Wanachama (wenye akaunti ya Mobile App). Wadau
/// (Stakeholders - Binafsi/Taasisi) HAWANA akaunti ya Mobile App, kwa
/// hiyo hawawezi kupokea ujumbe kwa njia hii - kuwatumia kunahitaji njia
/// nyingine (SMS/Barua Pepe) ambayo haijajengwa bado kwenye mfumo huu.
class AdminMessagesView extends StatefulWidget {
  const AdminMessagesView({super.key});

  @override
  State<AdminMessagesView> createState() => _AdminMessagesViewState();
}

class _AdminMessagesViewState extends State<AdminMessagesView> {
  final messageCtrl = TextEditingController();
  _TargetMode _targetMode = _TargetMode.all;
  int? _selectedRulerId;
  bool _isLoadingRulers = true;
  bool _isSending = false;
  List<LookupOption> _rulers = [];

  // ---- Vichujio vya "Kwa Kikundi" ----
  bool _isLoadingGroupLookups = true;
  List<LookupOption> _regions = [];
  List<LookupOption> _branches = [];
  List<LookupOption> _occupations = [];
  List<LookupOption> _occupationTypes = [];
  String? _groupGender;
  int? _groupRegionId;
  int? _groupBranchId;
  int? _groupOccupationId;
  int? _groupOccupationTypeId;
  bool _groupLeadersOnly = false;

  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadRulers();
    _loadGroupLookups();
    _loadHistory();
  }

  Future<void> _loadRulers() async {
    try {
      final data = await Get.find<ApiClient>().get('/api/rulers/', query: {'limit': 1000});
      final items = (data is Map && data['items'] != null) ? data['items'] as List : data as List;
      _rulers = items.map((e) {
        final j = e as Map<String, dynamic>;
        final name = [j['first_name'], j['last_name']].where((x) => x != null && x.toString().isNotEmpty).join(' ');
        return LookupOption(j['id'] as int, name.isEmpty ? 'Mwanachama #${j['id']}' : name);
      }).toList();
    } catch (_) {
      // si hatari kubwa - "Kwa Mtu Mmoja" itakuwa tupu, "Kwa Wote" bado inafanya kazi
    } finally {
      if (mounted) setState(() => _isLoadingRulers = false);
    }
  }

  Future<void> _loadGroupLookups() async {
    try {
      final api = Get.find<ApiClient>();
      final regionsData = await api.get('/api/regions/', query: {'limit': 500});
      _regions = (regionsData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
      final branchesData = await api.get('/api/branches/', query: {'limit': 500});
      _branches = (branchesData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
      final occupationsData = await api.get('/api/occupations/');
      _occupations = (occupationsData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
      final occupationTypesData = await api.get('/api/occupation-types/');
      _occupationTypes = (occupationTypesData as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // si hatari kubwa - dropdown za "Kwa Kikundi" zitakuwa tupu, mtumiaji anaweza jaribu tena
    } finally {
      if (mounted) setState(() => _isLoadingGroupLookups = false);
    }
  }

  Future<void> _loadHistory() async {
    if (mounted) setState(() => _isLoadingHistory = true);
    try {
      final data = await Get.find<ApiClient>().get('/api/admin/messages/history');
      _history = (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      // si hatari kubwa - "History" itabaki tupu, mtumiaji anaweza "Jaribu Tena"
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  bool get _hasGroupFilter =>
      _groupGender != null || _groupRegionId != null || _groupBranchId != null || _groupOccupationId != null || _groupOccupationTypeId != null || _groupLeadersOnly;

  Future<void> _send() async {
    if (messageCtrl.text.trim().isEmpty) {
      Get.snackbar('Kosa', 'Andika ujumbe kwanza.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_targetMode == _TargetMode.single && _selectedRulerId == null) {
      Get.snackbar('Kosa', 'Chagua Mwanachama wa kutuma ujumbe.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_targetMode == _TargetMode.group && !_hasGroupFilter) {
      Get.snackbar('Kosa', 'Chagua angalau kigezo kimoja cha kikundi (mfano Jinsia, Mkoa, n.k.).', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    String confirmTitle;
    String confirmBody;
    Color confirmColor = AppColors.primaryGreen;
    switch (_targetMode) {
      case _TargetMode.single:
        confirmTitle = 'Thibitisha';
        confirmBody = 'Tuma ujumbe huu kwa mwanachama huyu?';
        break;
      case _TargetMode.group:
        confirmTitle = 'Thibitisha Kikundi';
        confirmBody = 'Tuma ujumbe huu kwa kikundi kilichochaguliwa? Kitendo hiki hakiwezi kufutwa.';
        confirmColor = AppColors.danger;
        break;
      case _TargetMode.all:
        confirmTitle = 'Thibitisha Broadcast';
        confirmBody = 'Tuma ujumbe huu kwa WANACHAMA WOTE? Kitendo hiki hakiwezi kufutwa.';
        confirmColor = AppColors.danger;
        break;
    }
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: Text(confirmTitle),
      content: Text(confirmBody),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Ghairi')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Get.back(result: true),
          child: Text(_targetMode == _TargetMode.single ? 'Tuma' : 'Tuma'),
        ),
      ],
    ));
    if (confirmed != true) return;

    setState(() => _isSending = true);
    try {
      final result = await Get.find<ApiClient>().post('/api/admin/messages/send', body: {
        'message': messageCtrl.text.trim(),
        if (_targetMode == _TargetMode.single) 'ruler_id': _selectedRulerId,
        if (_targetMode == _TargetMode.group) ...{
          'gender': _groupGender,
          'region_id': _groupRegionId,
          'branch_id': _groupBranchId,
          'occupation_id': _groupOccupationId,
          'occupation_type_id': _groupOccupationTypeId,
          'leaders_only': _groupLeadersOnly,
        },
      });
      final sentTo = (result as Map)['sent_to'];
      Get.snackbar('Imefanikiwa', 'Ujumbe umetumwa kwa wanachama $sentTo.', snackPosition: SnackPosition.BOTTOM);
      messageCtrl.clear();
      setState(() {
        _selectedRulerId = null;
        _groupGender = null;
        _groupRegionId = null;
        _groupBranchId = null;
        _groupOccupationId = null;
        _groupOccupationTypeId = null;
        _groupLeadersOnly = false;
      });
      _loadHistory(); // sasisha 'History' papo hapo baada ya kutuma
    } catch (e) {
      Get.snackbar('Hitilafu', 'Imeshindikana kutuma ujumbe.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteHistoryItem(int logId) async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Futa Kutoka Historia'),
      content: const Text('Hii itaondoa rekodi hii kwenye Historia (haiathiri arifa zilizokwishafika kwa Wanachama). Una uhakika?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Ghairi')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Get.back(result: true),
          child: const Text('Futa'),
        ),
      ],
    ));
    if (confirmed != true) return;
    try {
      await Get.find<ApiClient>().delete('/api/admin/messages/history/$logId');
      _loadHistory();
    } catch (_) {
      Get.snackbar('Hitilafu', 'Imeshindikana kufuta.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Ujumbe kwa Wanachama',
      // MUHIMU: muundo wa "safu mbili" (side-by-side) - Tuma Ujumbe
      // KUSHOTO, Historia ya Ujumbe KULIA - kutumia vizuri nafasi pana
      // ya skrini ya Web (badala ya kila kitu kupangwa juu-chini na
      // nafasi tupu pande zote).
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          if (!isWide) {
            // Skrini nyembamba (mfano tablet/simu) - bado juu-chini
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSendCard(context),
                  const SizedBox(height: 24),
                  _buildHistoryCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: _buildSendCard(context))),
              const SizedBox(width: 24),
              Expanded(child: SingleChildScrollView(child: _buildHistoryCard(context))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSendCard(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.06), border: const Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(children: [
              const Icon(Icons.send_outlined, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              const Text('Tuma Ujumbe', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ujumbe utafika kama arifa halisi (push notification) hata kama Mwanachama ana app imefungwa.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
                  child: Column(children: [
                    RadioListTile<_TargetMode>(
                      value: _TargetMode.all,
                      groupValue: _targetMode,
                      onChanged: (v) => setState(() => _targetMode = v!),
                      title: const Text('Kwa Wote (Broadcast)', style: TextStyle(fontSize: 13)),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    RadioListTile<_TargetMode>(
                      value: _TargetMode.group,
                      groupValue: _targetMode,
                      onChanged: (v) => setState(() => _targetMode = v!),
                      title: const Text('Kwa Kikundi (Jinsia, Mkoa, Tawi, Fani, n.k.)', style: TextStyle(fontSize: 13)),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    RadioListTile<_TargetMode>(
                      value: _TargetMode.single,
                      groupValue: _targetMode,
                      onChanged: (v) => setState(() => _targetMode = v!),
                      title: const Text('Kwa Mtu Mmoja', style: TextStyle(fontSize: 13)),
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ]),
                ),
                if (_targetMode == _TargetMode.single) ...[
                  const SizedBox(height: 14),
                  _isLoadingRulers
                      ? const Center(child: CircularProgressIndicator())
                      : SearchableDropdown(
                          label: 'Chagua Mwanachama',
                          options: _rulers,
                          value: _selectedRulerId,
                          onChanged: (v) => setState(() => _selectedRulerId = v),
                        ),
                ],
                if (_targetMode == _TargetMode.group) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      'Chagua kigezo kimoja au zaidi - ujumbe utatumwa TU kwa Wanachama wanaokidhi VYOTE '
                      'ulivyochagua (mfano ukichagua Jinsia="Female" NA Mkoa="Dodoma", utatuma kwa wanawake wa '
                      'Dodoma tu). Wadau (Binafsi/Taasisi) hawapatikani hapa - hawana akaunti ya Mobile App.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingGroupLookups)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            value: _groupGender,
                            decoration: const InputDecoration(labelText: 'Jinsia', isDense: true),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Zote')),
                              DropdownMenuItem(value: 'Male', child: Text('Wanaume')),
                              DropdownMenuItem(value: 'Female', child: Text('Wanawake')),
                            ],
                            onChanged: (v) => setState(() => _groupGender = v),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: SearchableDropdown(
                            label: 'Mkoa',
                            options: _regions,
                            value: _groupRegionId,
                            onChanged: (v) => setState(() => _groupRegionId = v),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: SearchableDropdown(
                            label: 'Tawi',
                            options: _branches,
                            value: _groupBranchId,
                            onChanged: (v) => setState(() => _groupBranchId = v),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: SearchableDropdown(
                            label: 'Fani',
                            options: _occupations,
                            value: _groupOccupationId,
                            onChanged: (v) => setState(() => _groupOccupationId = v),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: SearchableDropdown(
                            label: 'Aina ya Kazi',
                            options: _occupationTypes,
                            value: _groupOccupationTypeId,
                            onChanged: (v) => setState(() => _groupOccupationTypeId = v),
                          ),
                        ),
                      ],
                    ),
                  CheckboxListTile(
                    value: _groupLeadersOnly,
                    onChanged: (v) => setState(() => _groupLeadersOnly = v ?? false),
                    title: const Text('Viongozi wenye nafasi inayoendelea (Active) tu', style: TextStyle(fontSize: 13)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
                const SizedBox(height: 18),
                TextField(
                  controller: messageCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Ujumbe',
                    hintText: 'Andika ujumbe wako hapa...',
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_outlined, size: 18),
                    label: Text(switch (_targetMode) {
                      _TargetMode.all => 'Tuma kwa Wote',
                      _TargetMode.group => 'Tuma kwa Kikundi',
                      _TargetMode.single => 'Tuma Ujumbe',
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.inputFill, border: const Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.history, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Text('Historia ya Ujumbe', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                ]),
                IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadHistory, tooltip: 'Sasisha'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: _isLoadingHistory
                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                : _history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: EmptyStateWidget(icon: Icons.mail_outline, title: 'Hakuna Historia', subtitle: 'Ujumbe utakaotuma utaonekana hapa.'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        separatorBuilder: (_, __) => const Divider(height: 24),
                        itemBuilder: (context, i) {
                          final h = _history[i];
                          final targetType = h['target_type'] as String? ?? 'ALL';
                          final isAll = targetType == 'ALL';
                          final isGroup = targetType == 'GROUP';
                          final badgeColor = isAll ? AppColors.primaryGreen : (isGroup ? AppColors.warning : AppColors.info);
                          final badgeText = isAll ? 'KWA WOTE' : (h['target_ruler_name'] as String? ?? (isGroup ? 'Kikundi' : 'Mtu Mmoja'));
                          final createdAt = DateTime.tryParse(h['created_at'] as String);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: badgeColor),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt) : '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                    onPressed: () => _deleteHistoryItem(h['id'] as int),
                                    tooltip: 'Futa',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Text(h['message'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Imetumwa kwa wanachama ${h['sent_to_count']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
