import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/empty_state_widget.dart';

/// Ukurasa wa Admin kuona notifications ZOTE zilizoko kwenye jedwali
/// (zilizotumwa kwa Wanachama - Fursa zinazolingana, ujumbe, n.k.), na
/// kuweza kufuta moja moja au kwa mkupuo (bulk).
class AdminNotificationsView extends StatefulWidget {
  const AdminNotificationsView({super.key});

  @override
  State<AdminNotificationsView> createState() => _AdminNotificationsViewState();
}

class _AdminNotificationsViewState extends State<AdminNotificationsView> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _typeFilter;
  final Set<int> _selectedIds = {};

  final _types = const ['OPPORTUNITY_MATCH', 'ADMIN_MESSAGE', 'COMMENT', 'REPLY', 'LIKE', 'RATE', 'INTERESTED'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await Get.find<ApiClient>().get('/api/admin/notifications/', query: {
        'limit': 200,
        if (_typeFilter != null) 'type': _typeFilter,
      });
      _notifications = (data as List).cast<Map<String, dynamic>>();
      _selectedIds.clear();
    } catch (_) {
      Get.snackbar('Hitilafu', 'Imeshindikana kupakia notifications.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteOne(int id) async {
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Futa Notification'),
      content: const Text('Una uhakika unataka kufuta notification hii?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Ghairi')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Get.back(result: true), child: const Text('Futa')),
      ],
    ));
    if (confirmed != true) return;
    try {
      await Get.find<ApiClient>().delete('/api/admin/notifications/$id');
      _load();
    } catch (_) {
      Get.snackbar('Hitilafu', 'Imeshindikana kufuta.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await Get.dialog<bool>(AlertDialog(
      title: const Text('Futa Zilizochaguliwa'),
      content: Text('Una uhakika unataka kufuta notifications ${_selectedIds.length}?'),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Ghairi')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Get.back(result: true), child: const Text('Futa Zote')),
      ],
    ));
    if (confirmed != true) return;
    try {
      await Get.find<ApiClient>().post('/api/admin/notifications/bulk-delete', body: _selectedIds.toList());
      _load();
    } catch (_) {
      Get.snackbar('Hitilafu', 'Imeshindikana kufuta.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'OPPORTUNITY_MATCH':
        return AppColors.primaryGreen;
      case 'ADMIN_MESSAGE':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Notifications',
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Chuja kwa aina:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(width: 10),
            DropdownButton<String?>(
              value: _typeFilter,
              hint: const Text('Zote'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Zote')),
                ..._types.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t))),
              ],
              onChanged: (v) {
                setState(() => _typeFilter = v);
                _load();
              },
            ),
            const Spacer(),
            if (_selectedIds.isNotEmpty)
              TextButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                label: Text('Futa Zilizochaguliwa (${_selectedIds.length})', style: const TextStyle(color: AppColors.danger)),
              ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Sasisha'),
          ]),
          const SizedBox(height: 14),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_notifications.isEmpty)
            const EmptyStateWidget(icon: Icons.notifications_none_outlined, title: 'Hakuna Notifications', subtitle: 'Notifications zilizotumwa kwa Wanachama zitaonekana hapa.')
          else
            DataTableCard(
              columns: [
                DataColumn(
                  label: Checkbox(
                    value: _selectedIds.length == _notifications.length && _notifications.isNotEmpty,
                    tristate: true,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.addAll(_notifications.map((n) => n['id'] as int));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
                  ),
                ),
                const DataColumn(label: Text('Aina')),
                const DataColumn(label: Text('Mpokeaji')),
                const DataColumn(label: Text('Ujumbe')),
                const DataColumn(label: Text('Hali')),
                const DataColumn(label: Text('Tarehe')),
                const DataColumn(label: Text('Vitendo')),
              ],
              rows: _notifications.map((n) {
                final id = n['id'] as int;
                final createdAt = DateTime.tryParse(n['created_at'] as String);
                return DataRow(cells: [
                  DataCell(Checkbox(
                    value: _selectedIds.contains(id),
                    onChanged: (v) => setState(() => v == true ? _selectedIds.add(id) : _selectedIds.remove(id)),
                  )),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _typeColor(n['type'] as String).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(n['type'] as String, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _typeColor(n['type'] as String))),
                  )),
                  DataCell(Text(n['recipient_name'] as String? ?? '-')),
                  DataCell(SizedBox(width: 260, child: Text(n['message'] as String? ?? '', overflow: TextOverflow.ellipsis, maxLines: 1))),
                  DataCell(Text(
                    n['is_read'] == true ? 'Imesomwa' : 'Haijasomwa',
                    style: TextStyle(color: n['is_read'] == true ? AppColors.success : AppColors.accentYellow, fontWeight: FontWeight.w600, fontSize: 12),
                  )),
                  DataCell(Text(createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt) : '-')),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    onPressed: () => _deleteOne(id),
                  )),
                ]);
              }).toList(),
            ),
        ],
      ),
      ),
    );
  }
}
