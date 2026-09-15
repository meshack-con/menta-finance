import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../controllers/forum_moderation_controller.dart';

class ForumModerationView extends GetView<ForumModerationController> {
  const ForumModerationView({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return AppShell(
      title: 'Forum Moderation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Forum Moderation',
            subtitle: 'Ripoti za content zisizofaa kwenye Forum - kagua na chukua hatua.',
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
                    ElevatedButton(onPressed: controller.loadReports, child: const Text('Jaribu tena')),
                  ]),
                );
              }
              if (controller.reports.isEmpty) {
                return const Center(child: Text('Hakuna ripoti kwa sasa. 🎉', style: TextStyle(color: AppColors.textSecondary)));
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: const [
                    DataColumn(label: Text('Aina')),
                    DataColumn(label: Text('ID ya Kitu')),
                    DataColumn(label: Text('Sababu')),
                    DataColumn(label: Text('Aliyeripoti (Ruler ID)')),
                    DataColumn(label: Text('Tarehe')),
                    DataColumn(label: Text('Vitendo')),
                  ],
                  rows: controller.reports.map((r) {
                    return DataRow(cells: [
                      DataCell(Text(r.entityType)),
                      DataCell(Text('#${r.entityId}')),
                      DataCell(SizedBox(width: 220, child: Text(r.reason ?? '-', overflow: TextOverflow.ellipsis))),
                      DataCell(Text('#${r.rulerId}')),
                      DataCell(Text(dateFmt.format(r.createdAt))),
                      DataCell(Row(children: [
                        if (r.entityType == 'TOPIC' || r.entityType == 'OPPORTUNITY')
                          TextButton(
                            onPressed: () => controller.blockContent(r),
                            child: const Text('Zuia (Block)'),
                          ),
                        TextButton(
                          onPressed: () => controller.dismissReport(r.id),
                          child: const Text('Puuza (Dismiss)'),
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
}
