import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'empty_state_widget.dart';

/// "Kadi" nzuri inayozungushia DataTable yoyote - kivuli laini, pembe za
/// mviringo, kichwa cha safu chenye rangi tofauti na mwili, na nafasi
/// (padding) ya kutosha. Inatumika mahali pote penye jedwali kwenye app
/// (Maeneo, Elimu, Taasisi, Vyeo, Shughuli, Watumiaji, Wanachama, n.k.)
/// ili muonekano ubaki mmoja na wa kuvutia zaidi kuliko jedwali "tupu".
///
/// NB: 'rows' ikiwa tupu, inaonyesha 'EmptyStateWidget' nzuri (icon +
/// kichwa + maelezo) badala ya jedwali tupu lisiloeleweka - hii inatumika
/// KILA MAHALI kwa mkupuo mmoja kwa sababu DataTableCard ndiyo msingi wa
/// majedwali yote ya Admin.
class DataTableCard extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double columnSpacing;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptySubtitle;

  const DataTableCard({
    super.key,
    required this.columns,
    required this.rows,
    this.columnSpacing = 28,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Hakuna Data',
    this.emptySubtitle = 'Hakuna kitu cha kuonyesha hapa kwa sasa.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: rows.isEmpty
          ? EmptyStateWidget(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle)
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    // NB: minWidth ni namba halisi (kutoka LayoutBuilder), SIYO
                    // double.infinity - kutumia infinity hapa kunasababisha
                    // "layout error" (infinite width) inayovunja kuonyesha
                    // jedwali LOTE. Hii ndiyo iliyokuwa sababu ya "hamna
                    // mahali data zinaonesha" baada ya marekebisho yaliyopita.
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: columnSpacing,
                      headingRowColor: WidgetStateProperty.all(AppColors.tableHeaderBg),
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13),
                      dataTextStyle: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 60,
                      horizontalMargin: 20,
                      columns: columns,
                      rows: rows,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
