import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/data/client_project_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../widgets/client_invoice_dialog.dart';

String _fmtMoney(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

/// Ukurasa wa "Taarifa Kamili za Client".
///
/// Hii NI ukurasa mpya, tofauti na Clients (AppRoutes.rulerList).
/// Unafikiwa TU kupitia kitufe cha "Tazama" kwenye orodha ya Clients
/// (ruler_list_view.dart) - HAUKO kwenye Sidebar kwa makusudi (angalia
/// app_sidebar.dart, hakuna reference ya AppRoutes.clientDetail humo).
///
/// Client id inapokelewa kupitia Get.arguments (String).
class ClientDetailView extends StatelessWidget {
  const ClientDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ClientProjectStore>();
    final clientId = (Get.arguments as String?) ?? '';
    final dateFmt = DateFormat('dd/MM/yyyy');

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final client = store.clients.firstWhereOrNull((c) => c.id == clientId);

        if (client == null) {
          return AppShell(
            title: 'Taarifa za Client',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Rudi Clients'),
                ),
                const SizedBox(height: 40),
                const Center(child: Text('Client huyu hakupatikana.', style: TextStyle(color: AppColors.textSecondary))),
              ],
            ),
          );
        }

        final projects = store.projectsFor(client.id);
        final totalPaid = projects.fold<double>(0, (sum, p) => sum + p.paid);
        final totalOutstanding = projects.fold<double>(0, (sum, p) => sum + p.outstanding);
        final totalBilled = projects.fold<double>(0, (sum, p) => sum + p.amount);
        final companyTotalIncome = store.projects.fold<double>(0, (sum, p) => sum + p.paid);
        final incomeShare = companyTotalIncome == 0 ? 0.0 : (totalPaid / companyTotalIncome * 100);

        return AppShell(
          title: 'Taarifa za Client',
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PageHeader(
                        title: client.name,
                        subtitle: 'Taarifa kamili za client huyu na projects zote alizoleta kwenye kampuni.',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Rudi Clients'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- Kadi ya taarifa za msingi za client ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.avatarBg,
                          child: Text(
                            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primaryGreen),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(client.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 18,
                                runSpacing: 4,
                                children: [
                                  _InfoChip(icon: Icons.phone_outlined, label: client.phone.isEmpty ? '-' : client.phone),
                                  _InfoChip(icon: Icons.email_outlined, label: client.email.isEmpty ? '-' : client.email),
                                  _InfoChip(icon: Icons.work_outline, label: '${projects.length} Projects'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Muhtasari: Total Paid, Outstanding, % ya Total Income ----
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 720;
                    final cards = [
                      _SummaryCard(
                        icon: Icons.check_circle_outline,
                        color: AppColors.primaryGreen,
                        label: 'Jumla Aliyolipa (Total Paid)',
                        value: _fmtMoney(totalPaid),
                      ),
                      _SummaryCard(
                        icon: Icons.pending_outlined,
                        color: AppColors.warning,
                        label: 'Jumla Anayodaiwa (Outstanding)',
                        value: _fmtMoney(totalOutstanding),
                      ),
                      _SummaryCard(
                        icon: Icons.pie_chart_outline_rounded,
                        color: AppColors.primaryTeal,
                        label: 'Mchango kwa Total Income ya Kampuni',
                        value: '${incomeShare.toStringAsFixed(1)}%',
                      ),
                      _SummaryCard(
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.info,
                        label: 'Jumla ya Bei ya Projects (Billed)',
                        value: _fmtMoney(totalBilled),
                      ),
                    ];
                    if (isNarrow) {
                      return Column(
                        children: [
                          for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i != cards.length - 1) const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ---- Orodha ya Projects zote za client huyu ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Projects Zote Alizoleta Client Huyu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        DataTableCard(
                          emptyIcon: Icons.work_outline,
                          emptyTitle: 'Hakuna Project',
                          emptySubtitle: 'Client huyu bado hana project yoyote.',
                          columns: const [
                            DataColumn(label: Text('Project')),
                            DataColumn(label: Text('Aina')),
                            DataColumn(label: Text('Tarehe Iliyoingizwa')),
                            DataColumn(label: Text('Deadline')),
                            DataColumn(label: Text('Bei ya Project')),
                            DataColumn(label: Text('Paid')),
                            DataColumn(label: Text('Outstanding')),
                            DataColumn(label: Text('Invoice')),
                          ],
                          rows: projects.map((project) {
                            return DataRow(cells: [
                              DataCell(Text(project.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                              DataCell(Text(project.type)),
                              DataCell(Text(dateFmt.format(project.registeredAt))),
                              DataCell(Text(dateFmt.format(project.deadline))),
                              DataCell(Text(_fmtMoney(project.amount))),
                              DataCell(Text(_fmtMoney(project.paid))),
                              DataCell(
                                Text(
                                  _fmtMoney(project.outstanding),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: project.outstanding > 0 ? AppColors.danger : AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                              DataCell(
                                TextButton.icon(
                                  onPressed: () => showDialog<void>(
                                    context: context,
                                    builder: (_) => ClientInvoiceDialog(client: client, project: project),
                                  ),
                                  icon: const Icon(Icons.print_outlined, size: 16),
                                  label: const Text('Chapisha'),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SummaryCard({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
