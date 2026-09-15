import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../lookup/lookup_config.dart';
import '../widgets/document_type_split_panel.dart';
import '../../education/views/education_level_split_panel.dart';
import '../../education/views/education_program_split_panel.dart';
import '../widgets/leadership_split_panel.dart';
import '../widgets/split_lookup_panel.dart';

class _SettingsTab {
  final String label;
  final IconData icon;
  final Widget Function() builder;
  const _SettingsTab({required this.label, required this.icon, required this.builder});
}

/// Ukurasa mmoja unaokusanya moduli zote za "usanidi" (configuration/lookup)
/// kama tabs za mlalo - badala ya kila moja kuwa sidebar item tofauti.
/// Muundo umefuata mfumo wa awali (UVCCM Taifa) uliopendekezwa: tab
/// iliyochaguliwa ina background ya kijani hafifu, fomu ya "Ongeza" iko
/// papo hapo (siyo dialog) upande wa kushoto, orodha+search upande wa kulia.
class SettingsHubView extends StatefulWidget {
  const SettingsHubView({super.key});

  @override
  State<SettingsHubView> createState() => _SettingsHubViewState();
}

class _SettingsHubViewState extends State<SettingsHubView> {
  int _index = 0;

  late final List<_SettingsTab> _tabs = [
    // NB: 'Wadau' imehamishwa kuwa ukurasa wake mwenyewe chini ya kundi
    // la "Usajili" kwenye sidebar (angalia app_sidebar.dart) - siyo
    // tabo hapa tena, kuepuka kurudia (duplication).
    // ---- Mnyororo wa uongozi: Mkoa -> Tawi -> Ngazi ya Elimu -> Programu ----
    // (mpangilio huu WA MAKUSUDI - kila kimoja kinategemea kilichotangulia)
    _SettingsTab(label: 'Mikoa', icon: Icons.location_city_outlined, builder: () => const SplitLookupPanel(config: regionConfig, icon: Icons.location_city_outlined)),
    _SettingsTab(label: 'Matawi', icon: Icons.account_tree_outlined, builder: () => const SplitLookupPanel(config: branchConfig, icon: Icons.account_tree_outlined)),
    _SettingsTab(label: 'Ngazi ya Elimu', icon: Icons.school_outlined, builder: () => const EducationLevelSplitPanel()),
    _SettingsTab(label: 'Programu za Elimu', icon: Icons.menu_book_outlined, builder: () => const EducationProgramSplitPanel()),
    _SettingsTab(label: 'Vyeo', icon: Icons.badge_outlined, builder: () => const SplitLookupPanel(config: titleEntityConfig, icon: Icons.badge_outlined)),
    _SettingsTab(label: 'Nafasi za Uongozi', icon: Icons.workspace_premium_outlined, builder: () => const LeadershipSplitPanel()),
    _SettingsTab(label: 'Taasisi', icon: Icons.business_outlined, builder: () => const SplitLookupPanel(config: instituteConfig, icon: Icons.business_outlined)),
    _SettingsTab(label: 'Fani', icon: Icons.work_outline, builder: () => const SplitLookupPanel(config: occupationConfig, icon: Icons.work_outline)),
    _SettingsTab(label: 'Aina ya Kazi', icon: Icons.badge_outlined, builder: () => const SplitLookupPanel(config: occupationTypeConfig, icon: Icons.badge_outlined)),
    _SettingsTab(label: 'Viambatisho', icon: Icons.folder_special_outlined, builder: () => const DocumentTypeSplitPanel()),
  ];

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Usanidi wa Mfumo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usanidi wa Mfumo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Simamia data ya msingi ya mfumo - Vyeo, Nafasi za Uongozi, Taasisi, Elimu, Maeneo, Shughuli na Viambatisho.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final tab = _tabs[i];
                final active = i == _index;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _index = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? AppColors.successBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: active ? AppColors.primaryGreen.withOpacity(0.3) : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(tab.icon, size: 18, color: active ? AppColors.primaryGreen : AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: active ? AppColors.primaryGreen : AppColors.textSecondary,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: IndexedStack(
                index: _index,
                children: [for (final tab in _tabs) tab.builder()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
