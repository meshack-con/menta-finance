import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../controllers/leadership_verification_controller.dart';

class LeadershipVerificationView extends GetView<LeadershipVerificationController> {
  const LeadershipVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Uthibitisho wa Uongozi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Uthibitisho wa Uongozi',
            subtitle: 'Wanachama waliojidai kuwa viongozi wenyewe (mobile) - thibitisha au kataa.',
          ),
          const SizedBox(height: 18),
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
                    ElevatedButton(onPressed: controller.loadAll, child: const Text('Jaribu tena')),
                  ]),
                );
              }
              if (controller.pending.isEmpty) {
                return const Center(
                  child: Text('Hakuna maombi yanayosubiri uthibitisho. 🎉', style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: const [
                    DataColumn(label: Text('Mwanachama')),
                    DataColumn(label: Text('Nafasi ya Uongozi Anayodai')),
                    DataColumn(label: Text('Tarehe Kuanza')),
                    DataColumn(label: Text('Vitendo')),
                  ],
                  rows: controller.pending.map((p) {
                    return DataRow(cells: [
                      DataCell(Text(controller.rulerNames[p.rulerId] ?? '...', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(controller.leadershipNames[p.leadershipId] ?? '...')),
                      DataCell(Text(p.startDate ?? '-')),
                      DataCell(Row(children: [
                        ElevatedButton(
                          onPressed: () => controller.verify(p.id),
                          child: const Text('Thibitisha'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                          onPressed: () => _confirmReject(context, p.id),
                          child: const Text('Kataa'),
                        ),
                      ])),
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

  void _confirmReject(BuildContext context, int id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Kataa Ombi'),
        content: const Text('Una uhakika unataka kukataa (kufuta) ombi hili la uongozi?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.reject(id);
            },
            child: const Text('Kataa'),
          ),
        ],
      ),
    );
  }
}
