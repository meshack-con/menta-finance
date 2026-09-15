import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../controllers/login_history_controller.dart';

class LoginHistoryView extends GetView<LoginHistoryController> {
  const LoginHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return AppShell(
      title: 'Historia ya Login',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Historia ya Login',
            subtitle: 'Taarifa za kuingia kwenye mfumo (read-only).',
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 340,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Username, simu au kifaa...',
                isDense: true,
              ),
              onChanged: (v) => controller.searchText.value = v,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value != null) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: controller.loadHistory, child: const Text('Jaribu tena')),
                  ]),
                );
              }
              final list = controller.filteredHistory;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    controller.searchText.value.isEmpty ? 'Hakuna historia ya login bado.' : 'Hakuna matokeo.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: const [
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Simu')),
                    DataColumn(label: Text('Roles wakati huo')),
                    DataColumn(label: Text('Kifaa Kilichotumika')),
                    DataColumn(label: Text('Tarehe')),
                  ],
                  rows: list.map((h) {
                    return DataRow(cells: [
                      DataCell(Text(h.username ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(h.phoneNumber ?? '-')),
                      DataCell(Text(h.roles ?? '-')),
                      DataCell(Text(h.deviceUsed ?? '-')),
                      DataCell(Text(dateFmt.format(h.createdAt))),
                    ]);
                  }).toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
